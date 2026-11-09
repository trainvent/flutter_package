import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'triangle_loading_indicator.dart';

/// Pull-to-refresh with the Continuous trace instead of Material's spinner.
///
/// Pulling down past the top of [child] winds the trace forward with the drag.
/// Releasing beyond [triggerDistance] calls [onRefresh], and the trace runs
/// until the returned future completes.
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
    this.size = 40,
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

class _TriangleRefreshIndicatorState extends State<TriangleRefreshIndicator> {
  static const _fadeDuration = Duration(milliseconds: 200);
  static const _traceInset = 0.2;

  double _pulled = 0;
  bool _dragging = false;
  bool _refreshing = false;

  double get _fraction =>
      (_pulled / widget.triggerDistance).clamp(0.0, 1.0).toDouble();

  bool _onScroll(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification) || _refreshing) {
      return false;
    }
    final atTop = notification.metrics.extentBefore == 0;
    switch (notification) {
      case ScrollStartNotification(dragDetails: _?) when atTop:
        _dragging = true;
        _setPulled(0);
      case OverscrollNotification(:final overscroll, dragDetails: _?)
          when _dragging && overscroll < 0:
        _setPulled(_pulled - overscroll);
      // A bouncing list springs back before it ends, so the first update
      // without a finger is the release.
      case ScrollUpdateNotification(dragDetails: null) when _dragging:
        _release();
      case ScrollUpdateNotification(:final metrics, :final scrollDelta?)
          when _dragging:
        if (metrics.pixels < 0) {
          _setPulled(-metrics.pixels);
        } else if (scrollDelta > 0 && _pulled > 0) {
          _setPulled(math.max(0, _pulled - scrollDelta));
        }
      case ScrollEndNotification() when _dragging:
        _release();
      default:
        break;
    }
    return false;
  }

  void _release() {
    _dragging = false;
    if (_pulled >= widget.triggerDistance) {
      _refresh();
    } else {
      _setPulled(0);
    }
  }

  void _setPulled(double value) {
    if (value != _pulled) setState(() => _pulled = value);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _pulled = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = _refreshing || _pulled > 0;
    final top = _refreshing
        ? widget.displacement
        : _fraction * widget.displacement;
    final indicator = Container(
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
        progress: _refreshing ? null : AlwaysStoppedAnimation(_fraction),
      ),
    );
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: top,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: visible ? (_refreshing ? 1 : _fraction) : 0,
                duration: _fadeDuration,
                child: Center(
                  child: _refreshing
                      ? Semantics(
                          liveRegion: true,
                          label:
                              widget.semanticsLabel ??
                              MaterialLocalizations.of(
                                context,
                              ).refreshIndicatorSemanticLabel,
                          child: indicator,
                        )
                      : indicator,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
