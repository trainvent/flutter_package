import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// The animation family used by the loading indicator.
enum TriangleLoadingIndicatorMode {
  /// Recursively builds and zooms nested triangles.
  place,

  /// Follows the fixed circle and triangle route.
  trace,
}

/// The playback style of the Trace animation family.
enum TraceStyle {
  /// Burns away the route from its beginning with a glowing ember.
  fuze,

  /// Loops a moving segment over a faint guide.
  continuous,
}

/// An animated loading indicator made from recursively nested triangles.
///
/// By default the indicator animates continuously. Supply [progress] to drive
/// the animation externally, or [iterations] to limit the number of automatic
/// cycles.
class TriangleLoadingIndicator extends StatefulWidget {
  const TriangleLoadingIndicator({
    super.key,
    this.size = 48,
    this.targetDeg = 60,
    this.trianglesPerCycle = 6,
    Duration? iterationDuration,
    this.buildToZoomTimeRatio = 1.625,
    this.keepHistoryCycles = 2,
    this.strokeWidth = 2.2,
    this.strokeColor = const Color(0xFF111111),
    this.background = Colors.transparent,
    this.showFill = false,
    this.baseColor,
    this.baseHue = 26,
    this.saturation = 0.73,
    this.lightness = 0.52,
    this.hueStep = 7,
    this.maxDepth = 1500,
    this.progress,
    this.iterations,
    this.removingOld = true,
    this.oneByOne = false,
    this.zoomSpin = false,
    this.mode = TriangleLoadingIndicatorMode.place,
    this.traceStyle = TraceStyle.fuze,
    this.showArrow = true,
  }) : iterationDuration =
           iterationDuration ??
           (mode == TriangleLoadingIndicatorMode.trace &&
                   traceStyle == TraceStyle.continuous
               ? const Duration(milliseconds: 1800)
               : const Duration(milliseconds: 3400)),
       assert(iterations == null || iterations > 0),
       assert(buildToZoomTimeRatio > 0);

  final double size;
  final double targetDeg;
  final int trianglesPerCycle;

  /// Total time for one iteration.
  final Duration iterationDuration;

  /// Ratio of the time spent building to the time spent zooming.
  ///
  /// A value of 2 makes each build or removal phase take twice as long as the
  /// zoom phase. The default of 1.625 preserves the original 1300:800 timing.
  final double buildToZoomTimeRatio;
  final int keepHistoryCycles;
  final double strokeWidth;
  final Color strokeColor;

  /// Color shown inside the circle behind the triangles.
  final Color background;

  final bool showFill;
  final Color? baseColor;
  final double baseHue;
  final double saturation;
  final double lightness;
  final double hueStep;
  final int maxDepth;

  /// Controls a single animation cycle when supplied. Values should be in the
  /// range 0–1. When omitted, the indicator animates continuously.
  final Animation<double>? progress;

  /// Number of cycles to play, or null to animate endlessly.
  ///
  /// When [progress] is supplied, a non-null value is the number of complete
  /// cycles represented by that animation. A null value represents one full
  /// seamless visual loop; the owner of [progress] controls whether it repeats.
  final int? iterations;

  /// Removes the surrounding triangles, largest first, before each zoom.
  final bool removingOld;

  /// Advances the full nested set by one triangle during each cycle.
  ///
  /// When true, the current outer triangle is removed, a new innermost
  /// triangle is added, and the remaining set is zoomed outward. This removal
  /// happens regardless of [removingOld].
  final bool oneByOne;

  /// Rotates the camera during each zoom so the active triangle stays upright.
  /// When false, the camera zooms straight and triangle orientation alternates.
  final bool zoomSpin;

  /// The animation family, either Place or the fixed Trace route.
  final TriangleLoadingIndicatorMode mode;

  /// The playback style used when [mode] is [TriangleLoadingIndicatorMode.trace].
  final TraceStyle traceStyle;

  /// Whether the Continuous trace has an arrowhead on its leading edge.
  final bool showArrow;

