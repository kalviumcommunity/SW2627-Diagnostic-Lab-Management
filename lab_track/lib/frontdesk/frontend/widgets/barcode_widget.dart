import 'package:flutter/material.dart';

/// Displays the identifier as text until a validated barcode encoder is added.
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
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            'ID: $code',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textStyle ?? const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      );
}
