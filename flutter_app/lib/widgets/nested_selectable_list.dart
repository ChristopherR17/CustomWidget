import 'package:flutter/material.dart';

class NestedSelectableList<T> extends StatelessWidget {
  const NestedSelectableList({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> items;
  final T? selected;
  final String Function(T item) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        ...items.map((item) {
          final isSelected = selected == item;
          return Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, bottom: 4),
            child: ListTile(
              dense: true,
              selected: isSelected,
              selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(labelOf(item), style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
              onTap: () => onSelected(item),
            ),
          );
        }),
      ],
    );
  }
}
