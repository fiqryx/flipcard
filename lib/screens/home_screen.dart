import 'package:flutter/material.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/screens/deck_detail_screen.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:forui/forui.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late UserStore _userStore;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _userStore.getData();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addDeck() async {
    await showFSheet<Deck?>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (context) => _DeckEditSheet(
        onSave: (name, description) {
          final deck = Deck(
            name: name,
            description: description,
            cards: [],
            createdAt: DateTime.now(),
          );

          _userStore.addDeck(deck);

          return deck;
        },
      ),
    );
  }

  Future<void> _editDeck(Deck deck) async {
    await showFSheet<Deck?>(
      context: context,
      side: FLayout.btt,
      mainAxisMaxRatio: null,
      builder: (context) => _DeckEditSheet(
        deck: deck,
        onSave: (name, description) {
          final updatedDeck = deck.copyWith(
            name: name,
            description: description,
            updatedAt: DateTime.now(),
          );

          _userStore.addDeck(updatedDeck);

          return updatedDeck;
        },
      ),
    );
  }

  Future<void> _deleteDeck(Deck deck) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Deck'),
            content: Text('Are you sure you want to delete "${deck.name}"?'),
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

    if (confirmed && mounted) {
      _userStore.deleteDeck(deck.id);
    }
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DeckDetailsScreen(deck: deck)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Decks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _loadData,
              child: _userStore.decks.isEmpty
                  ? _EmptyDeckState(onAddDeck: _addDeck)
                  : _DeckListView(
                      decks: _userStore.decks,
                      onTap: _openDeck,
                      onEdit: _editDeck,
                      onDelete: _deleteDeck,
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _addDeck,
        shape: CircleBorder(side: BorderSide(color: colors.border, width: 1)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EmptyDeckState extends StatelessWidget {
  final VoidCallback onAddDeck;

  const _EmptyDeckState({required this.onAddDeck});

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
                size: 80,
                FIcons.squareLibrary,
                color: colors.mutedForeground.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'No Decks Yet',
                style: themeOf.textTheme.titleMedium?.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first deck to get started',
                style: themeOf.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedForeground.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              FButton(
                onPress: onAddDeck,
                prefix: Icon(Icons.add),
                mainAxisSize: MainAxisSize.min,
                child: const Text('Create Deck'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckListView extends StatelessWidget {
  final List<Deck> decks;
  final Function(Deck) onTap;
  final Function(Deck) onEdit;
  final Function(Deck) onDelete;

  const _DeckListView({
    required this.decks,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: decks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final deck = decks[index];
        return _DeckCard(
          deck: deck,
          onTap: () => onTap(deck),
          onEdit: () => onEdit(deck),
          onDelete: () => onDelete(deck),
        );
      },
    );
  }
}

class _DeckCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return FCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.secondary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${deck.cards.length}',
                  style: TextStyle(
                    color: colors.secondaryForeground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deck.name,
                    style: themeOf.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (deck.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      deck.description,
                      style: themeOf.textTheme.bodySmall?.copyWith(
                        color: colors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: onEdit,
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: onDelete,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: colors.destructive,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: colors.destructive),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckEditSheet extends StatefulWidget {
  final Deck? deck;
  final Deck Function(String name, String description) onSave;

  const _DeckEditSheet({required this.onSave, this.deck});

  @override
  State<_DeckEditSheet> createState() => _DeckEditSheetState();
}

class _DeckEditSheetState extends State<_DeckEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deck?.name);
    _descriptionController = TextEditingController(
      text: widget.deck?.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.deck == null ? 'New Deck' : 'Edit Deck',
            style: themeOf.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          FTextField(
            autofocus: true,
            hint: 'Deck Name',
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          FTextField(
            maxLines: 3,
            hint: 'Description (Optional)',
            controller: _descriptionController,
          ),
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
                    if (_nameController.text.isNotEmpty) {
                      Navigator.pop(
                        context,
                        widget.onSave(
                          _nameController.text,
                          _descriptionController.text,
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
