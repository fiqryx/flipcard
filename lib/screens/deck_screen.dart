import 'dart:convert';
import 'dart:io';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/flashcard.dart';
import 'package:flipcard/constants/enums.dart';
import 'package:flipcard/widgets/app_bar.dart';
import 'package:flipcard/widgets/badge.dart';
import 'package:flipcard/widgets/button_group.dart';
import 'package:flipcard/widgets/deck_sheet.dart';
import 'package:flipcard/widgets/expandable_fab.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flipcard/screens/deck_detail_screen.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  late UserStore _userStore;

  final _viewKey = 'deck_view';
  final _storage = FlutterSecureStorage();

  bool _isLoading = false;
  String _searchValue = '';
  List<Deck> _filteredDecks = [];
  ViewMode _viewMode = ViewMode.list;

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
    try {
      setState(() => _isLoading = true);

      final layout = await _storage.read(key: _viewKey);
      debugPrint(layout);
      setState(() {
        _viewMode = layout == 'grid' ? ViewMode.grid : ViewMode.list;
      });

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
      _filterDeck(_searchValue);
    }
  }

  Future<void> _addDeck() async {
    try {
      final deck = await showFSheet<Deck?>(
        context: context,
        side: FLayout.btt,
        mainAxisMaxRatio: null,
        builder: (context) => DeckSheet(
          onSave: (name, description) => Deck(
            name: name,
            description: description,
            cards: [],
            createdAt: DateTime.now(),
          ),
        ),
      );

      if (deck != null) {
        setState(() => _isLoading = true);
        await _userStore.addDeck(deck);
        _filterDeck(_searchValue);
      }
    } catch (e) {
      _showError('Create failed', description: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importDeck() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Deck File',
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final contents = await file.readAsString();
      final Map<String, dynamic> deckJson = json.decode(contents);

      // Validate basic structure
      if (deckJson['name'] == null || deckJson['cards'] == null) {
        throw FormatException('Invalid deck format - missing required fields');
      }

      // Generate new IDs and preserve original data
      final importedDeck = Deck(
        name: deckJson['name'] as String,
        description: deckJson['description'] as String? ?? '',
        cards: (deckJson['cards'] as List).map((card) {
          return FlashCard(
            deckId: '',
            front: card['front'] as String? ?? '',
            back: card['back'] as String? ?? '',
            description: card['description'] as String? ?? '',
            isFlipped: false,
          );
        }).toList(),
      );

      for (final card in importedDeck.cards) {
        card.deckId = importedDeck.id;
      }

      _userStore.decks.add(importedDeck);
      await _userStore.updateDecks([..._userStore.decks]);
      _filterDeck('');

      if (mounted) {
        showFToast(
          context: context,
          icon: const Icon(FIcons.circleCheck),
          title: Text('Imported ${importedDeck.name}'),
          duration: const Duration(seconds: 2),
        );
      }
    } on FormatException {
      _showError(
        'Invalid file format',
        description: 'The selected file is not a valid deck format',
      );
    } catch (e) {
      _showError('Import failed', description: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterDeck(String value) {
    if (value.isEmpty) {
      _filteredDecks = List.from(_userStore.decks);
    } else {
      _filteredDecks = _userStore.decks.where((deck) {
        return deck.name.toLowerCase().contains(value.toLowerCase()) ||
            deck.description.toLowerCase().contains(value.toLowerCase());
      }).toList();
    }
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeckDetailsScreen(
          deck: deck,
          onDeleted: () {
            setState(() {
              _searchValue = '';
              _filterDeck('');
            });
          },
        ),
      ),
    );
  }

  void _toggleLayout() async {
    final isList = _viewMode == ViewMode.list;
    await _storage.write(key: _viewKey, value: isList ? 'grid' : 'list');
    setState(() => _viewMode = isList ? ViewMode.grid : ViewMode.list);
  }

  void _showError(String message, {String? description}) {
    if (mounted) {
      showFToast(
        context: context,
        icon: Icon(FIcons.circleX),
        alignment: FToastAlignment.bottomCenter,
        title: Text(message.replaceAll('Exception: ', '')),
        description: description != null
            ? Text(description.replaceAll('Exception: ', ''))
            : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarPrimary(
        title: Text(
          'Your Decks',
          style: context.theme.typography.lg.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Scaffold(
        appBar: AppBarSecondary(
          hint: 'Search decks...',
          onSearch: (value) {
            setState(() {
              _searchValue = value;
              _filterDeck(value);
            });
          },
          actions: [
            ButtonGroup(
              children: [
                ButtonGroupItem(
                  width: 30,
                  height: 30,
                  icon: FIcons.layoutList,
                  isActive: _viewMode == ViewMode.list,
                  onPressed: _viewMode == ViewMode.list ? null : _toggleLayout,
                ),
                ButtonGroupItem(
                  width: 30,
                  height: 30,
                  icon: FIcons.layoutGrid,
                  isActive: _viewMode == ViewMode.grid,
                  onPressed: _viewMode == ViewMode.grid ? null : _toggleLayout,
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator.adaptive(
                onRefresh: _loadData,
                child: _buildContent(),
              ),
      ),
      floatingActionButtonLocation: ExpandedFab.location,
      floatingActionButton: ExpandedFab(
        distance: 60,
        openIcon: Icon(FIcons.plus, size: 20),
        shape: CircleBorder(),
        children: [
          Row(
            spacing: 10,
            children: [
              Text('Import deck'),
              FloatingActionButton.small(
                shape: CircleBorder(),
                onPressed: _importDeck,
                child: const Icon(FIcons.cloudUpload, size: 20),
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Text('Create deck'),
              FloatingActionButton.small(
                shape: CircleBorder(),
                onPressed: _addDeck,
                child: const Icon(FIcons.squarePlus, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_userStore.decks.isEmpty) {
      return _EmptyDeckState(onAddDeck: _addDeck);
    }

    if (_filteredDecks.isEmpty) {
      return _EmptySearchState(searchTerm: _searchValue);
    }

    if (_viewMode == ViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredDecks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final deck = _filteredDecks[index];
          return _DecListkCard(deck: deck, onTap: () => _openDeck(deck));
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemCount: _filteredDecks.length,
      itemBuilder: (context, index) {
        final deck = _filteredDecks[index];
        return _DeckGridCard(deck: deck, onTap: () => _openDeck(deck));
      },
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  final String searchTerm;

  const _EmptySearchState({required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FIcons.searchX,
                size: 80,
                color: colors.mutedForeground.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: themeOf.textTheme.titleMedium?.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No decks match "$searchTerm"',
                style: themeOf.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedForeground.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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
                FIcons.layers,
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

class _DecListkCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const _DecListkCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return InkWell(
      onTap: onTap,
      child: FCard(
        title: Text(
          deck.name,
          style: theme.typography.sm.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          deck.description,
          style: theme.typography.xs.copyWith(color: colors.mutedForeground),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        child: TBadge(
          margin: EdgeInsets.only(top: 6),
          label: '${deck.cards.length} cards',
          backgroundColor: colors.secondary,
          foregroundColor: colors.secondaryForeground,
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
      ),
    );
  }
}

class _DeckGridCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;

  const _DeckGridCard({required this.deck, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;

    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FCard(
            // image: Icon(Icons.quiz, size: 24, color: colors.mutedForeground),
            title: Text(
              deck.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.sm.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              deck.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: TBadge(
              label: '${deck.cards.length} cards',
              backgroundColor: colors.secondary,
              foregroundColor: colors.secondaryForeground,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
