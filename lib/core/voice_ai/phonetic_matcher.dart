import 'dart:math';

class PhoneticMatcher {
  static double similarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    int distance = _levenshtein(s1.toLowerCase(), s2.toLowerCase());
    int maxLen = max(s1.length, s2.length);
    return 1.0 - (distance / maxLen);
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  static String? findBestMatch(String input, List<String> candidates, {double threshold = 0.7}) {
    String? bestMatch;
    double maxSimilarity = -1.0;

    for (var candidate in candidates) {
      double sim = similarity(input, candidate);
      if (sim > maxSimilarity) {
        maxSimilarity = sim;
        bestMatch = candidate;
      }
    }

    return (maxSimilarity >= threshold) ? bestMatch : null;
  }
}