  /// Number of iterations required for the geometry and visible hues to repeat.
  ///
  /// Outline-only animation needs two iterations by default. With fills, the
  /// original 7-degree hue step repeats after 60 iterations (seven hue turns).
  int get loopIterations {
    if (mode == TriangleLoadingIndicatorMode.trace) return 1;
    final depthStep = oneByOne ? 1 : trianglesPerCycle;
    final geometryPeriod = zoomSpin
        ? 1
        : _stepPeriod(targetDeg, depthStep, 120 * trianglesPerCycle);
    final colorPeriod = showFill ? _stepPeriod(hueStep, depthStep, 360) : 1;
    return geometryPeriod ~/ geometryPeriod.gcd(colorPeriod) * colorPeriod;
  }

  static int _stepPeriod(double degrees, int depthStep, int fullTurn) {
    // Convert decimal degree steps to integer ratios before finding their period.
    final scientific = degrees.abs().toString().toLowerCase().split('e');
    final decimal = scientific.first.split('.');
    final fractional = decimal.length == 2 ? decimal.last : '';
    final exponent = scientific.length == 2 ? int.parse(scientific.last) : 0;
    final decimalPlaces = fractional.length - exponent;
    var numerator = BigInt.parse('${decimal.first}$fractional');
    var denominator = BigInt.one;
    if (decimalPlaces >= 0) {
      denominator = BigInt.from(10).pow(decimalPlaces);
    } else {
      numerator *= BigInt.from(10).pow(-decimalPlaces);
    }
    final turn = BigInt.from(fullTurn) * denominator;
    final step = numerator * BigInt.from(depthStep);
    return (turn ~/ turn.gcd(step)).toInt();
  }

  @override
  State<TriangleLoadingIndicator> createState() =>
      _TriangleLoadingIndicatorState();
}

class _TriangleLoadingIndicatorState extends State<TriangleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _syncAutoplay();
  }

  @override
  void didUpdateWidget(covariant TriangleLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.iterations != widget.iterations ||
        oldWidget.iterationDuration != widget.iterationDuration ||
        oldWidget.buildToZoomTimeRatio != widget.buildToZoomTimeRatio ||
        oldWidget.targetDeg != widget.targetDeg ||
        oldWidget.trianglesPerCycle != widget.trianglesPerCycle ||
        oldWidget.hueStep != widget.hueStep ||
        oldWidget.showFill != widget.showFill ||
        oldWidget.maxDepth != widget.maxDepth ||
        oldWidget.removingOld != widget.removingOld ||
        oldWidget.oneByOne != widget.oneByOne ||
        oldWidget.zoomSpin != widget.zoomSpin ||
        oldWidget.mode != widget.mode ||
        oldWidget.traceStyle != widget.traceStyle) {
      if (oldWidget.progress != null && widget.progress == null) {
        _controller.value = 0;
      }
      _syncAutoplay();
    }
  }

  void _syncAutoplay() {
    assert(
      widget.iterationDuration.inMicroseconds > 0,
      'iterationDuration must be greater than zero.',
    );
    _controller.stop();
    if (widget.progress == null) {
      if (widget.iterations == null) {
        _controller.repeat(
          period: widget.iterationDuration * widget.loopIterations,
        );
      } else {
        _controller.duration = widget.iterationDuration * widget.iterations!;
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.progress ?? _controller;
    if (widget.mode == TriangleLoadingIndicatorMode.trace) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _TracePainter(
              style: widget.traceStyle,
              showArrow: widget.showArrow,
              strokeWidth: widget.strokeWidth,
              strokeColor: widget.strokeColor,
              background: widget.background,
              showFill: widget.showFill,
              fillColors:
                  widget.showFill && widget.traceStyle == TraceStyle.fuze
                  ? List.generate(
                      4,
                      (index) => HSLColor.fromAHSL(
                        1,
                        (HSLColor.fromColor(
                                  widget.baseColor ??
                                      Theme.of(context).colorScheme.primary,
                                ).hue +
                                index * widget.hueStep) %
                            360,
                        widget.saturation,
                        widget.lightness,
                      ).toColor(),
                    )
                  : const [],
              animation: animation,
              iterations: widget.iterations ?? 1,
              color: widget.baseColor ?? Theme.of(context).colorScheme.primary,
              reducedMotion: MediaQuery.disableAnimationsOf(context),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PlacePainter(
            animation: animation,
            iterations: widget.iterations ?? widget.loopIterations,
            targetDeg: widget.targetDeg,
            trianglesPerCycle: widget.trianglesPerCycle,
            buildToZoomTimeRatio: widget.buildToZoomTimeRatio,
            keepHistoryCycles: widget.keepHistoryCycles,
            strokeWidth: widget.strokeWidth,
            strokeColor: widget.strokeColor,
            background: widget.background,
            showFill: widget.showFill,
            baseColor:
                widget.baseColor ?? Theme.of(context).colorScheme.primary,
            saturation: widget.saturation,
            lightness: widget.lightness,
            hueStep: widget.hueStep,
            maxDepth: widget.maxDepth,
            removingOld: widget.removingOld,
            oneByOne: widget.oneByOne,
            zoomSpin: widget.zoomSpin,
          ),
        ),
      ),
    );
  }
}

