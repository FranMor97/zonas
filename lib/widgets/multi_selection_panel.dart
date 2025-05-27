import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/board.dart';
import 'package:table_game/models/board_components/element_type.dart';
import 'package:table_game/views/zone_editor/zone_editor_content.dart';

class MultiSelectionPanel extends StatelessWidget {
  final int selectedCount;
  final Set<String> mergedGroups;
  final Map<String, int> elementTypes;

  const MultiSelectionPanel({
    super.key,
    required this.selectedCount,
    required this.mergedGroups,
    required this.elementTypes,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<ZoneEditorBloc>().state as ZoneEditorLoaded;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selección múltiple ($selectedCount tiles)',
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(ClearTileSelection());
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (mergedGroups.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.lightBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${mergedGroups.length} grupo(s) fusionado(s) incluido(s)',
                    style: const TextStyle(
                      color: Colors.lightBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          if (elementTypes.isNotEmpty)
            Wrap(
              spacing: 8,
              children: elementTypes.entries.map((entry) {
                final elementType = state.availableElements.firstWhere((e) => e.id == entry.key,
                    orElse: () => ElementType(
                        id: entry.key,
                        name: 'Desconocido',
                        color: Colors.grey,
                        icon: Icons.help,
                        defaultSize: const Size(1, 1)));

                return Chip(
                  avatar: Icon(elementType.icon, size: 16),
                  label: Text('${elementType.name}: ${entry.value}'),
                  backgroundColor: elementType.color.withOpacity(0.2),
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),

          const SizedBox(height: 16),

          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: const Text('Fusionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.allSelectedSameType && selectedCount > 1
                      ? const Color(0xFF00BFA5)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: state.allSelectedSameType && selectedCount > 1
                    ? () {
                  context.read<ZoneEditorBloc>().add(MergeSelectedTiles());
                }
                    : null,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete),
                label: const Text('Eliminar selección'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  // Eliminar todos los tiles seleccionados
                  Board updatedBoard = state.board;
                  for (final tile in state.selectedTiles) {
                    updatedBoard = updatedBoard.removeElement(tile.x, tile.y);
                  }

                  context.read<ZoneEditorBloc>().add(BoardUpdated(updatedBoard));
                  context.read<ZoneEditorBloc>().add(ClearTileSelection());
                },
              ),
              if (mergedGroups.isNotEmpty)
                ElevatedButton.icon(
                  icon: const Icon(Icons.link_off),
                  label: const Text('Separar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    separateMergedElements(context, state);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

