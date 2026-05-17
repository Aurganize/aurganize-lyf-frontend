import 'package:flutter/material.dart';

import '../../../domain/enums/plan_item_type.dart';
import '../../../domain/enums/temperature.dart';
import '../../../domain/models/confidence.dart';
import '../../../domain/models/item_time.dart';
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


extension ParsedCardViewModelFactory on ParsedCardViewModel {
  /// Build a presentational view model from a domain [PlanItem] plus
  /// its source [rawText].
  ///
  /// The factory encodes ALL the type-to-label, type-to-icon,
  /// time-to-label, and temperature-to-label mappings. Both the peek
  /// card and the detail view call this; they never invent their own.
  static ParsedCardViewModel fromDomain({
    required PlanItem item,
    required String rawText,
  }) {
    return ParsedCardViewModel(
      planItemId: item.id,
      rawText: rawText,
      title: item.title,
      titleConfidence: item.confidenceFor('title'),
      attributes: <ParsedAttribute>[
        ParsedAttribute(
          key: 'type',
          label: 'Type',
          displayValue: _typeLabel(item.type),
          confidence: item.confidenceFor('type'),
          icon: _typeIcon(item.type),
        ),
        ParsedAttribute(
          key: 'time',
          label: 'When',
          displayValue: _timeLabel(item.time),
          confidence: item.confidenceFor('time'),
          icon: Icons.calendar_today_outlined,
        ),
        ParsedAttribute(
          key: 'recurrence',
          label: 'Recurrence',
          displayValue: _recurrenceLabel(item.time),
          confidence: item.confidenceFor('time'), // shares time confidence
          icon: Icons.refresh,
        ),
        ParsedAttribute(
          key: 'parent',
          label: 'Parent',
          displayValue: item.parentId == null ? 'No parent' : 'Linked',
          confidence: item.confidenceFor('parent'),
          icon: Icons.account_tree_outlined,
        ),
        ParsedAttribute(
          key: 'temperature',
          label: 'Temperature',
          displayValue: _temperatureLabel(item.temperature),
          confidence: item.confidenceFor('temperature'),
          icon: Icons.thermostat_outlined,
        ),
      ],
    );
  }
}

// ── label/icon helpers ─────────────────────────────────────────────────────

String _typeLabel(PlanItemType t) {
  return switch (t) {
    PlanItemType.task => 'Task',
    PlanItemType.errand => 'Errand',
    PlanItemType.call => 'Call',
    PlanItemType.appointment => 'Appointment',
    PlanItemType.medication => 'Medication',
    PlanItemType.note => 'Note',
    PlanItemType.project => 'Project',
    PlanItemType.unknown => 'Untyped',
  };
}

IconData _typeIcon(PlanItemType t) {
  return switch (t) {
    PlanItemType.task => Icons.check_box_outline_blank,
    PlanItemType.errand => Icons.shopping_bag_outlined,
    PlanItemType.call => Icons.phone_outlined,
    PlanItemType.appointment => Icons.event_outlined,
    PlanItemType.medication => Icons.medical_services_outlined,
    PlanItemType.note => Icons.sticky_note_2_outlined,
    PlanItemType.project => Icons.account_tree_outlined,
    PlanItemType.unknown => Icons.help_outline,
  };
}

String _timeLabel(ItemTime t) {
  return t.when<String>(
    hardTime: (DateTime at, _) {
      final DateTime local = at.toLocal();
      return '${_pad(local.hour)}:${_pad(local.minute)} on '
          '${local.month}/${local.day}';
    },
    timeWindow: (DateTime? from, DateTime until) {
      final DateTime u = until.toLocal();
      return 'By ${u.month}/${u.day}';
    },
    recurring: (_, __, ___) => 'Recurring',
    untimed: () => 'No specific time',
  );
}

String _recurrenceLabel(ItemTime t) {
  return t.when<String>(
    hardTime: (_, __) => 'One-off',
    timeWindow: (_, __) => 'One-off',
    recurring: (String rrule, _, __) {
      if (rrule == 'FREQ=DAILY') return 'Daily';
      if (rrule.startsWith('FREQ=WEEKLY;BYDAY=')) {
        return 'Weekly on a fixed day';
      }
      if (rrule == 'FREQ=WEEKLY') return 'Weekly';
      return 'Custom recurrence';
    },
    untimed: () => 'One-off',
  );
}

String _temperatureLabel(Temperature t) {
  return switch (t) {
    Temperature.hot => 'Hot',
    Temperature.warm => 'Warm',
    Temperature.cool => 'Cool',
  };
}

String _pad(int n) => n.toString().padLeft(2, '0');