import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flipcard/models/deck.dart';
import 'package:flipcard/models/flashcard.dart';
import 'package:flipcard/stores/user_store.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreen();
}

class _MenuScreen extends State<MenuScreen> {
  late UserStore _userStore;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userStore = Provider.of<UserStore>(context);
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

  Future<void> _exportDeck(BuildContext context, Deck deck) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${deck.name}.json');
      final timestamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[^\w]'),
        '_',
      );

      final exportData = deck.toJson()
        ..['exported_at'] = timestamp
        ..['created_at'] = deck.createdAt.toIso8601String()
        ..['updated_at'] = deck.updatedAt.toIso8601String();

      await file.writeAsString(json.encode(exportData));

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Sharing ${deck.name} flashcard deck',
          subject: 'Flashcard Deck Export',
        ),
      );
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FIcons.triangleAlert),
          title: Text('Export Failed'),
          description: Text(e.toString()),
          alignment: FToastAlignment.bottomCenter,
        );
      }
    }
  }

  Future<void> _importDeck(BuildContext context) async {
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

      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FIcons.circleCheck),
          title: Text('Imported ${importedDeck.name}'),
          duration: const Duration(seconds: 2),
        );
      }
    } on FormatException {
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FIcons.triangleAlert),
          title: const Text('Invalid file format'),
          description: const Text(
            'The selected file is not a valid deck format',
          ),
        );
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FIcons.triangleAlert),
          title: const Text('Import failed'),
          description: Text(e.toString()),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final themeOf = Theme.of(context);
    final filtered = _userStore.decks
        .where((d) => d.cards.length >= 4)
        .toList();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _loadData,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Import Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.border),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _importDeck(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: colors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.download_rounded,
                                  color: colors.secondaryForeground,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Import Deck',
                                      style: themeOf.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add decks from JSON files',
                                      style: themeOf.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colors.mutedForeground
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colors.mutedForeground,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Export Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Available Decks',
                        style: themeOf.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FIcons.squareLibrary,
                                    size: 68,
                                    color: colors.mutedForeground.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    filtered.isEmpty
                                        ? 'No decks available'
                                        : 'No decks with enough cards',
                                    style: themeOf.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: colors.mutedForeground,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    filtered.isEmpty
                                        ? 'Create at least one deck with 4+ cards to start'
                                        : 'Add at least 4 cards to a deck begin',
                                    style: themeOf.textTheme.bodyMedium
                                        ?.copyWith(
                                          color: colors.mutedForeground
                                              .withValues(alpha: 0.8),
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final deck = filtered[index];

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: colors.border),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _exportDeck(context, deck),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: colors.secondary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.upload_rounded,
                                              color: colors.secondaryForeground,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deck.name,
                                                  style: themeOf
                                                      .textTheme
                                                      .titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${deck.cards.length} cards',
                                                  style: themeOf
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .mutedForeground,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.share_rounded,
                                            color: colors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
