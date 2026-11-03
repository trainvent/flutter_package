import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainvent_general/trainvent_general.dart';

class TriangleLoadingIndicatorScreen extends StatefulWidget {
  const TriangleLoadingIndicatorScreen({super.key});

  @override
  State<TriangleLoadingIndicatorScreen> createState() =>
      _TriangleLoadingIndicatorScreenState();
}

class _TriangleLoadingIndicatorScreenState
    extends State<TriangleLoadingIndicatorScreen>
    with SingleTickerProviderStateMixin {
  static const _defaults = TriangleLoadingIndicator();

  late final AnimationController _playback;
  late final TextEditingController _iterationDurationController;
  late final TextEditingController _iterationCountController;
  String? _iterationCountError;
  bool _showColor = _defaults.showFill;
  bool _zoomSpin = _defaults.zoomSpin;
  bool _showArrow = _defaults.showArrow;
  TriangleLoadingIndicatorMode _mode = _defaults.mode;
  TraceStyle _traceStyle = _defaults.traceStyle;

  bool get _trace => _mode == TriangleLoadingIndicatorMode.trace;
  bool get _continuous => _trace && _traceStyle == TraceStyle.continuous;
  bool _removingOld = _defaults.removingOld;
  bool _oneByOne = _defaults.oneByOne;
  bool _resumeAfterScrub = false;
  int? _iterations = _defaults.iterations;
  Duration _iterationDuration = _defaults.iterationDuration;

  bool get _isDefault =>
      _showColor == _defaults.showFill &&
      _zoomSpin == _defaults.zoomSpin &&
      _showArrow == _defaults.showArrow &&
      _mode == _defaults.mode &&
      _traceStyle == _defaults.traceStyle &&
      _removingOld == _defaults.removingOld &&
      _oneByOne == _defaults.oneByOne &&
      _iterations == _defaults.iterations &&
      _iterationDuration == _defaults.iterationDuration;

  int get _seamlessLoopIterations => TriangleLoadingIndicator(
    mode: _mode,
    traceStyle: _traceStyle,
    showFill: _showColor,
    oneByOne: _oneByOne,
    zoomSpin: _zoomSpin,
  ).loopIterations;

  int get _playbackIterations => _iterations ?? _seamlessLoopIterations;

  Duration get _cycleDuration => _iterationDuration;

  @override
  void initState() {
    super.initState();
    _iterationDurationController = TextEditingController(
      text: _iterationDuration.inMilliseconds.toString(),
    );
    _iterationCountController = TextEditingController(
      text: _iterations?.toString() ?? '',
    );
    _playback = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() {});
      });
    _startPlayback();
  }

  @override
  void dispose() {
    _iterationDurationController.dispose();
    _iterationCountController.dispose();
    _playback.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      if (_playback.isAnimating) {
        _playback.stop();
      } else {
        _startPlayback(reset: _playback.isCompleted);
      }
    });
  }

  void _startPlayback({bool reset = true}) {
    _playback.duration = _cycleDuration * _playbackIterations;
    if (_iterations == null) {
      if (reset) _playback.value = 0;
      _playback.repeat();
    } else {
      _playback.forward(from: reset ? 0 : null);
    }
  }

  void _restart() {
    setState(() => _startPlayback());
  }

  void _resetToDefaults() {
    setState(() {
      _showColor = _defaults.showFill;
      _zoomSpin = _defaults.zoomSpin;
      _showArrow = _defaults.showArrow;
      _mode = _defaults.mode;
      _traceStyle = _defaults.traceStyle;
      _removingOld = _defaults.removingOld;
      _oneByOne = _defaults.oneByOne;
      _iterations = _defaults.iterations;
      _iterationCountController.clear();
      _iterationCountError = null;
      _iterationDuration = _defaults.iterationDuration;
      _iterationDurationController.text = _iterationDuration.inMilliseconds
          .toString();
      _resumeAfterScrub = false;
      _startPlayback();
    });
  }

  void _setAnimation(TriangleLoadingIndicatorMode mode, TraceStyle style) {
    setState(() {
      _mode = mode;
      _traceStyle = style;
      _iterations = null;
      _iterationCountController.clear();
      _iterationCountError = null;
      _iterationDuration = TriangleLoadingIndicator(
        mode: mode,
        traceStyle: style,
      ).iterationDuration;
      _iterationDurationController.text = _iterationDuration.inMilliseconds
          .toString();
      _startPlayback();
    });
  }

  void _setIterations(int? value, {bool updateText = true}) {
    if (value != null && value < 1) return;
    setState(() {
      _iterations = value;
      _iterationCountError = null;
      if (updateText) _iterationCountController.text = value?.toString() ?? '';
      _startPlayback();
    });
  }

  void _setIterationsFromText(String text) {
    if (text.isEmpty) {
      _setIterations(null, updateText: false);
      return;
    }
    final value = int.tryParse(text);
    if (value == null || value < 1) {
      setState(() => _iterationCountError = 'Use 1 or more');
      return;
    }
    _setIterations(value, updateText: false);
  }

  void _setIterationDuration(String value) {
    final milliseconds = int.tryParse(value);
    if (milliseconds == null || milliseconds <= 0) return;

    final duration = Duration(milliseconds: milliseconds);
    if (duration == _iterationDuration) return;

    setState(() {
      _iterationDuration = duration;
      _startPlayback();
    });
  }

  String _formatTime(double progress) {
    final elapsed =
        (_playback.duration ?? _defaults.iterationDuration) * progress;
    final seconds = elapsed.inSeconds;
    final tenths = (elapsed.inMilliseconds % 1000) ~/ 100;
    return '$seconds.$tenths s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triangle Loading Indicator'),
        actions: [
          IconButton(
            tooltip: 'Reset to defaults',
            onPressed: _isDefault ? null : _resetToDefaults,
            icon: const Icon(Icons.settings_backup_restore),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = math.min(
                    constraints.maxWidth * 0.62,
                    constraints.maxHeight * 0.72,
                  );
                  return RepaintBoundary(
                    child: CustomPaint(
                      painter: const _TransparencyPatternPainter(),
                      child: Center(
                        child: TriangleLoadingIndicator(
                          key: const ValueKey('triangle-playground-preview'),
                          size: previewSize,
                          showFill: _showColor,
                          progress: _playback,
                          iterations: _iterations,
                          iterationDuration: _iterationDuration,
                          removingOld: _removingOld,
                          oneByOne: _oneByOne,
                          zoomSpin: _zoomSpin,
                          mode: _mode,
                          traceStyle: _traceStyle,
                          showArrow: _showArrow,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: DropdownButtonFormField<TriangleLoadingIndicatorMode>(
                key: ValueKey(_mode),
                initialValue: _mode,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(
                    value: TriangleLoadingIndicatorMode.place,
                    child: Text('Place'),
                  ),
                  DropdownMenuItem(
                    value: TriangleLoadingIndicatorMode.trace,
                    child: Text('Trace'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) _setAnimation(value, _traceStyle);
                },
              ),
            ),
            if (_trace)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: SegmentedButton<TraceStyle>(
                  segments: const [
                    ButtonSegment(value: TraceStyle.fuze, label: Text('Fuze')),
                    ButtonSegment(
                      value: TraceStyle.continuous,
                      label: Text('Continuous'),
                    ),
                  ],
                  selected: {_traceStyle},
                  onSelectionChanged: (selection) =>
                      _setAnimation(_mode, selection.single),
                ),
              ),
            if (_trace && _continuous)
              SwitchListTile.adaptive(
                key: const ValueKey('continuous-arrow-switch'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text('Arrow'),
                value: _showArrow,
                onChanged: (value) => setState(() => _showArrow = value),
              ),
            if (!_trace)
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                title: const Text('Zoom spin'),
                subtitle: Text(
                  _zoomSpin
                      ? 'Keep the active triangle pointing up'
                      : 'Zoom straight and alternate up/down',
                ),
                value: _zoomSpin,
                onChanged: (value) {
                  setState(() {
                    _zoomSpin = value;
                    _startPlayback();
                  });
                },
              ),
            if (!_trace)
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text('Remove old triangles'),
                subtitle: const Text(
                  'Deconstruct from largest to smallest before zooming',
                ),
                value: _removingOld,
                onChanged: (value) {
                  setState(() {
                    _removingOld = value;
                    _startPlayback();
                  });
                },
              ),
            if (!_trace)
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                title: const Text('One by one'),
                subtitle: const Text(
                  'Remove, build, and zoom one triangle per cycle',
                ),
                value: _oneByOne,
                onChanged: (value) {
                  setState(() {
                    _oneByOne = value;
                    _startPlayback();
                  });
                },
              ),
            if (!_continuous)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.palette_outlined),
                      label: Text('Color'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.change_history),
                      label: Text('Outline'),
                    ),
                  ],
                  selected: {_showColor},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _showColor = selection.first;
                      _startPlayback();
                    });
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 24,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 190,
                    child: TextField(
                      key: const ValueKey('iteration-duration-field'),
                      controller: _iterationDurationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Iteration duration',
                        suffixText: 'ms',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _setIterationDuration,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.outlined(
                        tooltip: 'Decrease iterations',
                        onPressed: _iterations != null && _iterations! > 1
                            ? () => _setIterations(_iterations! - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: TextField(
                          key: const ValueKey('iteration-count-field'),
                          controller: _iterationCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'Iterations',
                            hintText: '∞',
                            border: const OutlineInputBorder(),
                            errorText: _iterationCountError,
                          ),
                          onChanged: _setIterationsFromText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Increase iterations',
                        onPressed: () => _setIterations((_iterations ?? 0) + 1),
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        key: const ValueKey('endless-iterations-button'),
                        tooltip: 'Endless',
                        isSelected: _iterations == null,
                        onPressed: () => _setIterations(null),
                        icon: const Icon(Icons.all_inclusive),
                        selectedIcon: const Icon(Icons.all_inclusive),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _playback,
                builder: (context, _) => _buildPlaybackControls(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Slider(
              value: _playback.value,
              onChangeStart: (_) {
                _resumeAfterScrub = _playback.isAnimating;
                _playback.stop();
              },
              onChanged: (value) => _playback.value = value,
              onChangeEnd: (_) {
                if (_resumeAfterScrub) {
                  _startPlayback(reset: false);
                }
              },
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Restart',
                  onPressed: _restart,
                  icon: const Icon(Icons.replay),
                ),
                Expanded(
                  child: Center(
                    child: FilledButton.tonalIcon(
                      onPressed: _togglePlayback,
                      icon: Icon(
                        _playback.isAnimating ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(_playback.isAnimating ? 'Pause' : 'Play'),
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    _formatTime(_playback.value),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransparencyPatternPainter extends CustomPainter {
  const _TransparencyPatternPainter();

  static const _tileSize = 16.0;
  static const _light = Color(0xFFF5F5F5);
  static const _dark = Color(0xFFDADADA);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += _tileSize) {
      final row = (y / _tileSize).floor();
      for (var x = 0.0; x < size.width; x += _tileSize) {
        final column = (x / _tileSize).floor();
        paint.color = (row + column).isEven ? _light : _dark;
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            y,
            math.min(_tileSize, size.width - x),
            math.min(_tileSize, size.height - y),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransparencyPatternPainter oldDelegate) =>
      false;
}
