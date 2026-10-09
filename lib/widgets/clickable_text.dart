import 'package:flutter/material.dart';

/// 모바일 터치 피드백(리플 효과)이 적용된 클릭 가능한 텍스트 위젯
class ClickableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final VoidCallback onTap;

  const ClickableText({
    super.key,
    required this.text,
    this.style,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        splashColor: Colors.black.withValues(alpha: 0.1),
        highlightColor: Colors.black.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            text,
            style: (style ?? const TextStyle()).copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
