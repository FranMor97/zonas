import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/board.dart';
import 'package:table_game/models/board_components/tile.dart';
import 'package:table_game/views/zone_editor/properties_panel.dart';
import 'package:table_game/widgets/board_grid.dart';
import 'package:table_game/widgets/element_palette.dart';
import 'package:table_game/widgets/mode_button.dart';
import 'package:table_game/widgets/multi_selection_panel.dart';

class ZoneEditorContent extends StatelessWidget {
  final ZoneEditorLoaded state;

  const ZoneEditorContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        title: Text('Editor - ${state.board.config.name}'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (state.editMode == 'select')
            IconButton(
              icon: Icon(
                state.isMultiSelectMode ? Icons.select_all : Icons.checklist,
                color: state.isMultiSelectMode ? Colors.lightBlue : Colors.white,
              ),
              tooltip: state.isMultiSelectMode
                  ? 'Desactivar selección múltiple'
                  : 'Activar selección múltiple',
              onPressed: () {
                context.read<ZoneEditorBloc>().add(ToggleMultiSelectMode(!state.isMultiSelectMode));
              },
            ),
          if (state.isMultiSelectMode && state.selectedTiles.length > 1)
            IconButton(
              icon: const Icon(Icons.merge_type),
              tooltip: 'Fusionar tiles seleccionados',
              onPressed: () {
                context.read<ZoneEditorBloc>().add(MergeSelectedTiles());
              },
            ),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(UndoLastAction());
            },
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Rehacer',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(RedoLastAction());
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar tablero',
            onPressed: () {
              _showConfirmationDialog(
                context,
                'Limpiar tablero',
                '¿Estás seguro de que deseas limpiar todo el tablero?',
                () {
                  context.read<ZoneEditorBloc>().add(ClearBoard());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(const SaveCurrentBoard());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                color: const Color(0xFF333333),
                child: ElementPalette(
                  elements: state.availableElements,
                  selectedElement: state.selectedElement,
                  eraserMode: state.eraserMode,
                  onElementSelected: (element) {
                    context.read<ZoneEditorBloc>().add(ElementTypeSelected(element));
                  },
                  onEraserToggled: (enabled) {
                    context.read<ZoneEditorBloc>().add(EraserModeToggled(enabled));
                  },
                ),
              ),
              if (state.isMultiSelectMode)
                Container(
                  color: Colors.blue.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.select_all, color: Colors.lightBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Modo selección múltiple activo (${state.selectedTiles.length} seleccionados)',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Limpiar selección'),
                        onPressed: () {
                          context.read<ZoneEditorBloc>().add(ClearTileSelection());
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: const Color(0xFF333333),
                child: Row(
                  children: [
                    Icon(
                      state.eraserMode
                          ? Icons.delete_outline
                          : state.editMode == 'select'
                              ? Icons.select_all
                              : state.selectedElement?.icon ?? Icons.touch_app,
                      color: state.eraserMode
                          ? Colors.red
                          : state.editMode == 'select'
                              ? Colors.blue
                              : state.selectedElement?.color ?? Colors.white70,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      state.eraserMode
                          ? 'Modo borrador'
                          : state.editMode == 'select'
                              ? 'Modo selección'
                              : state.selectedElement != null
                                  ? 'Elemento: ${state.selectedElement!.name}'
                                  : 'Selecciona un elemento',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Spacer(),
                    // Botones de modo
                    Row(
                      children: [
                        ModeButton(
                          mode: 'place',
                          icon: Icons.add_box,
                          label: 'Colocar',
                          isSelected: state.editMode == 'place',
                        ),
                        const SizedBox(width: 8),
                        ModeButton(
                          mode: 'erase',
                          icon: Icons.delete,
                          label: 'Borrar',
                          isSelected: state.editMode == 'erase',
                        ),
                        const SizedBox(width: 8),
                        ModeButton(
                          mode: 'select',
                          icon: Icons.select_all,
                          label: 'Seleccionar',
                          isSelected: state.editMode == 'select',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF1A1A1A),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: BoardGrid(
                            board: state.board,
                            onTileTap: (x, y) {
                              context.read<ZoneEditorBloc>().add(TileTapped(x, y));
                            },
                            onTileDrag: (x, y) {
                              context.read<ZoneEditorBloc>().add(TileDragged(x, y));
                            },
                            onEraseDrag: (x, y) {
                              context.read<ZoneEditorBloc>().add(EraseDragg(x, y));
                            },
                            onDragEnd: () {
                              context.read<ZoneEditorBloc>().add(DragEnded());
                            },
                            selectedTile: state.selectedTile,
                            mode: state.editMode,
                            selectedElement: state.selectedElement,
                            showCoordinates: true,
                            selectedTiles: state.selectedTiles,
                            isMultiSelectMode: state.isMultiSelectMode,
                            editorState: state,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomSheet: _buildBottomPanel(context, state),
    );
  }

  Widget _buildBottomPanel(BuildContext context, ZoneEditorLoaded state) {
    if (state.isMultiSelectMode && state.selectedTiles.isNotEmpty) {
      return MultiSelectionPanel(
        elementTypes: state.selectedElementTypes,
        mergedGroups: state.selectedMergedGroups,
        selectedCount: state.selectedTiles.length,
      );
    } else if (state.hasSelectedTile && state.selectedTile != null && state.editMode == 'select') {
      return const PropertiesPanel();
    }
    // Sin panel
    return const SizedBox.shrink();
  }


  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    Function() onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

void separateMergedElements(BuildContext context, ZoneEditorLoaded state) {
  Board updatedBoard = state.board;

  // Para cada grupo fusionado seleccionado
  for (final groupId in state.selectedMergedGroups) {
    final groupTiles = state.getMergedElementTiles(groupId);

    // Remover todos los tiles del grupo
    for (final tile in groupTiles) {
      updatedBoard = updatedBoard.removeElement(tile.x, tile.y);
    }

    // Volver a colocar cada tile como elemento individual
    for (final tile in groupTiles) {
      if (tile.type != null) {
        updatedBoard = updatedBoard.placeElement(
          tile.x,
          tile.y,
          tile.type!,
          rotation: tile.rotation,
          properties: {
            ...tile.properties ?? {},
            'isMerged': false,
            'mergedGroupId': null,
          },
        );
      }
    }
  }

  context.read<ZoneEditorBloc>().add(BoardUpdated(updatedBoard));
  context.read<ZoneEditorBloc>().add(ClearTileSelection());
}
