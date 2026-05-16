import 'package:flutter/material.dart';

import '../../../domain/models/confidence.dart';
import '../../../domain/models/plan_item.dart';

/// Presentational shape for a parsed card.
///
/// Lives in the feature layer because it carries UI-only concerns —
/// pre-rendered label strings, the visual confidence state, the icon
/// hint. The data layer never sees this; the providers in Phase 04
/// build it from a [PlanItem] + the user's intention.
class ParsedCardViewModel {
  const ParsedCardViewModel({
    required this.planItemId,
    required this.rawText,
    required this.title,
    required this.titleConfidence,
    required this.attributes,
  });

  /// The plan item this card represents. Used to fire edit and
  /// dismiss callbacks back to the providers.
  final String planItemId;

  /// The user's original intention text — quoted in the detail view's
  /// "You typed" block. The peek does not render this.
  final String rawText;

  final String title;
  final Confidence titleConfidence;

  /// Five rows in canonical order: type, when, recurrence, parent, temperature.
  ///
  /// Some attributes may be omitted when the parser has no signal
  /// (e.g. recurrence on a one-off task). The list preserves order
  /// for deterministic rendering.
  final List<ParsedAttribute> attributes;

  /// Returns the attribute matching [key], or null if absent.
  ParsedAttribute? attributeFor(String key) {
    for (final ParsedAttribute a in attributes) {
      if (a.key == key) return a;
    }
    return null;
  }
}

/// One row in a parsed card — one of: type, when, recurrence, parent, temperature.
class ParsedAttribute {
  const ParsedAttribute({
    required this.key,
    required this.label,
    required this.displayValue,
    required this.confidence,
    required this.icon,
  });

  /// Stable identifier: 'type', 'time', 'recurrence', 'parent', 'temperature'.
  /// Matches the [PlanItem.confidences] map keys exactly.
  final String key;

  /// Localized row label — e.g. "Type", "When", "Recurrence".
  final String label;

  /// Localized human-readable value — "Errand", "This week", "Weekly".
  final String displayValue;

  final Confidence confidence;

  /// Material icon shown left of the row label in the detail card,
  /// and inside the chip in the peek card.
  final IconData icon;

  /// Convenience getter — we store the code point rather than IconData
  /// because IconData isn't const-constructible across the codegen
  /// boundary in some setups. The chip reads this back through [icon].
//   IconData get icon =>
//       IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

// IconData has to be imported. Drop this at the top:
//   import 'package:flutter/material.dart' show IconData;
//
// The reason for the dance: ParsedAttribute may eventually be
// serialized to/from a remote API; keeping the code-point as int
// keeps the model JSON-safe.