class _PlacePainter extends CustomPainter {
  _PlacePainter({
    required this.animation,
    required this.iterations,
    required this.targetDeg,
    required this.trianglesPerCycle,
    required this.buildToZoomTimeRatio,
    required this.keepHistoryCycles,
    required this.strokeWidth,
    required this.strokeColor,
    required this.background,
    required this.showFill,
    required this.baseColor,
    required this.saturation,
    required this.lightness,
    required this.hueStep,
    required this.maxDepth,
    required this.removingOld,
    required this.oneByOne,
    required this.zoomSpin,
  }) : geometry = _PlaceGeometry(
         stepDeg: targetDeg / trianglesPerCycle,
         trianglesPerCycle: trianglesPerCycle,
         oneByOne: oneByOne,
         removingOld: removingOld,
         keepHistoryCycles: keepHistoryCycles,
         maxDepth: maxDepth,
       ),
       baseHue = HSLColor.fromColor(baseColor).hue,
       super(repaint: animation);

  final Animation<double> animation;
  final int iterations;
  final double targetDeg;
  final int trianglesPerCycle;
  final double buildToZoomTimeRatio;
  final int keepHistoryCycles;
  final double strokeWidth;
  final Color strokeColor;
  final Color background;
  final bool showFill;
  final Color baseColor;
  final double baseHue;
  final double saturation;
  final double lightness;
  final double hueStep;
  final int maxDepth;
  final bool removingOld;
  final bool oneByOne;
  final bool zoomSpin;
  final _PlaceGeometry geometry;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final cycles = animation.value.clamp(0.0, 1.0) * iterations;
    final cycleIndex = cycles.floor();
    final local = cycles - cycleIndex;
    final depthStep = oneByOne ? 1 : trianglesPerCycle;
    final hasRemoval = removingOld || oneByOne;
    final buildSpan =
        buildToZoomTimeRatio /
        (1 + (hasRemoval ? 2 : 1) * buildToZoomTimeRatio);
    final removalSpan = hasRemoval ? buildSpan : 0.0;
    final zoomSpan = 1 - buildSpan - removalSpan;
    final inRemoval = oneByOne
        ? local < removalSpan
        : hasRemoval && local >= buildSpan && local < buildSpan + removalSpan;
    final inBuild = oneByOne
        ? !inRemoval && local < removalSpan + buildSpan
        : local < buildSpan;
    final phaseProgress =
        (oneByOne
                ? inRemoval
                      ? local / removalSpan
                      : inBuild
                      ? (local - removalSpan) / buildSpan
                      : (local - removalSpan - buildSpan) / zoomSpan
                : inBuild
                ? local / buildSpan
                : inRemoval
                ? (local - buildSpan) / removalSpan
                : (local - buildSpan - removalSpan) / zoomSpan)
            .clamp(0.0, 1.0);
    final zoom = inBuild || inRemoval
        ? 0.0
        : phaseProgress < 0.5
        ? 4 * phaseProgress * phaseProgress * phaseProgress
        : 1 - math.pow(-2 * phaseProgress + 2, 3) / 2;
    final stepRadians = targetDeg / trianglesPerCycle * math.pi / 180;
    final endScale = math.pow(geometry.stepScale, -depthStep).toDouble();
    final endAngle = zoomSpin ? -depthStep * stepRadians : 0.0;
    final real = 1 + (endScale * math.cos(endAngle) - 1) * zoom;
    final imaginary = endScale * math.sin(endAngle) * zoom;
    final radius = math.min(size.width, size.height) * 0.46;
    final cameraScale = radius * math.sqrt(real * real + imaginary * imaginary);
    final rotation =
        (zoomSpin
            ? 0.0
            : (cycleIndex * depthStep * stepRadians) % (2 * math.pi / 3)) +
        math.atan2(imaginary, real);
    final center = Offset(size.width / 2, size.height / 2);
    final circle = Rect.fromCircle(center: center, radius: radius);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawCircle(center, radius, Paint()..color = background);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.scale(cameraScale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / cameraScale;
    final fill = Paint();

    void drawAt(int depth, double alpha) {
      final path = geometry.paths[depth];
      if (path == null || alpha <= 0) return;
      if (showFill) {
        final hue =
            (baseHue + (cycleIndex * depthStep + depth) * hueStep) % 360;
        fill.color = HSLColor.fromAHSL(
          alpha,
          hue,
          saturation,
          lightness,
        ).toColor();
        canvas.drawPath(path, fill);
      }
      stroke.color = strokeColor.withValues(alpha: alpha);
      canvas.drawPath(path, stroke);
    }

    void drawRange(int first, int last) {
      for (var depth = first; depth <= last; depth++) {
        drawAt(depth, 1);
      }
    }

    if (oneByOne) {
      if (inRemoval) {
        drawAt(0, 1 - phaseProgress);
        drawRange(1, trianglesPerCycle);
      } else if (inBuild) {
        drawRange(1, trianglesPerCycle);
        drawAt(trianglesPerCycle + 1, phaseProgress);
      } else {
        drawRange(1, trianglesPerCycle + 1);
      }
    } else if (inRemoval) {
      final removal = phaseProgress * depthStep;
      final first = removal.floor();
      drawAt(first, 1 - (removal - first));
      drawRange(first + 1, depthStep);
    } else if (inBuild) {
      final depth = phaseProgress * depthStep;
      drawRange(geometry.firstDepth, depth.floor());
      drawAt(depth.floor() + 1, depth - depth.floor());
    } else {
      if (removingOld) {
        drawAt(depthStep, 1);
      } else {
        for (var depth = geometry.firstDepth; depth <= depthStep; depth++) {
          drawAt(depth, depth < geometry.firstDepth + depthStep ? 1 - zoom : 1);
        }
      }
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PlacePainter oldDelegate) =>
      animation != oldDelegate.animation ||
      iterations != oldDelegate.iterations ||
      targetDeg != oldDelegate.targetDeg ||
      trianglesPerCycle != oldDelegate.trianglesPerCycle ||
      buildToZoomTimeRatio != oldDelegate.buildToZoomTimeRatio ||
      keepHistoryCycles != oldDelegate.keepHistoryCycles ||
      strokeWidth != oldDelegate.strokeWidth ||
      strokeColor != oldDelegate.strokeColor ||
      background != oldDelegate.background ||
      showFill != oldDelegate.showFill ||
      baseColor != oldDelegate.baseColor ||
      saturation != oldDelegate.saturation ||
      lightness != oldDelegate.lightness ||
      hueStep != oldDelegate.hueStep ||
      maxDepth != oldDelegate.maxDepth ||
      removingOld != oldDelegate.removingOld ||
      oneByOne != oldDelegate.oneByOne ||
      zoomSpin != oldDelegate.zoomSpin;
}

class _PlaceGeometry {
  _PlaceGeometry({
    required double stepDeg,
    required int trianglesPerCycle,
    required bool oneByOne,
    required bool removingOld,
    required int keepHistoryCycles,
    required int maxDepth,
  }) {
    final radians = stepDeg * math.pi / 180;
    final denominator = math.cos(radians) + math.sqrt(3) * math.sin(radians);
    stepScale = denominator > 1 ? 1 / denominator : 1;
    firstDepth = oneByOne || removingOld
        ? 0
        : -math.min(keepHistoryCycles * trianglesPerCycle, maxDepth - 1);
    final lastDepth = math.min(
      oneByOne ? trianglesPerCycle + 1 : trianglesPerCycle,
      maxDepth - 1,
    );
    for (var depth = firstDepth; depth <= lastDepth; depth++) {
      final radius = math.pow(stepScale, depth).toDouble();
      paths[depth] = Path()
        ..addPolygon(
          List.generate(3, (corner) {
            final angle =
                -math.pi / 2 + depth * radians + corner * 2 * math.pi / 3;
            return Offset(radius * math.cos(angle), radius * math.sin(angle));
          }),
          true,
        );
    }
  }

