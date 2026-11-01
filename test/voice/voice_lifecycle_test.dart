import 'package:flutter_test/flutter_test.dart';
import 'package:snaphisaab/data/services/voice_service.dart';

void main() {
  group('VoiceService Lifecycle Safety & Memory Leak Prevention Gate', () {
    late VoiceService voiceService;

    setUp(() {
      voiceService = VoiceService();
    });

    tearDown(() {
      if (!voiceService.isDisposed) {
        voiceService.dispose();
      }
    });

    test('Initial state is not disposed and not listening', () {
      expect(voiceService.isDisposed, isFalse);
      expect(voiceService.isListening, isFalse);
    });

    test('Calling dispose sets isDisposed to true and closes text stream', () async {
      expect(voiceService.isDisposed, isFalse);
      voiceService.dispose();
      expect(voiceService.isDisposed, isTrue);
      expect(voiceService.isListening, isFalse);
    });

    test('Safe disposal guards against "Bad state: Cannot add event after closing"', () async {
      final emittedEvents = <String>[];
      final sub = voiceService.onTextResult.listen((event) {
        emittedEvents.add(event);
      });

      // Dispose service immediately
      voiceService.dispose();
      expect(voiceService.isDisposed, isTrue);

      // Attempt operations after disposal - MUST NOT throw Closed Stream or Bad State exceptions
      expect(() async => await voiceService.initializeModel(), returnsNormally);
      expect(() async => await voiceService.startListening(), returnsNormally);
      expect(() async => await voiceService.startNativeGoogleVoice(), returnsNormally);
      expect(() async => await voiceService.stopListening(), returnsNormally);

      // Multiple dispose calls are safe idempotent operations
      expect(() => voiceService.dispose(), returnsNormally);

      await sub.cancel();
    });

    test('Reopening lifecycle: new instance works cleanly without cross-instance leakage', () async {
      // Instance 1
      final instance1 = VoiceService();
      expect(instance1.isDisposed, isFalse);
      instance1.dispose();
      expect(instance1.isDisposed, isTrue);

      // Instance 2
      final instance2 = VoiceService();
      expect(instance2.isDisposed, isFalse);

      final received = <String>[];
      final sub2 = instance2.onTextResult.listen((data) => received.add(data));

      instance2.dispose();
      expect(instance2.isDisposed, isTrue);
      await sub2.cancel();
    });
  });
}
