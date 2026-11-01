import 'package:flutter/material.dart';
import 'app_language.dart';
import 'language_controller.dart';

class BilingualText extends StatelessWidget {
  final String english;
  final String marathi;
  final TextStyle? style;
  final TextStyle? secondaryStyle;
  final TextAlign? textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final int? maxLines;
  final TextOverflow overflow;
  final LanguageController? languageController;

  const BilingualText({
    super.key,
    required this.english,
    required this.marathi,
    this.style,
    this.secondaryStyle,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.languageController,
  });

  @override
  Widget build(BuildContext context) {
    // If languageController is provided, use it; otherwise check active InheritedWidget or mode
    final mode = languageController?.currentLanguage ?? AppLanguage.english;

    if (mode == AppLanguage.marathi) {
      return Text(
        marathi,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    if (mode == AppLanguage.englishMarathi) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            english,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
          const SizedBox(height: 2),
          Text(
            marathi,
            style: secondaryStyle ??
                (style != null
                    ? style!.copyWith(
                        fontSize: (style!.fontSize ?? 14.0) * 0.85,
                        color: (style!.color ?? Colors.black).withOpacity(0.7),
                        fontWeight: FontWeight.normal,
                      )
                    : TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade600,
                      )),
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ],
      );
    }

    // Default: English mode
    return Text(
      english,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
