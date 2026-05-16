import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import 'day_tile.dart';

/// A single entry in the date train: enough data to render a [DayTile]
/// and identify it for tap handling.
class DateTrainEntry {
  const DateTrainEntry({
    required this.date,
    required this.weekdayLabel,
    required this.fullDateForA11y,
    required this.state,
    this.pill,
  });

  /// The day this tile represents (UTC midnight). Used as the key for
  /// the entry; tap callbacks receive this.
  final DateTime date;

  final String weekdayLabel;
  final String fullDateForA11y;
  final DayTileState state;
  final DayTilePill? pill;
}

/// The horizontally scrollable date strip used at the top of the
/// landing screen (PDD §13).
///
/// Stateless because the data model is owned by Riverpod providers
/// upstream. This widget only renders.
///
/// ### Anchoring
///
/// On first build, the train scrolls so that the focused tile sits at
/// 1/4 from the left edge of the visible area — close enough to be
/// the visual anchor, with two past days visible to its left. If the
/// caller updates [entries] and the focused tile moves, the train
/// scrolls smoothly to follow.
class DateTrain extends StatefulWidget {
  const DateTrain({
    super.key,
    required this.entries,
    required this.onTap,
  });

  final List<DateTrainEntry> entries;

  /// Called when the user taps a tile. Receives the [DateTrainEntry.date].
  final void Function(DateTime date) onTap;

  @override
  State<DateTrain> createState() => _DateTrainState();
}

class _DateTrainState extends State<DateTrain> {
  final ScrollController _controller = ScrollController();
  static const double _gap = AppSpacing.sm;

  int? _focusedIndex(List<DateTrainEntry> entries) {
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].state == DayTileState.focused) return i;
    }
    return null;
  }

  void _scrollToFocused({bool animate = false}) {
    final int? focused = _focusedIndex(widget.entries);
    if (focused == null || !_controller.hasClients) return;

    final double tileStride = AppSpacing.dayTileWidth + _gap;
    final double viewport = _controller.position.viewportDimension;
    final double targetCenter = focused * tileStride + tileStride / 2;
    // Place the focused tile at 1/4 from the left edge.
    double offset = targetCenter - viewport * 0.25;
    offset = offset.clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );

    if (animate) {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(offset);
    }
  }

  @override
  void initState() {
    super.initState();
    // Defer until after first layout so the viewport dimension exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToFocused();
    });
  }

  @override
  void didUpdateWidget(covariant DateTrain old) {
    super.didUpdateWidget(old);
    final int? oldFocus = _focusedIndex(old.entries);
    final int? newFocus = _focusedIndex(widget.entries);
    if (oldFocus != newFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToFocused(animate: true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.dayTileHeight + 8,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Date train',
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: widget.entries.length,
          separatorBuilder: (_, __) => const SizedBox(width: _gap),
          itemBuilder: (BuildContext context, int index) {
            final DateTrainEntry e = widget.entries[index];
            return DayTile(
              weekdayLabel: e.weekdayLabel,
              dayOfMonth: e.date.day,
              state: e.state,
              pill: e.pill,
              fullDateForA11y: e.fullDateForA11y,
              onTap: () => widget.onTap(e.date),
            );
          },
        ),
      ),
    );
  }
}