  late final double stepScale;
  late final int firstDepth;
  final paths = <int, Path>{};
}

class _TracePainter extends CustomPainter {
  const _TracePainter({
    required this.style,
    required this.showArrow,
    required this.strokeWidth,
    required this.strokeColor,
    required this.background,
    required this.showFill,
    required this.fillColors,
    required this.animation,
    required this.iterations,
    required this.color,
    required this.reducedMotion,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final int iterations;
  double get progress => animation.value.clamp(0.0, 1.0) * iterations;
  final Color color;
  final bool reducedMotion;

  final TraceStyle style;
  final bool showArrow;
  final double strokeWidth;
  final Color strokeColor;
  final Color background;
  final bool showFill;
  final List<Color> fillColors;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == TraceStyle.continuous) {
      _paintContinuous(canvas, size);
    } else {
      final fraction =
          progress > 0 && (progress - progress.round()).abs() < 1e-9
          ? 1.0
          : progress % 1;
      _paintFuze(canvas, size, fraction);
    }
  }

  void _paintFuze(Canvas canvas, Size size, double progress) {
    final scale = math.min(size.width, size.height) / 900;
    canvas.save();
    canvas.translate(
      (size.width - 900 * scale) / 2,
      (size.height - 900 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawCircle(const Offset(450, 450), 445, Paint()..color = background);
    if (showFill) {
      const triangles = [
        [
          Offset(450, 9.45),
          Offset(831.5275, 670.275),
          Offset(68.4725, 670.275),
        ],
        [
          Offset(548.3474, 179.7927),
          Offset(634.8327, 670.275),
          Offset(166.8199, 499.9323),
        ],
        [
          Offset(570.641, 306.2257),
          Offset(514.1917, 626.3653),
          Offset(265.1673, 417.409),
        ],
        [
          Offset(556.0899, 388.749),
          Offset(450, 572.502),
          Offset(343.9101, 388.749),
        ],
      ];
      for (var index = 0; index < triangles.length; index++) {
        canvas.drawPath(
          Path()..addPolygon(triangles[index], true),
          Paint()..color = fillColors[index].withValues(alpha: 1 - progress),
        );
      }
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = strokeColor;
    final metric = _TraceGeometry.metric;
    final distance = metric.length * progress;
    canvas.drawPath(metric.extractPath(distance, metric.length), stroke);
    if (progress <= 0 || progress >= 1) {
      canvas.restore();
      return;
    }
    final tip = metric.getTangentForOffset(distance)!.position;
    final emberRadius = math.max(1.5, strokeWidth * 0.9) / scale;
    final glowRadius = emberRadius * 4;
    canvas.drawCircle(
      tip,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFB347).withValues(alpha: 0.85),
            const Color(0xFFFF6B00).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: tip, radius: glowRadius)),
    );
    canvas.drawCircle(
      tip,
      emberRadius,
      Paint()..color = const Color(0xFFFFF1DC),
    );
    canvas.restore();
  }

