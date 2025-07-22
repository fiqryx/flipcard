import 'package:flipcard/helpers/logger.dart';
import 'package:flipcard/models/quiz_result.dart';
import 'package:flipcard/screens/quiz_play_screen.dart';
import 'package:flipcard/services/quiz_result_service.dart';
import 'package:flipcard/services/user_service.dart';
import 'package:flipcard/widgets/app_bar.dart';
import 'package:flipcard/widgets/badge.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreen();
}

class _QuizScreen extends State<QuizScreen> {
  late UserStore _userStore;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPreviousQuiz();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  Future<void> _checkForPreviousQuiz() async {
    final hasState = await QuizService.hasQuizState();
    if (hasState && mounted) {
      _showContinueQuizDialog();
    }
  }

  Future<void> _showContinueQuizDialog() async {
    final quizState = await QuizService.getQuizState();
    if (quizState == null || !mounted) return;

    final deckName = quizState['deckName'] as String? ?? 'Unknown Deck';
    final currentIndex = quizState['currentIndex'] as int? ?? 0;
    final shuffledCardsData = quizState['shuffledCards'] as List? ?? [];
    final totalCards = shuffledCardsData.length;

    showFDialog(
      context: context,
      barrierDismissible: false,
      builder: (context, style, animation) => _QuizContinueDialog(
        name: deckName,
        style: style,
        animation: animation,
        progress: '${currentIndex + 1}/$totalCards',
        onContinue: () async => await _continuePreviousQuiz(quizState),
      ),
    );
  }

  Future<void> _continuePreviousQuiz(Map<String, dynamic> quizState) async {
    try {
      final deckId = quizState['deckId'] as String? ?? '';
      final shuffledCardsData = quizState['shuffledCards'] as List? ?? [];
      final shuffledCards = QuizService.parseFlashCards(shuffledCardsData);
      final currentIndex = quizState['currentIndex'] as int? ?? 0;
      final correctAnswers = quizState['correctAnswers'] as int? ?? 0;
      final deckName = quizState['deckName'] as String? ?? 'Unknown Deck';

      // Find the deck to get the full deck object
      final deck = _userStore.decks.firstWhere(
        (d) => d.id == deckId,
        orElse: () => Deck(id: deckId, name: deckName, cards: shuffledCards),
      );

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPlayScreen(
            deck: deck,
            onCompleted: (correct) => _quizCompleted(
              deckId: deckId,
              correctAnswers: correct,
              incorrectAnswers: deck.cards.length - correct,
              timeSpentSeconds: 0,
            ),
            resumeState: {
              'shuffledCards': shuffledCards,
              'currentIndex': currentIndex,
              'correctAnswers': correctAnswers,
            },
          ),
        ),
      );

      // Check if we returned from quiz without completing
      // If so, check if there's still a saved state
      if (result != 'completed') {
        _checkForPreviousQuiz();
      }
    } catch (e) {
      // If there's an error, clear the state and show error
      await QuizService.clearQuizState();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error continuing quiz: $e')));
      }
    }
  }

  Future<void> _quizCompleted({
    required String deckId,
    required int correctAnswers,
    required int incorrectAnswers,
    required int timeSpentSeconds,
    int skippedAnswers = 0,
  }) async {
    if (_userStore.user == null || !UserService.isAuthenticated) {
      return;
    }

    try {
      final deck = _userStore.decks.firstWhere((d) => d.id == deckId);

      final quizResult = QuizResult(
        userId: _userStore.user!.userId,
        deckId: deckId,
        deckName: deck.name,
        totalCards: deck.cards.length,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers,
        skippedAnswers: skippedAnswers,
        timeSpentSeconds: timeSpentSeconds,
      );

      _userStore.addQuiz(await QuizResultService.save(quizResult));
    } catch (e) {
      Logger.log('Error saving quiz result: $e', name: "QuizScreen");
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      await _userStore.getData();
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          icon: Icon(FIcons.circleX),
          title: Text(e.toString().replaceAll('Exception: ', '')),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPrimary(
        title: Text(
          'Quiz',
          style: context.theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _loadData,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildContent() {
    final filtered = _userStore.decks
        .where((d) => d.cards.length >= 4)
        .toList();

    if (filtered.isEmpty) {
      return _QuizEmpty(isEmpty: filtered.isEmpty);
    }

    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final deck = filtered[index];

        return _QuizDeckCard(
          deck: deck,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizPlayScreen(
                  deck: deck,
                  onCompleted: (correct) => _quizCompleted(
                    deckId: deck.id,
                    correctAnswers: correct,
                    incorrectAnswers: deck.cards.length - correct,
                    timeSpentSeconds: 0,
                  ),
                ),
              ),
            );

            // Check if we returned from quiz without completing
            // If so, check if there's still a saved state
            if (result != 'completed') {
              _checkForPreviousQuiz();
            }
          },
        );
      },
    );
  }
}

class _QuizEmpty extends StatelessWidget {
  final bool isEmpty;

  const _QuizEmpty({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: colors.mutedForeground.withValues(alpha: 0.8),
          ),
          SizedBox(height: 20),
          Text(
            isEmpty ? 'No decks available' : 'No decks with enough cards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.mutedForeground,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isEmpty
                  ? 'Create at least one deck with 4+ cards to start'
                  : 'Add at least 4 cards to a deck to begin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.mutedForeground.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizDeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const _QuizDeckCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final hasCards = deck.cards.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FCard(
            image: Center(
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (hasCards ? colors.border : colors.muted),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz,
                  color: hasCards ? colors.primary : colors.mutedForeground,
                  size: 24,
                ),
              ),
            ),
            title: Center(
              child: Text(
                deck.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.typography.sm.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            child: Center(
              child: TBadge(
                margin: EdgeInsets.only(top: 8),
                label: '${deck.cards.length} cards',
                backgroundColor: colors.secondary,
                foregroundColor: colors.secondaryForeground,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizContinueDialog extends StatelessWidget {
  final String name;
  final String progress;
  final FDialogStyle style;
  final VoidCallback onContinue;
  final Animation<double> animation;

  const _QuizContinueDialog({
    required this.name,
    required this.progress,
    required this.onContinue,
    required this.style,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FDialog(
      animation: animation,
      style: style.call,
      direction: Axis.horizontal,
      title: Text('Continue Previous Quiz?'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You have an unfinished quiz for:'),
          SizedBox(height: 8),
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Progress: $progress cards'),
        ],
      ),
      actions: [
        FButton(
          mainAxisSize: MainAxisSize.min,
          style: FButtonStyle.outline(),
          onPress: () async {
            Navigator.of(context).pop();
            await QuizService.clearQuizState();
          },
          child: Text('Start New'),
        ),
        FButton(
          mainAxisSize: MainAxisSize.min,
          onPress: () {
            Navigator.of(context).pop();
            onContinue();
          },
          child: Text('Continue'),
        ),
      ],
    );
  }
}
