class LanguageNormalizer {
  static final Map<String, String> _unitMap = {
    'kg': 'kg',
    'kgs': 'kg',
    'kilo': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'किलो': 'kg',
    'किलोग्रॅम': 'kg',
    'gram': 'gm',
    'grams': 'gm',
    'gm': 'gm',
    'ग्रॅम': 'gm',
    'liter': 'liter',
    'liters': 'liter',
    'litre': 'liter',
    'litres': 'liter',
    'लिटर': 'liter',
    'ml': 'ml',
    'milliliter': 'ml',
    'millilitres': 'ml',
    'मिली': 'ml',
    'packet': 'packet',
    'packets': 'packet',
    'पॅकेट': 'packet',
    'dozen': 'dozen',
    'dozens': 'dozen',
    'डझन': 'dozen',
    'piece': 'nos',
    'pieces': 'nos',
    'nos': 'nos',
    'नग': 'nos',
    'bottle': 'bottle',
    'bottles': 'bottle',
    'बाटली': 'bottle',
    'box': 'box',
    'खोका': 'box',
    'bundle': 'bundle',
    'जुडी': 'bundle',
    'पेंढी': 'bundle',
  };

  static String normalizeUnit(String input) {
    String lower = input.toLowerCase().trim();
    return _unitMap[lower] ?? lower;
  }

  static String cleanNoise(String text) {
    return text.toLowerCase()
        .replaceAll('rupees', '')
        .replaceAll('₹', '')
        .replaceAll('total', '')
        .replaceAll('equals', '')
        .replaceAll('  ', ' ')
        .trim();
  }
}
