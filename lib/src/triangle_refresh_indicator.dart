import 'package:material_ui/material_ui.dart';

import 'triangle_loading_indicator.dart';

/// Pull-to-refresh with the Continuous trace instead of Material's spinner.
///
/// Pulling down past the top of [child] slides the indicator in from above
/// and winds the trace with the drag. Releasing beyond [triggerDistance] calls
/// [onRefresh], and the trace runs until the returned future completes.
///
/// Like [RefreshIndicator], the scrollable inside [child] needs
/// [AlwaysScrollableScrollPhysics] so short lists can still be pulled.
class TriangleRefreshIndicator extends StatefulWidget {
  const TriangleRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.triggerDistance = 80,
    this.displacement = 40,
    this.size = 48,
    this.color,
    this.backgroundColor,
    this.semanticsLabel,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  final Widget child;
  final Future<void> Function() onRefresh;

  /// How far the user has to pull before releasing starts a refresh.
  final double triggerDistance;

  /// Where the indicator rests below the top edge while refreshing.
  final double displacement;

  /// Diameter of the round indicator.
  final double size;

  /// Trace colour. Defaults to the theme's primary colour.
  final Color? color;

  /// Disc colour behind the trace. Defaults to the theme's
  /// `surfaceContainerHigh`.
  final Color? backgroundColor;

  /// Announced while refreshing. Defaults to the Material "Refresh" label.
  final String? semanticsLabel;

  /// Which scroll notifications to react to; by default only the nearest
  /// scrollable.
  final ScrollNotificationPredicate notificationPredicate;

  @override
  State<TriangleRefreshIndicator> createState() =>
      _TriangleRefreshIndicatorState();
}

enum _Phase { idle, dragging, refreshing, finishing }

class _TriangleRefreshIndicatorState extends State<TriangleRefreshIndicator>
    with TickerProviderStateMixin {
  static const _settleDuration = Duration(milliseconds: 200);
  static const _traceInset = 0.14;

  /// The pull as a share of the trigger distance. It drives the slide and the
  /// trace directly, so dragging repaints only the indicator.
  late final AnimationController _pull = AnimationController(
    vsync: this,
    upperBound: double.infinity,
  );

  /// Shrinks the indicator away once a refresh has finished.
  late final AnimationController _finish = AnimationController(
    vsync: this,
    duration: _settleDuration,
  );

  _Phase _phase = _Phase.idle;
  double _pulled = 0;

  @override
  void dispose() {
    _pull.dispose();
    _finish.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification) ||
        _phase == _Phase.refreshing ||
        _phase == _Phase.finishing) {
      return false;
    }
    final dragging = _phase == _Phase.dragging;
    switch (notification) {
      case ScrollStartNotification(dragDetails: _?)
          when notification.metrics.extentBefore == 0:
        _phase = _Phase.dragging;
        _pull.stop();
        _setPulled(0);
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when dragging && overscroll < 0:
        _setPulled(_pulled - overscroll);
      // A bouncing list springs back before it ends, so the first update
      // without a finger is the release.
      case ScrollUpdateNotification(dragDetails: null) when dragging:
        _release();
      case ScrollUpdateNotification(:final metrics, :final scrollDelta?)
          when dragging:
        if (metrics.pixels < 0) {
          _setPulled(-metrics.pixels);
        } else if (scrollDelta > 0 && _pulled > 0) {
          _setPulled((_pulled - scrollDelta).clamp(0, double.infinity));
        }
      case ScrollEndNotification() when dragging:
        _release();
      default:
        break;
    }
    return false;
  }

  void _setPulled(double value) {
    _pulled = value;
    _pull.value = value / widget.triggerDistance;
  }

  void _release() {
    if (_pulled >= widget.triggerDistance) {
      _refresh();
    } else {
      _phase = _Phase.idle;
      _pulled = 0;
      _pull.animateTo(0, duration: _settleDuration, curve: Curves.easeOut);
    }
  }

  Future<void> _refresh() async {
    setState(() => _phase = _Phase.refreshing);
    _pull.animateTo(1, duration: _settleDuration, curve: Curves.easeOut);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _phase = _Phase.finishing);
        await _finish.forward(from: 0);
        if (mounted) {
          _pull.value = 0;
          _pulled = 0;
          _finish.value = 0;
          setState(() => _phase = _Phase.idle);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final running = _phase == _Phase.refreshing || _phase == _Phase.finishing;
    final disc = Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(widget.size * _traceInset),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colors.surfaceContainerHigh,
        shape: BoxShape.circle,
        boxShadow: kElevationToShadow[2],
      ),
      child: TriangleLoadingIndicator(
        size: widget.size * (1 - 2 * _traceInset),
        mode: TriangleLoadingIndicatorMode.trace,
        traceStyle: TraceStyle.continuous,
        baseColor: widget.color ?? colors.primary,
        progress: running ? null : _pull,
      ),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          AnimatedBuilder(
            animation: Listenable.merge([_pull, _finish]),
            child: running
                ? Semantics(
                    liveRegion: true,
                    label:
                        widget.semanticsLabel ??
                        MaterialLocalizations.of(
                          context,
                        ).refreshIndicatorSemanticLabel,
                    child: disc,
                  )
                : disc,
            builder: (context, child) {
              final reach = _pull.value.clamp(0.0, 1.0);
              final shown = 1 - _finish.value;
              final hidden = reach == 0 && !running;
              return Positioned(
                // Slides in from just above the top edge to its resting spot.
                top: -widget.size + reach * (widget.size + widget.displacement),
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Offstage(
                    offstage: hidden,
                    child: Center(
                      child: Opacity(
                        opacity: shown,
                        child: Transform.scale(scale: shown, child: child),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
