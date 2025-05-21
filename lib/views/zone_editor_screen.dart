// lib/screens/zone_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        if (state is ZoneEditorError) {
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
            backgroundColor: Color(0xFF212121), // Fondo oscuro
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ZoneEditorError) {
          // Mostrar un mensaje de error pero permitir reintentar
          return Scaffold(
            backgroundColor: Color(0xFF212121), // Fondo oscuro
            appBar: AppBar(
              title: const Text('Editor de Zonas'),
              backgroundColor: Color(0xFF333333), // Barra oscura
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
                      backgroundColor: Color(0xFF00BFA5), // Verde azulado
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
          // Estado inicial
          return const Scaffold(
            backgroundColor: Color(0xFF212121), // Fondo oscuro
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
      backgroundColor: Color(0xFF212121), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: Color(0xFF333333), // Barra oscura
        title: Text('Editor - ${state.board.config.name}'),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón de deshacer
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Deshacer',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(UndoLastAction());
            },
          ),
          // Botón de rehacer
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Rehacer',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(RedoLastAction());
            },
          ),
          // Botón para limpiar el tablero
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Limpiar tablero',
            onPressed: () {
              _showConfirmationDialog(
                context,
                'Limpiar tablero',
                '¿Estás seguro de que deseas limpiar todo el tablero?',
                    () {
                  context.read<ZoneEditorBloc>().add(BoardCleared());
                },
              );
            },
          ),
          // Botón para guardar
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
            onPressed: () {
              context.read<ZoneEditorBloc>().add(SaveCurrentBoard());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Paleta de elementos disponibles
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Color(0xFF333333), // Fondo oscuro para la paleta
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

          // Barra de modo actual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Color(0xFF333333), // Barra oscura
            child: Row(
              children: [
                Icon(
                  state.eraserMode
                      ? Icons.delete_outline
                      : state.selectedElement?.icon ?? Icons.touch_app,
                  color: state.eraserMode
                      ? Colors.red
                      : state.selectedElement?.color ?? Colors.white70,
                ),
                const SizedBox(width: 8.0),
                Text(
                  state.eraserMode
                      ? 'Modo borrador'
                      : state.selectedElement != null
                      ? 'Elemento: ${state.selectedElement!.name}'
                      : 'Selecciona un elemento',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Botones de modo - usando botones individuales
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

          // Tablero principal (grid)
          Expanded(
            child: Container(
              color: Color(0xFF1A1A1A), // Fondo más oscuro para el área del tablero
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
                        selectedTile: state.selectedTile,
                        showCoordinates: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // Panel de propiedades cuando hay un elemento seleccionado
      bottomSheet: state.hasSelectedTile && state.editMode == 'select'
          ? _buildPropertiesPanel(context, state)
          : null,
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
        color: Color(0xFF333333), // Panel oscuro
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
          // Título del panel
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
              // Botón para cerrar el panel
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(
                    TileSelected(Tile(x: -1, y: -1)), // Deseleccionar
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Información de posición
          Text(
            'Posición: (${tile.x}, ${tile.y})',
            style: TextStyle(color: Colors.white70),
          ),

          // Rotación
          Row(
            children: [
              Text(
                'Rotación:',
                style: TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.rotate_left, color: Colors.white),
                tooltip: 'Rotar izquierda',
                onPressed: () {
                  context.read<ZoneEditorBloc>().add(
                    RotateSelectedElement( false),
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
                    RotateSelectedElement( true),
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
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF333333),
        title: Text(title, style: TextStyle(color: Colors.white)),
        content: Text(message, style: TextStyle(color: Colors.white70)),
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