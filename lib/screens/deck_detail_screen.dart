import 'package:flipcard/models/language.dart';
import 'package:flipcard/screens/quiz_play_screen.dart';
import 'package:flipcard/services/card_service.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/flashcard.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class DeckDetailsScreen extends StatefulWidget {
  final Deck deck;

  const DeckDetailsScreen({super.key, required this.deck});

  @override
  State<DeckDetailsScreen> createState() => _DeckDetailsScreenState();
}

class _DeckDetailsScreenState extends State<DeckDetailsScreen> {
  late UserStore _userStore;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  Future<void> _addCard() async {
    final result = await showModalBottomSheet<FlashCard?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CardEditSheet(
        onSave: (front, back) =>
            FlashCard(deckId: widget.deck.id, front: front, back: back),
      ),
    );

    if (result != null) {
      final card = await CardService.create(
        FlashCard(
          deckId: widget.deck.id,
          back: result.back,
          front: result.front,
        ),
      );

      setState(() {
        widget.deck.cards.add(card);
        _userStore.updateUserStats();
      });
    }
  }

  Future<void> _editCard(FlashCard card) async {
    final result = await showFSheet<FlashCard?>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (context) => _CardEditSheet(
        card: card,
        onSave: (front, back) => card.copyWith(front: front, back: back),
      ),
    );

    if (result != null) {
      await CardService.update(result);
      final idx = widget.deck.cards.indexWhere((v) => v.id == card.id);
      setState(() {
        widget.deck.cards[idx] = result;
        _userStore.updateUserStats();
      });
    }
  }

  Future<void> _deleteCard(FlashCard card) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Delete Card',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            content: Text(
              'Are you sure you want to delete "${card.front}"?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              FButton(
                mainAxisSize: MainAxisSize.min,
                style: FButtonStyle.outline(),
                onPress: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: () => Navigator.pop(context, true),
                style: FButtonStyle.destructive(),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await CardService.deleteById(card.id);
      setState(() {
        widget.deck.cards.remove(card);
        _userStore.updateUserStats();
      });
    }
  }

  Future<void> _showDeckSettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DeckSettings(
        deck: widget.deck,
        onSave: (deck) async {
          debugPrint(deck.toString());
          setState(() {
            // need fix 'widget.deck' with editable deck
            widget.deck.backLanguage = deck.backLanguage;
            widget.deck.frontLanguage = deck.frontLanguage;
          });
          await _userStore.addDeck(deck);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeOf = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deck.name,
          style: themeOf.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (widget.deck.cards.length >= 4)
            IconButton(
              icon: Icon(FIcons.circlePlay),
              tooltip: 'Start Quiz',
              style: IconButton.styleFrom(shape: CircleBorder()),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPlayScreen(deck: widget.deck),
                  ),
                );
              },
            ),

          IconButton(
            icon: Icon(FIcons.settings2),
            tooltip: 'Deck Settings',
            style: IconButton.styleFrom(shape: CircleBorder()),
            onPressed: _showDeckSettings,
          ),
        ],
      ),
      body: _userStore.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _userStore.getData,
              child: widget.deck.cards.isEmpty
                  ? _EmptyDeckState(onAddCard: _addCard)
                  : _CardListView(
                      cards: widget.deck.cards,
                      onEdit: _editCard,
                      onDelete: _deleteCard,
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _addCard,
        shape: CircleBorder(
          side: BorderSide(color: themeOf.colorScheme.outline, width: 1),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EmptyDeckState extends StatelessWidget {
  final VoidCallback onAddCard;

  const _EmptyDeckState({required this.onAddCard});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.copy,
                size: 80,
                color: colors.mutedForeground.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'No Cards Yet',
                style: themeOf.textTheme.titleMedium?.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first card to get started',
                style: themeOf.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedForeground.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: onAddCard,
                mainAxisSize: MainAxisSize.min,
                child: const Text('Add Card'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardListView extends StatelessWidget {
  final List<FlashCard> cards;
  final Function(FlashCard) onEdit;
  final Function(FlashCard) onDelete;

  const _CardListView({
    required this.cards,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _FlashCardItem(
          card: card,
          onEdit: () => onEdit(card),
          onDelete: () => onDelete(card),
        );
      },
    );
  }
}

class _FlashCardItem extends StatelessWidget {
  final FlashCard card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FlashCardItem({
    required this.card,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return Card(
      elevation: 0,
      color: colors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        title: Text(
          card.front,
          style: themeOf.textTheme.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Answer :',
                  style: themeOf.textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground.withValues(alpha: 0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(card.back, style: themeOf.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      onPress: onEdit,
                      style: FButtonStyle.outline(),
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      onPress: onDelete,
                      style: FButtonStyle.destructive(),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEditSheet extends StatefulWidget {
  final FlashCard? card;
  final FlashCard Function(String front, String back) onSave;

  const _CardEditSheet({required this.onSave, this.card});

  @override
  State<_CardEditSheet> createState() => _CardEditSheetState();
}

class _CardEditSheetState extends State<_CardEditSheet> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front);
    _backController = TextEditingController(text: widget.card?.back);
  }

  @override
  Widget build(BuildContext context) {
    final themeOf = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.theme.colors.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.theme.colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.card == null ? 'Add New Card' : 'Edit Card',
            style: themeOf.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          FTextField(
            hint: 'Question',
            maxLines: 2,
            autofocus: true,
            controller: _frontController,
          ),
          const SizedBox(height: 16),
          FTextField(controller: _backController, hint: 'Answer', maxLines: 3),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: () => Navigator.pop(context),
                  style: FButtonStyle.outline(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FButton(
                  onPress: () {
                    if (_frontController.text.isNotEmpty &&
                        _backController.text.isNotEmpty) {
                      Navigator.pop(
                        context,
                        widget.onSave(
                          _frontController.text,
                          _backController.text,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _DeckSettings extends StatefulWidget {
  final Deck deck;
  final Function(Deck) onSave;

  const _DeckSettings({required this.deck, required this.onSave});

  @override
  State<StatefulWidget> createState() => _DeckSettingsState();
}

class _DeckSettingsState extends State<_DeckSettings> {
  late String selectedFrontLanguage;
  late String selectedBackLanguage;

  @override
  void initState() {
    final deck = widget.deck;
    selectedFrontLanguage = Language.findByLocale(deck.frontLanguage).code;
    selectedBackLanguage = Language.findByLocale(deck.backLanguage).code;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: context.theme.colors.border,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Deck Settings',
            style: themeOf.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure speech recognition languages for this deck',
            style: themeOf.textTheme.bodyMedium?.copyWith(
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),

          // Front Language Setting
          _LanguageSelector(
            title: 'Front Card Language',
            subtitle: 'Language for question/front side',
            selectedLanguage: selectedFrontLanguage,
            onLanguageChanged: (language) {
              setState(() {
                selectedFrontLanguage = language;
              });
            },
          ),
          const SizedBox(height: 16),

          // Back Language Setting
          _LanguageSelector(
            title: 'Back Card Language',
            subtitle: 'Language for answer/back side',
            selectedLanguage: selectedBackLanguage,
            onLanguageChanged: (language) {
              setState(() {
                selectedBackLanguage = language;
              });
            },
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: () => Navigator.pop(context),
                  style: FButtonStyle.outline(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FButton(
                  onPress: () {
                    final updatedDeck = widget.deck.copyWith(
                      frontLanguage: _parseLocale(selectedFrontLanguage),
                      backLanguage: _parseLocale(selectedBackLanguage),
                    );
                    widget.onSave(updatedDeck);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Locale _parseLocale(String localeString) {
    final parts = localeString.split('-');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }
}

class _LanguageSelector extends StatelessWidget {
  final String title;
  final String subtitle;
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const _LanguageSelector({
    required this.title,
    required this.subtitle,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);
    final selectedLang = Language.findByCode(selectedLanguage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: themeOf.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: themeOf.textTheme.bodySmall?.copyWith(
            color: colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showLanguagePicker(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  selectedLang?.flag ?? '🌐',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedLang?.name ?? 'Unknown',
                    style: themeOf.textTheme.bodyMedium,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: colors.mutedForeground),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LanguagePickerSheet(
        selectedLanguage: selectedLanguage,
        onLanguageSelected: onLanguageChanged,
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const _LanguagePickerSheet({
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String searchQuery = '';
  List<Language> filteredLanguages = Language.list;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: context.theme.colors.border,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            'Select Language',
            style: themeOf.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Search field
          FTextField(
            hint: 'Search languages...',
            onChange: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
                filteredLanguages = Language.list
                    .where(
                      (lang) =>
                          lang.name.toLowerCase().contains(searchQuery) ||
                          lang.code.toLowerCase().contains(searchQuery),
                    )
                    .toList();
              });
            },
          ),
          const SizedBox(height: 16),

          // Language list
          Expanded(
            child: ListView.builder(
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                final language = filteredLanguages[index];
                final isSelected = language.code == widget.selectedLanguage;

                return ListTile(
                  leading: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(
                    language.name,
                    style: themeOf.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    language.code,
                    style: themeOf.textTheme.bodySmall?.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: colors.primary)
                      : null,
                  onTap: () {
                    widget.onLanguageSelected(language.code);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
