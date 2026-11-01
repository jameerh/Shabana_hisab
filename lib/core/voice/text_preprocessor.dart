class TextPreprocessor {
  // Pre-compiled regular expressions for performance
  static final RegExp _whatsappTimestampHeader = RegExp(
    r'^\s*\[\s*\d{1,2}:\d{2}(?::\d{2})?(?:\s*[APap][Mm])?(?:,\s*[\d/\.\-]+)?\s*\]\s*(?:[^:\n]+:\s*)?',
    caseSensitive: false,
  );

  static final RegExp _senderHeaderOnly = RegExp(
    r'^\s*[\w\u0900-\u097F\s]{2,20}:\s*',
  );

  static final RegExp _bulletsAndNumbers = RegExp(
    r'^\s*(?:[\-\*\•\>\▪\▫\✓\✔\☑\✅\👉\➡\⭐\🛒\📦\🛍️]|\(?\d{1,3}\)?[\.\)\:]|[A-Za-z]\))\s*',
  );

  static final RegExp _systemNoiseLines = RegExp(
    r'^\s*(?:forwarded(?:\s+many\s+times)?|<media\s+omitted>|this\s+message\s+was\s+deleted|you\s+deleted\s+this\s+message|yesterday|today|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s*$',
    caseSensitive: false,
  );

  static final RegExp _emojis = RegExp(
    r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]',
    unicode: true,
  );

  List<String> processText(String rawInput) {
    if (rawInput.trim().isEmpty) return [];

    final lines = rawInput.split(RegExp(r'\r?\n'));
    List<String> cleanedLines = [];

    for (var line in lines) {
      String cleaned = line.trim();
      if (cleaned.isEmpty) continue;

      // 1. Remove WhatsApp system noise lines
      if (_systemNoiseLines.hasMatch(cleaned)) continue;

      // 2. Remove WhatsApp timestamp headers e.g. [12:32, 28/7/2026] Wifey:
      cleaned = cleaned.replaceAll(_whatsappTimestampHeader, '');

      // 3. Remove standalone sender headers e.g. Wifey:
      if (cleaned.contains(':')) {
        cleaned = cleaned.replaceAll(_senderHeaderOnly, '');
      }

      // 4. Remove emojis
      cleaned = cleaned.replaceAll(_emojis, '');

      // 5. Remove bullet points and numbered list markers
      cleaned = cleaned.replaceAll(_bulletsAndNumbers, '');

      // 6. Clean OCR spaced letters e.g. "S u g a r 2 k g" -> "Sugar 2 kg"
      cleaned = _normalizeOcrSpacing(cleaned);

      // 7. Collapse multiple spaces
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned.isNotEmpty && !_systemNoiseLines.hasMatch(cleaned)) {
        cleanedLines.add(cleaned);
      }
    }

    return cleanedLines;
  }

  String _normalizeOcrSpacing(String text) {
    // Replaces sequences of single letters separated by space e.g. "S u g a r" -> "Sugar", "k g" -> "kg"
    return text.replaceAllMapped(
      RegExp(r'\b([a-zA-Z])(?:\s+([a-zA-Z]))+\b'),
      (match) => match.group(0)!.replaceAll(' ', ''),
    );
  }
}
