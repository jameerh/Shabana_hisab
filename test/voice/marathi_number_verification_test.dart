import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/domain/parser/snap_parser.dart';

void main() {
  final parser = SnapParser();

  test('Comprehensive Marathi Number Verification Suite (1 to 100, Hundreds, Thousands, Lakhs)', () {
    final testCases = <String, double>{
      // 1-10
      'एक खर्च': 1,
      'पाच खर्च': 5,
      'दहा खर्च': 10,

      // 11-20
      'अकरा खर्च': 11,
      'पंधरा खर्च': 15,
      'वीस खर्च': 20,

      // 21-50
      'पंचवीस खर्च': 25,
      'तीस खर्च': 30,
      'पस्तीस खर्च': 35,
      'चाळीस खर्च': 40,
      'पन्नास खर्च': 50,

      // 51-100
      'साठ खर्च': 60,
      'सत्तर खर्च': 70,
      'ऐंशी खर्च': 80,
      'नव्वद खर्च': 90,
      'शंभर खर्च': 100,

      // Compound Hundreds (User reported issue)
      'तेराशे पन्नास खर्च': 1350,
      'बाराशे पन्नास खर्च': 1250,
      'एक हजार पन्नास खर्च': 1050,
      'दोन हजार पन्नास खर्च': 2050,
      'पाच हजार दोनशे पन्नास खर्च': 5250,
      'अकराशे वीस खर्च': 1120,
      'चौदाशे तीस खर्च': 1430,
      'पंधराशे साठ खर्च': 1560,
      'सोळाशे सत्तर खर्च': 1670,
      'सतराशे ऐंशी खर्च': 1780,
      'अठराशे नव्वद खर्च': 1890,
      'एकोणीसशे पंचावन्न खर्च': 1955,

      // Colloquial / Fractional Marathi
      'सव्वाशे खर्च': 125,
      'दीडशे खर्च': 150,
      'अडीचशे खर्च': 250,
      'साडेतीनशे खर्च': 350,
      'साडेचारशे खर्च': 450,
      'साडेपाचशे खर्च': 550,

      // STT Hybrids & Digits (Google STT inputs)
      '13शे 50 खर्च': 1350,
      '12शे 50 खर्च': 1250,
      '13 शे 50 खर्च': 1350,
      '12 शे 50 खर्च': 1250,
      '1300 पन्नास खर्च': 1350,
      '1200 पन्नास खर्च': 1250,
      '1000 पन्नास खर्च': 1050,
      '१३शे ५० खर्च': 1350,
      '१२शे ५० खर्च': 1250,
      '1050 खर्च': 1050,
      '1350 खर्च': 1350,
    };

    for (final entry in testCases.entries) {
      final res = parser.parse(entry.key, profileType: 'PERSONAL', profileId: 1);
      expect(res?.amount, equals(entry.value), reason: "Failed for: '${entry.key}'");
    }
  });
}
