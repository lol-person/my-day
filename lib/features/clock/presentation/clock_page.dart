// lib/features/clock/presentation/clock_page.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClockPage extends StatefulWidget {
  const ClockPage({super.key});

  @override
  State<ClockPage> createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _currentPage = 0;

  static const Color _flipBackground = Color(0xFF15161B);
  static const Color _flipTile = Color(0xFF292B32);
  static const Color _digitalBackground = Color(0xFF0C1510);
  static const Color _digitalForeground = Color(0xFF69F0AE);

  static const List<String> _styleNames = [
    'Flip Clock',
    'Минимализм',
    'Digital',
  ];

  @override
  void initState() {
    super.initState();

    unawaited(_enterFullscreenLandscape());

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  Future<void> _enterFullscreenLandscape() async {
    try {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (error) {
      debugPrint('Не удалось включить полноэкранные часы: $error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    // При выходе из часов возвращаем обычную ориентацию приложения
    // и системные панели Android.
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));

    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String get _formattedDate {
    const weekdays = [
      'понедельник',
      'вторник',
      'среда',
      'четверг',
      'пятница',
      'суббота',
      'воскресенье',
    ];

    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${weekdays[_now.weekday - 1]}, '
        '${_now.day} ${months[_now.month - 1]}';
  }

  Widget _buildFlipDigit({
    required String digit,
    required double width,
    required double height,
    required double fontSize,
  }) {
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _flipTile,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Верхняя и нижняя половины карточки.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height / 2,
            child: Container(color: const Color(0xFF30323A)),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return ClipRect(
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.35),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
              child: FittedBox(
                key: ValueKey<String>(digit),
                fit: BoxFit.scaleDown,
                child: Text(
                  digit,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: height / 2 - 1,
            child: Container(
              height: 2,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: height / 2,
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipPair({
    required int value,
    required double digitWidth,
    required double digitHeight,
    required double fontSize,
  }) {
    final digits = _twoDigits(value);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFlipDigit(
          digit: digits[0],
          width: digitWidth,
          height: digitHeight,
          fontSize: fontSize,
        ),
        SizedBox(width: digitWidth * 0.07),
        _buildFlipDigit(
          digit: digits[1],
          width: digitWidth,
          height: digitHeight,
          fontSize: fontSize,
        ),
      ],
    );
  }

  Widget _buildFlipStyle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final width = constraints.maxWidth;

        final digitHeight = math.min(height * 0.63, 270.0);
        final digitWidth = math.min(digitHeight * 0.59, width * 0.185);
        final fontSize = digitHeight * 0.7;

        return Container(
          color: _flipBackground,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'FLIP CLOCK',
                      style: TextStyle(
                        color: Color(0xFFB9BBC5),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFlipPair(
                              value: _now.hour,
                              digitWidth: digitWidth,
                              digitHeight: digitHeight,
                              fontSize: fontSize,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: digitWidth * 0.12,
                              ),
                              child: Text(
                                ':',
                                style: TextStyle(
                                  color: const Color(0xFFB9BBC5),
                                  fontSize: fontSize * 0.85,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _buildFlipPair(
                              value: _now.minute,
                              digitWidth: digitWidth,
                              digitHeight: digitHeight,
                              fontSize: fontSize,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formattedDate,
                            style: const TextStyle(
                              color: Color(0xFFB9BBC5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          _twoDigits(_now.second),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimalStyle() {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final timeFontSize = math.min(
          height * 0.37,
          constraints.maxWidth * 0.15,
        );

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'СЕЙЧАС',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_twoDigits(_now.hour)}:'
                              '${_twoDigits(_now.minute)}',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: timeFontSize,
                                fontWeight: FontWeight.w300,
                                letterSpacing: -3,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _formattedDate,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'СЕКУНДЫ  ${_twoDigits(_now.second)}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDigitalStyle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final timeFontSize = math.min(
          height * 0.34,
          constraints.maxWidth * 0.14,
        );

        return Container(
          color: _digitalBackground,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: _digitalForeground, size: 9),
                        SizedBox(width: 8),
                        Text(
                          'DIGITAL',
                          style: TextStyle(
                            color: _digitalForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_twoDigits(_now.hour)}:'
                              '${_twoDigits(_now.minute)}',
                              style: TextStyle(
                                color: _digitalForeground,
                                fontFamily: 'monospace',
                                fontSize: timeFontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -2,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x8869F0AE),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ':${_twoDigits(_now.second)}',
                              style: TextStyle(
                                color: _digitalForeground,
                                fontFamily: 'monospace',
                                fontSize: timeFontSize * 0.38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formattedDate,
                      style: const TextStyle(
                        color: Color(0xFF9AB9A7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _flipBackground,
      body: Stack(
        children: [
          PageView(
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildFlipStyle(),
              _buildMinimalStyle(),
              _buildDigitalStyle(),
            ],
          ),
          Positioned(
            top: 10,
            right: 14,
            child: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final selected = index == _currentPage;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 17 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 8,
            child: SafeArea(
              child: IgnorePointer(
                child: Text(
                  _styleNames[_currentPage],
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
