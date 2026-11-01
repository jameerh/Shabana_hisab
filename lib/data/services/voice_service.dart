import 'dart:async';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  static const _platform = MethodChannel('com.example.snaphisaab/voice');

  // Keep the exact same stream structure so home_view.dart doesn't break
  final StreamController<String> _textStream = StreamController<String>.broadcast();
  Stream<String> get onTextResult => _textStream.stream;

  bool _isListening = false;
  bool get isListening => _isListening;
  bool _isInitialized = false;
  bool _disposed = false;
  bool get isDisposed => _disposed;

  /// Safe stream emission helper guarding against 'Bad state: Cannot add event after closing'
  void _emit(String event) {
    if (!_disposed && !_textStream.isClosed) {
      _textStream.add(event);
    }
  }

  // ==============================
  // 🚀 INIT MODEL (Google Speech)
  // ==============================
  Future<void> initializeModel() async {
    if (_disposed || _isInitialized) return;
    
    try {
      _emit("STATUS:Init Step 1...");
      
      // Strict timeout for initialization - increased to 8s
      final result = await _speechToText.initialize(
        onError: (val) {
          _emit("ERROR: ${val.errorMsg}");
        },
        onStatus: (val) {
          _emit("STATUS:$val");
        },
        debugLogging: true,
      ).timeout(const Duration(seconds: 8), onTimeout: () {
        _emit("ERROR: Speech init timed out");
        return false;
      });

      if (_disposed) return;
      _isInitialized = result;

      if (!_isInitialized) {
        _emit("ERROR: Engine Denied");
      } else {
        _emit("STATUS:Engine Ready");
      }
    } catch (e) {
      _emit("ERROR: Init Crash - $e");
    }
  }

  // ==============================
  // 🎤 START LISTENING
  // ==============================
  Future<void> startListening({String? preferredLocaleId}) async {
    if (_disposed) return;

    try {
      if (!_isInitialized) {
        await initializeModel();
      }

      if (_disposed) return;

      if (!_isInitialized) {
        _emit("ERROR: Speech engine unavailable.");
        return;
      }

      _isListening = true;
      _emit("STATUS:Mic Starting...");

      // Validate locale availability
      List<LocaleName> locales = [];
      try {
        locales = await _speechToText.locales().timeout(const Duration(seconds: 3));
      } catch (_) {}

      if (_disposed) return;

      String? selectedLocale;

      // 1. If preferredLocaleId is provided, try to find it exactly
      if (preferredLocaleId != null) {
        for (var l in locales) {
          if (l.localeId == preferredLocaleId) {
            selectedLocale = l.localeId;
            break;
          }
        }
      }

      // 2. Strict Marathi check if no preferred or preferred not found
      if (selectedLocale == null) {
        for (var l in locales) {
          String id = l.localeId.replaceAll('_', '-').toLowerCase();
          if (id == 'mr-in' || id == 'mr_in') {
            selectedLocale = l.localeId;
            break;
          }
        }
      }

      // 3. Fallback to Hindi
      if (selectedLocale == null) {
        for (var l in locales) {
          String id = l.localeId.replaceAll('_', '-').toLowerCase();
          if (id == 'hi-in' || id == 'hi_in') {
            selectedLocale = l.localeId;
            break;
          }
        }
      }

      selectedLocale ??= 'mr_IN'; // Hard fallback if nothing found
      
      _emit("STATUS: Listening ($selectedLocale)");

      await _speechToText.listen(
        onResult: (result) {
          if (_disposed) return;
          final words = result.recognizedWords;
          final isFinal = result.finalResult;

          if (words.isNotEmpty) {
            // Log raw transcript for architecture debugging
            _emit("RAW:$words");
            _emit("PARTIAL:$words");
            
            if (isFinal) {
              _emit(words);
            }
          } else if (isFinal) {
            _emit("ERROR: empty_final_result");
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4), 
        localeId: selectedLocale,
        onDevice: false, 
        listenOptions: SpeechListenOptions(
          cancelOnError: false, 
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );

    } catch (e) {
      print("VOICE CRASH: $e");
      _emit("ERROR: Start listening failed - $e");
      _isListening = false;
    }
  }

  // ==================================
  // 💎 NATIVE GOOGLE VOICE (Intent)
  // ==================================
  Future<String?> startNativeGoogleVoice({String language = 'mr-IN', bool addToStream = true}) async {
    if (_disposed) return null;

    try {
      _isListening = true;
      _emit("STATUS:Launching Google Voice ($language)...");
      
      final String? result = await _platform.invokeMethod('startVoiceRecognition', {
        'language': language,
      });
      
      if (_disposed) return result;

      _isListening = false;
      if (result != null && result.isNotEmpty) {
        if (addToStream) _emit(result);
        return result;
      } else {
        _emit("STATUS:notListening");
        return null;
      }
    } on PlatformException catch (e) {
      _isListening = false;
      if (e.code == "CANCELED") {
        _emit("STATUS:notListening");
      } else {
        _emit("ERROR: Native error - ${e.message}");
      }
      return null;
    } catch (e) {
      _isListening = false;
      _emit("ERROR: $e");
      return null;
    }
  }

  // ==============================
  // 🛑 STOP LISTENING
  // ==============================
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    _isListening = false;
    _emit("STATUS:notListening");
  }

  // ==============================
  // 🧹 DISPOSE
  // ==============================
  void dispose() {
    _disposed = true;
    _isListening = false;
    try {
      _speechToText.cancel();
    } catch (_) {}
    if (!_textStream.isClosed) {
      _textStream.close();
    }
  }
}