import 'package:flutter/material.dart';

class BarcodeWidget extends StatelessWidget {
  final String code;
  final double height;
  final double width;
  final bool showText;
  final TextStyle? textStyle;

  const BarcodeWidget({
    super.key,
    required this.code,
    this.height = 38,
    this.width = 180,
    this.showText = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width,
          child: CustomPaint(
            painter: _Code128Painter(code),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 3),
          Text(
            '*$code*',
            style: textStyle ??
                const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: Color(0xFF0F172A),
                ),
          ),
        ],
      ],
    );
  }
}

class _Code128Painter extends CustomPainter {
  final String code;

  _Code128Painter(this.code);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Deterministic bar pattern derived from characters
    final bytes = code.codeUnits;
    final List<int> pattern = [];

    // Quiet zone / guard pattern
    pattern.addAll([2, 1, 1, 2]);

    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      pattern.add((b % 3) + 1);
      pattern.add(((b ~/ 3) % 2) + 1);
      pattern.add(((b ~/ 5) % 3) + 1);
      pattern.add(1);
    }

    // Stop pattern
    pattern.addAll([2, 3, 1, 2, 1]);

    final totalUnits = pattern.reduce((a, b) => a + b);
    final unitWidth = size.width / totalUnits;

    double currentX = 0;
    bool isBar = true;

    for (final barWidth in pattern) {
      final w = barWidth * unitWidth;
      if (isBar) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, w, size.height), paint);
      }
      currentX += w;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(covariant _Code128Painter oldDelegate) => oldDelegate.code != code;
}
