import 'dart:math';

class DictResolveResult {
  final String canonicalName;
  final int confidence;
  final bool isUnknown;

  DictResolveResult({
    required this.canonicalName,
    required this.confidence,
    required this.isUnknown,
  });
}

class KiranaDictionaryResolver {
  // Map canonical display name -> list of lower-case aliases/variants
  static final Map<String, List<String>> _dictionary = {
    'Toor Dal': ['toor dal', 'toor', 'tur dal', 'tur', 'toordal', 'turdal', 'तूर', 'तुरी', 'तूर डाळ'],
    'Moong Dal': ['moong dal', 'moong', 'mug', 'mung', 'mung dal', 'mungdal', 'मूग', 'मूग डाळ'],
    'Chana Dal': ['chana dal', 'chana', 'harbhara', 'चना', 'चना दाल'],
    'Udid Dal': ['udid dal', 'udid', 'urad', 'urad dal', 'उडीद', 'उडीद डाळ'],
    'Akhha Masoor': ['akhha masoor', 'masoor dal', 'masoor', 'masur', 'मसूर'],
    'Matki Dal': ['matki dal', 'matki', 'मटकी'],
    'Chawali': ['chawali', 'chawli', 'chawla', 'चवळी'],
    'Green Vatana': ['green vatana', 'vatana', 'vatane', 'वटाणा', 'हिरवा वटाणा'],
    'Chhole': ['chhole', 'chole', 'kabuli chana', 'छोले'],
    'Rajma': ['rajma', 'राजमा'],
    
    'Sakhar': ['sakhar', 'sugar', 'shakkar', 'साखर', 'शक्कर'],
    'Salt': ['salt', 'meeth', 'mith', 'namak', 'मीठ', 'नमक'],
    'Rice / Chawal': ['rice', 'chawal', 'tandul', 'kolam', 'basmati', 'indrayani', 'kolam rice', 'तांदूळ', 'चावल'],
    'Wheat / Gahu': ['wheat', 'gahu', 'gehu', 'गहू', 'गेहू'],
    'Atta': ['atta', 'aata', 'flour', 'आटा'],
    'Rava': ['rava', 'rawa', 'ravva', 'रवा'],
    'Maida': ['maida', 'मैदा'],
    'Besan': ['besan', 'बेसन'],
    'Pohe': ['pohe', 'poha', 'पोहे'],
    'Shabudana': ['shabudana', 'sabudana', 'साबुदाणा'],
    'Jaggery': ['jaggery', 'gud', 'gul', 'गुळ', 'गूढ'],

    'Jeera': ['jeera', 'jira', 'जीरे', 'जीरा'],
    'Mohri': ['mohri', 'rai', ' सरसों', 'मोहरी'],
    'Jeera Mohri': ['jeera mohri', 'jira mohri'],
    'Turmeric / Haldi': ['haldi', 'halad', 'हळद', 'हल्दी'],
    'Red Chili Powder': ['mirchi pud', 'mirchi powder', 'tikhat', 'तिखट', 'मिर्च'],
    'Sabzi Masala': ['sabzi masala', 'garam masala', 'masala', 'मसाला'],
    'Chaha Pud': ['chaha pud', 'tea powder', 'chai patti', 'tea', 'चहा'],
    'Coffee': ['coffee', 'कॉफी'],

    'Marie Biscuit': ['marie biscuit', 'marie'],
    'Parle-G': ['parle', 'parle g', 'पार्ले'],
    'Bourbon': ['burbon', 'bourbon', 'बर्बन'],
    'Farsan': ['farsan', 'namkeen', 'फरसाण'],
    'Shengdana': ['shengdana', 'singdana', 'peanut', 'peanuts', 'शेंगदाणा'],
    'Sukha Khobra': ['sukha khobra', 'khobra', 'dry coconut', 'खोबरे'],

    'Bartan Saban': ['bartan saban', 'dish soap', 'saban', 'sabun', 'vim', 'साबण', 'साबुन'],
    'Washing Powder': ['washing powder', 'surf', 'detergent', 'निरमा'],
    'Kadepeti': ['matchbox', 'kadepeti', 'काडेपेटी'],
  };

  final Map<String, DictResolveResult> _cache = {};

  DictResolveResult resolve(String rawItemName) {
    final cleaned = rawItemName.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return DictResolveResult(canonicalName: 'Unknown', confidence: 0, isUnknown: true);
    }

    if (_cache.containsKey(cleaned)) {
      return _cache[cleaned]!;
    }

    // 1. Direct Alias Match
    for (var entry in _dictionary.entries) {
      for (var alias in entry.value) {
        if (alias == cleaned) {
          final res = DictResolveResult(canonicalName: entry.key, confidence: 98, isUnknown: false);
          _cache[cleaned] = res;
          return res;
        }
      }
    }

    // 2. Partial Contains Match
    for (var entry in _dictionary.entries) {
      for (var alias in entry.value) {
        if (cleaned.contains(alias) || alias.contains(cleaned)) {
          if (cleaned.length >= 3 && alias.length >= 3) {
            final res = DictResolveResult(canonicalName: entry.key, confidence: 85, isUnknown: false);
            _cache[cleaned] = res;
            return res;
          }
        }
      }
    }

    // 3. Fuzzy Match (Levenshtein Distance)
    String? bestCanonical;
    int minDistance = 999;

    for (var entry in _dictionary.entries) {
      for (var alias in entry.value) {
        int dist = _levenshteinDistance(cleaned, alias);
        if (dist < minDistance) {
          minDistance = dist;
          bestCanonical = entry.key;
        }
      }
    }

    if (bestCanonical != null && minDistance <= 2 && cleaned.length >= 4) {
      final res = DictResolveResult(canonicalName: bestCanonical, confidence: 78, isUnknown: false);
      _cache[cleaned] = res;
      return res;
    }

    // 4. Unknown fallback (capitalize title words)
    String fallbackTitle = _capitalizeWords(rawItemName);
    final res = DictResolveResult(canonicalName: fallbackTitle, confidence: 55, isUnknown: true);
    _cache[cleaned] = res;
    return res;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= s2.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  String _capitalizeWords(String input) {
    return input.split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }
}