  void _paintContinuous(Canvas canvas, Size size) {
    final route = _TraceGeometry.route;
    final scale = math.min(size.width, size.height) / 1040;
    canvas.save();
    canvas.translate(
      (size.width - 900 * scale) / 2,
      (size.height - 900 * scale) / 2,
    );
    canvas.scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 44
      ..color = color.withValues(alpha: color.a * 0.35);
    canvas.drawPath(route, stroke);
    stroke
      ..strokeWidth = 60
      ..color = color;
    if (reducedMotion) {
      canvas.drawPath(route, stroke);
    } else {
      final metric = _TraceGeometry.metric;
      final start = (progress % 1) * metric.length;
      final end = start + metric.length * 0.26;
      canvas.drawPath(
        metric.extractPath(start, math.min(end, metric.length)),
        stroke,
      );
      if (end > metric.length) {
        canvas.drawPath(metric.extractPath(0, end - metric.length), stroke);
      }
      if (showArrow) {
        final head = metric.getTangentForOffset(end % metric.length)!;
        final forward = head.vector;
        final normal = Offset(-forward.dy, forward.dx);
        final tip = head.position + forward * 80;
        final base = head.position - forward * 40;
        canvas.drawPath(
          Path()
            ..addPolygon([tip, base + normal * 66, base - normal * 66], true),
          Paint()..color = color,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) =>
      style != oldDelegate.style ||
      showArrow != oldDelegate.showArrow ||
      strokeWidth != oldDelegate.strokeWidth ||
      strokeColor != oldDelegate.strokeColor ||
      background != oldDelegate.background ||
      showFill != oldDelegate.showFill ||
      !listEquals(fillColors, oldDelegate.fillColors) ||
      animation != oldDelegate.animation ||
      iterations != oldDelegate.iterations ||
      color != oldDelegate.color ||
      reducedMotion != oldDelegate.reducedMotion;
}

class _TraceGeometry {
  static final triangles = Path()
    ..moveTo(450, 9.45)
    ..lineTo(548.3474, 179.7927)
    ..lineTo(831.5275, 670.275)
    ..lineTo(634.8327, 670.275)
    ..lineTo(68.4725, 670.275)
    ..lineTo(166.8199, 499.9323)
    ..lineTo(514.1917, 626.3653)
    ..lineTo(634.8327, 670.275)
    ..lineTo(570.641, 306.2257)
    ..lineTo(548.3474, 179.7927)
    ..lineTo(265.1673, 417.409)
    ..lineTo(343.9101, 388.749)
    ..lineTo(570.641, 306.2257)
    ..lineTo(556.0899, 388.749)
    ..lineTo(514.1917, 626.3653)
    ..lineTo(450, 572.502)
    ..lineTo(556.0899, 388.749)
    ..lineTo(343.9101, 388.749)
    ..lineTo(450, 572.502)
    ..lineTo(265.1673, 417.409)
    ..lineTo(166.8199, 499.9323)
    ..lineTo(450, 9.45);

  static final route = Path()
    ..moveTo(450, 9.45)
    ..arcToPoint(
      const Offset(831.5275, 670.275),
      radius: const Radius.circular(445),
    )
    ..arcToPoint(
      const Offset(68.4725, 670.275),
      radius: const Radius.circular(445),
    )
    ..arcToPoint(const Offset(450, 9.45), radius: const Radius.circular(445))
    ..extendWithPath(triangles, Offset.zero);

  static final metric = route.computeMetrics().single;
}
