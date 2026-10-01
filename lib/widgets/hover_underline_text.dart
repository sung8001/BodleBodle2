//호버 밑줄 텍스트
import 'package:flutter/material.dart';

class HoverUnderlineText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;

  const HoverUnderlineText({
    super.key,
    required this.text,
    required this.style,
    required this.onTap,
  });

  @override
  State<HoverUnderlineText> createState() => _HoverUnderlineTextState();
}

class _HoverUnderlineTextState extends State<HoverUnderlineText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: widget.style.copyWith(
            decoration: _isHovered
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
