// lib/screens/zone_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/models/board_components/board.dart';
import '../bloc/zone_editor_bloc/zone_editor_bloc.dart';
import '../models/board_components/tile.dart';
import '../widgets/board_grid.dart';
import '../widgets/element_palette.dart';

class ZoneEditorScreen extends StatelessWidget {
  const ZoneEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ZoneEditorBloc, ZoneEditorState>(
      listener: (context, state) {
        if (state is ZoneEditorSnackError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ZoneEditorSucces) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ZoneEditorLoaded) {
          return _ZoneEditorView(state: state);
        } else if (state is ZoneEditorLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF212121),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ZoneEditorError) {
          return Scaffold(
            backgroundColor: Color(0xFF212121),
            appBar: AppBar(
              title: const Text('Editor de Zonas'),
              backgroundColor: Color(0xFF333333),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00BFA5),
                    ),
                    onPressed: () {
                      // Reintentar con la configuración inicial
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Scaffold(
            backgroundColor: Color(0xFF212121),
            body: Center(
              child: Text(
                'Inicializando editor...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      },
    );
  }
}

class _ZoneEditorView extends StatelessWidget {
  final ZoneEditorLoaded state;

  const _ZoneEditorView({required this.state});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF333333),
        title: Text('Editor - ${state.board.config.name}'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón de selección múltiple (solo visible en modo selección)
          if (state.editMode == 'select')
            IconButton(
              icon: Icon(
                state.isMultiSelectMode
                    ? Icons.select_all
                    : Icons.checklist,
                color: state.isMultiSelectMode ? Colors.lightBlue : Colors.white,
              ),
              tooltip: state.isMultiSelectMode
                  ? 'Desactivar selección múltiple'
                  : 'Activar selección múltiple',
              onPressed: () {
                context.read<ZoneEditorBloc>().add(
                    ToggleMultiSelectMode(!state.isMultiSelectMode)
                );
              },
            ),

          // Botón para fusionar (solo visible en modo selección múltiple con tiles seleccionados)
          if (state.isMultiSelectMode && state.selectedTiles.length > 1)
            IconButton(
              icon: const Icon(Icons.merge_type),
              tooltip: 'Fusionar tiles seleccionados',
              onPressed: () {
                context.read<ZoneEditorBloc>().add(MergeSelectedTiles());
              },
            ),

          // Acciones existentes
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
              // Paleta de elementos disponibles
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Color(0xFF333333),
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

              // Barra de modo actual
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
                    const Spacer(),
                    // Botones de modo
                    Row(
                      children: [
                        _buildModeButton(
                          context,
                          'place',
                          Icons.add_box,
                          'Colocar',
                          state.editMode == 'place',
                        ),
                        const SizedBox(width: 8),
                        _buildModeButton(
                          context,
                          'erase',
                          Icons.delete,
                          'Borrar',
                          state.editMode == 'erase',
                        ),
                        const SizedBox(width: 8),
                        _buildModeButton(
                          context,
                          'select',
                          Icons.select_all,
                          'Seleccionar',
                          state.editMode == 'select',
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
    // Si estamos en modo selección múltiple con tiles seleccionados
    if (state.isMultiSelectMode && state.selectedTiles.isNotEmpty) {
      return _buildMultiSelectionPanel(context, state);
    }
    // Si tenemos un solo tile seleccionado (modo original)
    else if (state.hasSelectedTile && state.selectedTile != null && state.editMode == 'select') {
      return _buildPropertiesPanel(context, state);
    }
    // Sin panel
    return const SizedBox.shrink();
  }

  // Nuevo panel para selección múltiple
  Widget _buildMultiSelectionPanel(BuildContext context, ZoneEditorLoaded state) {
    final selectedCount = state.selectedTiles.length;

    // Verificar si todos los tiles son del mismo tipo
    bool allSameType = true;
    String? elementType;

    if (selectedCount > 0) {
      elementType = state.selectedTiles.first.type?.id;
      allSameType = state.selectedTiles.every((tile) => tile.type?.id == elementType);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFF333333),
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
          // Mostrar información sobre la selección
          if (selectedCount > 0 && allSameType)
            Row(
              children: [
                Icon(
                  state.selectedTiles.first.type?.icon ?? Icons.help_outline,
                  color: state.selectedTiles.first.type?.color ?? Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tipo: ${state.selectedTiles.first.type?.name ?? "Desconocido"}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),

          if (selectedCount > 0 && !allSameType)
            const Text(
              'La selección contiene diferentes tipos de elementos',
              style: TextStyle(color: Colors.red),
            ),

          const SizedBox(height: 16),

          // Botones de acción para selección múltiple
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.merge_type),
                label: const Text('Fusionar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: allSameType && selectedCount > 1
                      ? Color(0xFF00BFA5)
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: allSameType && selectedCount > 1
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context,
      String mode,
      IconData icon,
      String label,
      bool isSelected,
      ) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Color(0xFF00BFA5) : Color(0xFF4D4D4D),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        context.read<ZoneEditorBloc>().add(EditModeChanged(mode));
      },
    );
  }

  Widget _buildPropertiesPanel(BuildContext context, ZoneEditorLoaded state) {
    if (state.selectedTile == null || state.selectedTile!.type == null) {
      return const SizedBox.shrink();
    }

    final tile = state.selectedTile!;
    final elementType = tile.type!;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFF333333),
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
            children: [
              Icon(elementType.icon, color: elementType.color),
              const SizedBox(width: 8.0),
              Text(
                elementType.name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(
                    TileSelected(Tile(x: -1, y: -1)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            'Posición: (${tile.x}, ${tile.y})',
            style: TextStyle(color: Colors.white70),
          ),
          Row(
            children: [
              const Text(
                'Rotation:',
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.rotate_left, color: Colors.white),
                tooltip: 'Rotar izquierda',
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(
                    RotateSelectedElement(false),
                  );
                },
              ),
              Text(
                '${tile.rotation}°',
                style: TextStyle(color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                tooltip: 'Rotar derecha',
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(
                    RotateSelectedElement(true),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
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
              backgroundColor: Color(0xFF00BFA5),
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