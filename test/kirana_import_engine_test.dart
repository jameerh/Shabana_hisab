import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/core/voice/kirana_import_engine.dart';
import 'package:snaphisaab/core/voice/text_preprocessor.dart';
import 'package:snaphisaab/core/voice/kirana_quantity_unit_parser.dart';
import 'package:snaphisaab/core/voice/kirana_dictionary_resolver.dart';
import 'package:snaphisaab/core/voice/kirana_category_engine.dart';

void main() {
  group('Kirana Import Engine - Enterprise Test Suite', () {
    late KiranaRegexImportEngine engine;
    late TextPreprocessor preprocessor;

    setUp(() {
      preprocessor = TextPreprocessor();
      engine = KiranaRegexImportEngine(preprocessor: preprocessor);
    });

    test('1. WhatsApp User Sample Multi-line Text Copy-Paste Parsing', () {
      const whatsappSample = '''
[12:32, 28/7/2026] Wifey: Toor dal 1 kg
[12:33, 28/7/2026] Wifey: Parle 1 duzzan
[12:33, 28/7/2026] Wifey: Marie biscuit  6 unit
[12:33, 28/7/2026] Wifey: Matki dal 1 kilo
[12:33, 28/7/2026] Wifey: Moong dal 1 kilo
[12:33, 28/7/2026] Wifey: Sakhar 5 kilo
[12:34, 28/7/2026] Wifey: Apple goldChawal 5  kilo
[12:34, 28/7/2026] Wifey: Kolam rice 2 kilo
[12:34, 28/7/2026] Wifey: Shengdana 1 kilo
[12:35, 28/7/2026] Wifey: Chawali 1 kilo
[12:35, 28/7/2026] Wifey: Green vatana 1kilo
[12:35, 28/7/2026] Wifey: Sukha khobra pavsher
[12:35, 28/7/2026] Wifey: Chhole1 kilo
[12:36, 28/7/2026] Wifey: Akhha masoor 1/2 kilo
[12:36, 28/7/2026] Wifey: Rava 1 kilo
[12:36, 28/7/2026] Wifey: Shabudana 1 kilo
[12:36, 28/7/2026] Wifey: Salt 2 kilo
[12:37, 28/7/2026] Wifey: Jeera mohri pav kilo
[12:37, 28/7/2026] Wifey: Udid dal 1 kilo
[12:38, 28/7/2026] Wifey: Besan 1 /2 kilo
[12:39, 28/7/2026] Wifey: Chaha pud 2 packet
[12:40, 28/7/2026] Wifey: Sabzi masala 1 packet
[12:41, 28/7/2026] Wifey: Pohe 1 kilo
[12:41, 28/7/2026] Wifey: Bartan saban 3 packet
[12:43, 28/7/2026] Wifey: Farsan 1 packit
[12:43, 28/7/2026] Wifey: Burbon 6 packet
''';

      final items = engine.parse(whatsappSample);

      // 26 raw lines -> 25 items because "Apple goldChawal 5 kilo" and "Kolam rice 2 kilo"
      // resolve to canonical "Rice / Chawal" and auto-merge into 7.0 kilo!
      expect(items.length, 25);

      final rice = items.firstWhere((i) => i.canonicalName == 'Rice / Chawal');
      expect(rice.quantity, 7.0);
      expect(rice.unit, 'kilo');

      // Verify specific items
      final toor = items.firstWhere((i) => i.canonicalName == 'Toor Dal');
      expect(toor.quantity, 1.0);
      expect(toor.unit, 'kilo');

      final parle = items.firstWhere((i) => i.canonicalName == 'Parle-G');
      expect(parle.quantity, 1.0);
      expect(parle.unit, 'dozen');

      final khobra = items.firstWhere((i) => i.canonicalName == 'Sukha Khobra');
      expect(khobra.quantity, 0.25);
      expect(khobra.unit, 'kilo');

      final chhole = items.firstWhere((i) => i.canonicalName == 'Chhole');
      expect(chhole.quantity, 1.0);
      expect(chhole.unit, 'kilo');

      final masoor = items.firstWhere((i) => i.canonicalName == 'Akhha Masoor');
      expect(masoor.quantity, 0.5);
      expect(masoor.unit, 'kilo');

      final besan = items.firstWhere((i) => i.canonicalName == 'Besan');
      expect(besan.quantity, 0.5);
      expect(besan.unit, 'kilo');

      final farsan = items.firstWhere((i) => i.canonicalName == 'Farsan');
      expect(farsan.quantity, 1.0);
      expect(farsan.unit, 'packet');
    });

    test('2. Aggressive WhatsApp Metadata & System Message Removal', () {
      const noisyText = '''
Forwarded
Forwarded many times
[10:32 AM, 01/08/2026] Mom: Sakhar 5 kilo
<Media omitted>
This message was deleted
You deleted this message
Yesterday
Rahul: Toor Dal 2kg
''';

      final cleaned = preprocessor.processText(noisyText);
      expect(cleaned.length, 2);
      expect(cleaned[0], 'Sakhar 5 kilo');
      expect(cleaned[1], 'Toor Dal 2kg');
    });

    test('3. Emojis and List Markers Removal', () {
      const input = '''
• Sugar 2kg
1. 🛒 Toor Dal 1 kg
- 👉 Rice 5 kilo
(1) 🥔 Batata 2kg
✅ Milk 1 liter
''';

      final cleaned = preprocessor.processText(input);
      expect(cleaned[0], 'Sugar 2kg');
      expect(cleaned[1], 'Toor Dal 1 kg');
      expect(cleaned[2], 'Rice 5 kilo');
      expect(cleaned[3], 'Batata 2kg');
      expect(cleaned[4], 'Milk 1 liter');
    });

    test('4. ASCII & Unicode Fraction Parsing', () {
      final parser = KiranaQuantityUnitParser();

      expect(parser.parseLine('Sugar 1/2 kg').quantity, 0.5);
      expect(parser.parseLine('Sugar 1 /2 kg').quantity, 0.5);
      expect(parser.parseLine('Sugar ½ kg').quantity, 0.5);
      expect(parser.parseLine('Sugar 1½ kg').quantity, 1.5);
      expect(parser.parseLine('Sugar 2½ kg').quantity, 2.5);
      expect(parser.parseLine('Sugar ¾ kg').quantity, 0.75);
    });

    test('5. Marathi Spoken Numbers & Quantities', () {
      final parser = KiranaQuantityUnitParser();

      expect(parser.parseLine('Sakhar अर्धा किलो').quantity, 0.5);
      expect(parser.parseLine('Sakhar पाव किलो').quantity, 0.25);
      expect(parser.parseLine('Sakhar दीड किलो').quantity, 1.5);
      expect(parser.parseLine('Sakhar सव्वा किलो').quantity, 1.25);
      expect(parser.parseLine('Sakhar अडीच किलो').quantity, 2.5);
      expect(parser.parseLine('Sakhar साडेतीन किलो').quantity, 3.5);
      expect(parser.parseLine('Sakhar पाच किलो').quantity, 5.0);
    });

    test('6. Formatting Variations (x2, Sugar-2, .5kg, 250gm)', () {
      final parser = KiranaQuantityUnitParser();

      expect(parser.parseLine('Sugar-2').quantity, 2.0);
      expect(parser.parseLine('Sugar x2').quantity, 2.0);
      expect(parser.parseLine('Sugar 2x').quantity, 2.0);
      expect(parser.parseLine('Sugar .5kg').quantity, 0.5);
      expect(parser.parseLine('Sugar 250gm').quantity, 250.0);
      expect(parser.parseLine('Sugar 250gm').unit, 'gm');
    });

    test('7. Dictionary Resolver Fuzzy Matching', () {
      final resolver = KiranaDictionaryResolver();

      expect(resolver.resolve('toor').canonicalName, 'Toor Dal');
      expect(resolver.resolve('tur').canonicalName, 'Toor Dal');
      expect(resolver.resolve('toordal').canonicalName, 'Toor Dal');
      expect(resolver.resolve('turdal').canonicalName, 'Toor Dal');
      expect(resolver.resolve('तूर').canonicalName, 'Toor Dal');
      expect(resolver.resolve('तुरी').canonicalName, 'Toor Dal');
    });

    test('8. Category Engine Detection & Fallback', () {
      final categoryEngine = KiranaCategoryEngine();

      expect(categoryEngine.detectCategory('Toor Dal', 'Toor dal'), 'Grains & Pulses');
      expect(categoryEngine.detectCategory('Bartan Saban', 'dish soap'), 'Household');
      expect(categoryEngine.detectCategory('Marie Biscuit', 'biscuit'), 'Snacks & Beverages');
      expect(categoryEngine.detectCategory('Sabzi Masala', 'masala'), 'Spices & Staples');
    });

    test('9. Intra-List Duplicate Auto-Merging', () {
      const input = '''
Sugar 2kg
Toor Dal 1kg
Sugar 1kg
''';

      final items = engine.parse(input);

      expect(items.length, 2);
      final sugar = items.firstWhere((i) => i.canonicalName == 'Sakhar');
      expect(sugar.quantity, 3.0);
      expect(sugar.isDuplicate, true);
    });

    test('10. OCR Spacing Error Cleanup', () {
      const ocrInput = 'S u g a r 2 k g';
      final cleaned = preprocessor.processText(ocrInput);
      expect(cleaned[0], 'Sugar 2 kg');
    });

    test('11. Performance Benchmark - 1000 Lines Stress Test', () {
      final buffer = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        buffer.writeln('[12:32, 28/7/2026] Wifey: Toor dal ${i + 1} kg');
      }

      final stopwatch = Stopwatch()..start();
      final items = engine.parse(buffer.toString());
      stopwatch.stop();

      expect(items.isNotEmpty, true);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Must parse under 500ms
    });
  });
}
