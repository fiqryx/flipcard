import 'dart:io';
import 'dart:developer';
import 'package:flipcard/constants/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flipcard/models/voicer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class Speech with ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isReady = false;
  bool _isLoading = false;
  double _level = 0.0;
  String _words = '';
  TtsState _ttsState = TtsState.stopped;

  double get level => _level;
  String get words => _words;
  Future<List<LocaleName>> get locales => _stt.locales();

  /// speech-to-text state
  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  bool get isAvailable => _stt.isAvailable;
  bool get isListening => _stt.isListening;
  bool get isNotListening => _stt.isNotListening;

  /// text-to-speech state
  bool get isSpeaking => _ttsState == TtsState.playing;
  bool get isStopped => _ttsState == TtsState.stopped;
  bool get isPaused => _ttsState == TtsState.paused;
  bool get isContinued => _ttsState == TtsState.continued;

  Future<void> initialize() async {
    try {
      _isReady = await _stt.initialize(
        onStatus: (status) {
          _log('Speech recognition status: $status');
          notifyListeners();
        },
        onError: (error) {
          _log('Speech recognition error: $error');
          notifyListeners();
        },
      );

      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => _ttsSetState(TtsState.playing));
      _tts.setCompletionHandler(() => _ttsSetState(TtsState.stopped));
      _tts.setCancelHandler(() => _ttsSetState(TtsState.stopped));
      _tts.setPauseHandler(() => _ttsSetState(TtsState.paused));
      _tts.setContinueHandler(() => _ttsSetState(TtsState.continued));
      _tts.setErrorHandler((msg) {
        _log('Tts error: $msg');
        _ttsSetState(TtsState.stopped);
      });

      if (!kIsWeb) {
        if (Platform.isAndroid) {
          await _tts.getDefaultEngine;
          await _tts.getDefaultVoice;
        } else if (Platform.isIOS) {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.ambient,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        }
      }
    } catch (e) {
      _log('Initialize error: $e');
      _isReady = false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await stopSpeaking();
    await stopListening();
    notifyListeners();
  }

  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechListenOptions? options,
    void Function(SpeechRecognitionResult)? onResult,
  }) async {
    _words = '';
    _isLoading = true;
    notifyListeners();

    await stopSpeaking();
    await _stt.listen(
      listenOptions: options,
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      onSoundLevelChange: (level) => _level = level,
      onResult: (result) {
        _log('Listening result: ${result.recognizedWords}');
        _words = result.recognizedWords;

        if (result.finalResult) {
          _log('Listening final result: ${result.recognizedWords}');
          notifyListeners();
        }

        onResult?.call(result);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await stopSpeaking();
    await _stt.stop();
    _level = 0.0;
    notifyListeners();
  }

  Future<void> cancelListening() async {
    await _stt.cancel();
    _level = 0.0;
    notifyListeners();
  }

  Future<void> startSpeaking(
    String text, {
    double volume = 0.8,
    double rate = 0.4,
    double pitch = 1.0,
    String? language,
    Voicer? voicer,
  }) async {
    if (text.isNotEmpty) {
      await _tts.setVolume(volume);
      await _tts.setPitch(pitch);
      await _tts.setSpeechRate(rate);

      if (language != null && language.isNotEmpty) {
        await _tts.setLanguage(language);
      }

      if (voicer != null) {
        await _tts.setVoice(voicer.toJson());
      }

      await _tts.speak(text);
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _ttsSetState(TtsState.stopped);
  }

  Future<void> pauseSpeaking() async {
    await _tts.pause();
    _ttsSetState(TtsState.paused);
  }

  Future<List<Voicer>> voicers({Locale? locale}) async {
    return Voicer.toList(await _tts.getVoices, locale: locale);
  }

  /// reset main state
  void reset() {
    _words = '';
    _level = 0.0;
    _isLoading = false;
    _ttsState = TtsState.stopped;
  }

  void _ttsSetState(TtsState state) {
    _ttsState = state;
    notifyListeners();
  }

  void _log(String msg) {
    var timestamp = DateTime.now().toIso8601String();
    log('[$timestamp]: $msg', name: 'Speech');
  }
}
