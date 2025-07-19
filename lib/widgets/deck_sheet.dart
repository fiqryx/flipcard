import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flipcard/models/deck.dart';

class DeckSheet extends StatefulWidget {
  final Deck? deck;
  final Deck Function(String name, String description) onSave;

  const DeckSheet({super.key, required this.onSave, this.deck});

  @override
  State<DeckSheet> createState() => DeckSheetState();
}

class DeckSheetState extends State<DeckSheet> {
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
            widget.deck == null ? 'Add Deck' : 'Edit Deck',
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.bold),
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
