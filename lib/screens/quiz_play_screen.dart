import 'dart:math';
import 'package:flipcard/helpers/speech.dart';
import 'package:flipcard/models/language.dart';
import 'package:flipcard/models/voicer.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/flashcard.dart';
import 'package:flipcard/services/quiz_service.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class QuizPlayScreen extends StatefulWidget {
  final Deck deck;
  final Function(int correctAnswer)? onCompleted;
  final Map<String, dynamic>? resumeState;

  const QuizPlayScreen({
    super.key,
    required this.deck,
    this.onCompleted,
    this.resumeState,
  });

  @override
  State<StatefulWidget> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Speech _speech;
  late AnimationController _flipController;
  late AnimationController _scaleController;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;

  int currentIndex = 0;
  bool isFlipped = false;
  int correctAnswers = 0;
  List<FlashCard> shuffledCards = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Add status listeners to track animation state
    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });

    _scaleController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      }
    });

    FullScreen.setFullScreen(true);
    BackButtonInterceptor.add(
      _interceptor,
      name: "Leave_interceptor",
      context: context,
    );
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    _speech = Provider.of<Speech>(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Stop any ongoing animations before disposing
    _flipController.stop();
    _scaleController.stop();

    _flipController.dispose();
    _scaleController.dispose();

    _speech.stop();
    FullScreen.setFullScreen(false);
    BackButtonInterceptor.remove(_interceptor);
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Save state when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveQuizState();
      _speech.stop();

      // Stop animations when app goes to background
      _flipController.stop();
      _scaleController.stop();
    }
  }

  Future<void> _initialize() async {
    if (widget.resumeState != null) {
      // Resume from previous state
      shuffledCards = widget.resumeState!['shuffledCards'] as List<FlashCard>;
      currentIndex = widget.resumeState!['currentIndex'] as int;
      correctAnswers = widget.resumeState!['correctAnswers'] as int;
    } else {
      // Start new quiz
      shuffledCards = widget.deck.shuffle
          ? (List.from(widget.deck.cards)..shuffle(Random()))
          : widget.deck.cards;
      currentIndex = 0;
      correctAnswers = 0;

      // Save initial state
      _saveQuizState();
    }

    // request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission denied');
      return;
    }

    // initialize speech
    if (!_speech.isReady) await _speech.initialize();
  }

  void _startListening() async {
    if (_speech.isListening || _isAnimating) return;

    await _speech.startListening(
      localeId: Language.findByLocale(
        widget.deck.backLanguage,
      ).code.replaceAll("-", "_"),
      options: SpeechListenOptions(
        sampleRate: 1.0,
        enableHapticFeedback: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (state) {
        if (state.finalResult && _speech.words.isNotEmpty) {
          _flipCard();
        }
      },
    );
  }

  void _stopListening() async {
    await _speech.stopListening();
  }

  void _flipCard() {
    // Prevent multiple simultaneous animations
    if (_isAnimating) return;

    if (_speech.isListening) {
      _stopListening();
    }

    setState(() {
      _isAnimating = true;
    });

    // Scale animation with proper completion handling
    _scaleController.forward().then((_) {
      if (mounted) {
        _scaleController.reverse();
      }
    });

    if (isFlipped) {
      _speech.reset();
      _flipController.reverse().then((_) {
        if (mounted) {
          setState(() {
            isFlipped = false;
          });
        }
      });
    } else {
      _flipController.forward().then((_) {
        if (mounted) {
          setState(() {
            isFlipped = true;
          });
        }
      });
    }
  }

  void _nextCard(bool wasCorrect) {
    // Prevent action during animation
    if (_isAnimating) return;

    _speech.reset();

    if (wasCorrect) {
      setState(() => correctAnswers++);
    }

    if (currentIndex < shuffledCards.length - 1) {
      // Reset animations properly
      _flipController.reset();
      _scaleController.reset();

      setState(() {
        currentIndex++;
        isFlipped = false;
        _isAnimating = false;
      });

      _saveQuizState();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final confetti = Confetti.launch(
      context,
      options: const ConfettiOptions(particleCount: 100, spread: 70, y: 0.6),
    );

    if (widget.onCompleted != null) {
      widget.onCompleted!(correctAnswers);
    }

    // Clear quiz state when completed normally
    QuizService.clearQuizState();

    showFSheet(
      context: context,
      side: FLayout.btt,
      builder: (context) => _QuizResultSheet(
        totalCards: shuffledCards.length,
        correctAnswers: correctAnswers,
        onRestart: _restartQuiz,
      ),
    ).then((_) {
      if (mounted) {
        confetti.kill();
        Navigator.pop(context, 'completed');
      }
    });
  }

  void _restartQuiz() {
    // Reset all animations
    _flipController.reset();
    _scaleController.reset();

    setState(() {
      currentIndex = 0;
      isFlipped = false;
      correctAnswers = 0;
      _isAnimating = false;
      shuffledCards.shuffle(Random());
    });

    // Save new quiz state
    _saveQuizState();
  }

  Future<void> _saveQuizState() async {
    try {
      await QuizService.saveQuizState(
        deckId: widget.deck.id,
        deckName: widget.deck.name,
        shuffledCards: shuffledCards,
        currentIndex: currentIndex,
        correctAnswers: correctAnswers,
      );
    } catch (e) {
      debugPrint('Error saving quiz state: $e');
    }
  }

  Future<bool> _leaveQuiz() async {
    final isLeave = await showDialog<bool>(
      context: context,
      builder: (context) => _QuizLeaveDialog(),
    );

    if (isLeave == true) {
      await QuizService.clearQuizState();
      if (mounted) Navigator.pop(context, 'leaved');
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);
    final card = shuffledCards[currentIndex];
    final progress = (currentIndex + 1) / shuffledCards.length;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        await _saveQuizState();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filled(
            onPressed: _leaveQuiz,
            icon: Icon(FIcons.arrowLeft),
          ),
          title: Text(widget.deck.name),
          centerTitle: true,
          actions: [
            IconButton(
              style: IconButton.styleFrom(shape: CircleBorder()),
              onPressed: () async {
                if (_speech.isSpeaking) {
                  await _speech.stopSpeaking();
                } else {
                  final locale = widget.deck.frontLanguage;
                  await _speech.startSpeaking(
                    shuffledCards[currentIndex].front,
                    voicer: Voicer(
                      name: '${Language.findByLocale(locale).code}-language',
                      locale: locale,
                    ),
                  );
                }
              },
              icon: Icon(
                _speech.isSpeaking ? FIcons.volumeOff : FIcons.volume2,
              ),
            ),
            Chip(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              label: Text('${currentIndex + 1}/${shuffledCards.length}'),
            ),
            SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 8,
                    color: colors.primary,
                    backgroundColor: colors.muted,
                  ),
                  SizedBox(height: 24),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _scaleAnimation,
                        _flipAnimation,
                      ]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: GestureDetector(
                            onTap: _isAnimating
                                ? null
                                : _flipCard, // Disable tap during animation
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(_flipAnimation.value * pi),
                              child: _QuizCard(
                                card: card,
                                spoken: _speech.words,
                                onFlip: () => setState(() {}),
                                isLoading: _speech.isLoading,
                                isListening: _speech.isListening,
                                isFlipped: _flipAnimation.value > 0.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 32),
                  if (isFlipped) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            onPress: _isAnimating
                                ? null
                                : () => _nextCard(false),
                            style: FButtonStyle.destructive(),
                            prefix: Icon(Icons.close),
                            child: Text('Incorrect'),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: FButton(
                            onPress: _isAnimating
                                ? null
                                : () => _nextCard(true),
                            prefix: Icon(Icons.check),
                            child: Text('Correct'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FButton(
                            onPress: (_speech.isReady && !_isAnimating)
                                ? (_speech.isListening
                                      ? _stopListening
                                      : _startListening)
                                : null,
                            style: _speech.isListening
                                ? FButtonStyle.destructive()
                                : FButtonStyle.primary(),
                            prefix: Icon(
                              _speech.isListening ? Icons.mic_off : Icons.mic,
                            ),
                            child: Text(
                              _speech.isListening
                                  ? 'Stop'
                                  : _speech.isReady
                                  ? 'Speak'
                                  : 'No Mic',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 16),
                  Text(
                    'Score: $correctAnswers correct',
                    style: themeOf.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _interceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (info.ifRouteChanged(context)) {
      Navigator.pop(context, false);
    } else {
      _leaveQuiz();
    }

    return true;
  }
}

class _QuizResultSheet extends StatelessWidget {
  final int totalCards;
  final int correctAnswers;
  final VoidCallback onRestart;

  const _QuizResultSheet({
    required this.totalCards,
    required this.correctAnswers,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);
    final percentage = (correctAnswers / totalCards * 100).round();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Quiz Complete!',
            style: themeOf.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  color: _getScoreColor(percentage),
                  backgroundColor: colors.mutedForeground,
                ),
              ),
              Column(
                children: [
                  Text(
                    '$percentage%',
                    style: themeOf.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$correctAnswers/$totalCards',
                    style: themeOf.textTheme.bodyLarge,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colors.border),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(color: colors.foreground),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onRestart();
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Restart'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

class _QuizAnswerComparison extends StatelessWidget {
  final String spoken;
  final String correct;

  const _QuizAnswerComparison({required this.spoken, required this.correct});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final similarity = _countSimilarity(spoken, correct);
    final isCorrect = similarity > 0.6;
    final correctColor = similarity >= 0.9
        ? Colors.green
        : similarity > 0.6
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(top: 24),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: correctColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: correctColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(similarity * 100).toInt()}%',
                    style: TextStyle(
                      color: colors.background,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                isCorrect ? 'Correct Match!' : 'Different Answer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Answer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.mutedForeground,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  spoken.isNotEmpty ? spoken : 'No speech detected',
                  style: TextStyle(fontSize: 14, color: colors.foreground),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.mutedForeground,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  correct,
                  style: TextStyle(fontSize: 14, color: colors.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// count similarity
  double _countSimilarity(String spoken, String correct) {
    // Remove common words and punctuation for better matching
    String cleanSpoken = spoken
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase();
    String cleanCorrect = correct
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase();

    // Direct match
    if (cleanSpoken == cleanCorrect) return 1;

    // Check if spoken answer contains the correct answer
    if (cleanSpoken.contains(cleanCorrect) ||
        cleanCorrect.contains(cleanSpoken)) {
      return 1;
    }

    // Check if spoken answer contains key words from correct answer
    List<String> correctWords = cleanCorrect
        .split(' ')
        .where((w) => w.length > 2)
        .toList();
    List<String> spokenWords = cleanSpoken.split(' ');

    if (correctWords.isEmpty) return 0;

    // Calculate similarity based on word overlap
    int matchedWords = 0;
    for (String word in correctWords) {
      if (spokenWords.any(
        (w) => w.contains(word) || word.contains(w) || _calculate(w, word) <= 2,
      )) {
        matchedWords++;
      }
    }

    return matchedWords / correctWords.length;
  }

  /// calculate levenshtein distance
  int _calculate(String s1, String s2) {
    if (s1.length < s2.length) {
      return _calculate(s2, s1);
    }

    if (s2.isEmpty) {
      return s1.length;
    }

    List<int> previousRow = List<int>.generate(s2.length + 1, (i) => i);

    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];

      for (int j = 0; j < s2.length; j++) {
        int insertions = previousRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);

        currentRow.add(
          [
            insertions,
            deletions,
            substitutions,
          ].reduce((a, b) => a < b ? a : b),
        );
      }

      previousRow = currentRow;
    }

    return previousRow.last;
  }
}

class _QuizCard extends StatelessWidget {
  final FlashCard card;
  final String spoken;
  final VoidCallback onFlip;

  /// while true is showing back of card
  final bool isFlipped;
  final bool isLoading;
  final bool isListening;

  const _QuizCard({
    required this.card,
    required this.spoken,
    required this.onFlip,
    this.isFlipped = false,
    this.isLoading = false,
    this.isListening = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: !isFlipped
                // Soft sunset orange & Coral-red orange
                ? [Color(0xFFFF8A65), Color(0xFFFF5252)]
                // Neon purple & Blue-violet
                : [Color(0xFFC56BFF), Color(0xFF8A2BE2)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(!isFlipped ? 0 : pi),
              child: Text(
                !isFlipped ? 'QUESTION' : 'ANSWER',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1,
                  color: colors.primaryForeground,
                ),
              ),
            ),
            SizedBox(height: 24),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(!isFlipped ? 0 : pi),
              child: Text(
                !isFlipped ? card.front : card.back,
                style: TextStyle(
                  color: colors.primaryForeground,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (!isFlipped) ...[
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(!isFlipped ? 0 : pi),
                child: Text(
                  card.description ?? '',
                  style: theme.typography.base.copyWith(
                    color: colors.primaryForeground,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24),
              if (isLoading) ...[
                Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.primaryForeground,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing: "$spoken"',
                      style: TextStyle(
                        color: colors.primaryForeground,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ] else if (isListening) ...[
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      onEnd: onFlip,
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: Duration(milliseconds: 800),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            Icons.mic,
                            color: colors.primaryForeground,
                            size: 32,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Listening...',
                      style: TextStyle(
                        color: colors.primaryForeground,
                        fontSize: 14,
                      ),
                    ),
                    if (spoken.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        spoken,
                        style: TextStyle(
                          color: colors.primaryForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ] else ...[
                Text(
                  'Tap to reveal answer or speak your answer',
                  style: TextStyle(
                    color: colors.primaryForeground,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            // Show answer comparison when card is flipped after speech
            if (isFlipped && spoken.isNotEmpty) ...[
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(pi),
                child: _QuizAnswerComparison(
                  spoken: spoken,
                  correct: card.back,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuizLeaveDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Leave Quiz?'),
      content: Text('Your progress will be lost. Are you sure?'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.theme.colors.border),
      ),
      actions: [
        FButton(
          mainAxisSize: MainAxisSize.min,
          style: FButtonStyle.outline(),
          onPress: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        FButton(
          mainAxisSize: MainAxisSize.min,
          onPress: () => Navigator.pop(context, true),
          child: Text('Leave'),
        ),
      ],
    );
  }
}
