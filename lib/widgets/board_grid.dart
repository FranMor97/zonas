
import 'package:flutter/material.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/board.dart';
import 'package:table_game/models/board_components/element_type.dart';
import 'package:table_game/models/board_components/tile.dart';

class BoardGrid extends StatefulWidget {
  final Board board;
  final Function(int x, int y) onTileTap;
  final Function(int x, int y)? onTileDrag;
  final Function(int x, int y)? onEraseDrag;
  final Function()? onDragEnd;
  final Tile? selectedTile;
  final bool showCoordinates;
  final String mode;
  final ElementType? selectedElement;
  final VoidCallback? onRightClick;
  final List<Tile> selectedTiles;
  final bool isMultiSelectMode;
  // Nuevo parámetro para el estado completo
  final ZoneEditorLoaded? editorState;

  const BoardGrid({
    Key? key,
    required this.board,
    required this.onTileTap,
    required this.mode,
    this.onTileDrag,
    this.selectedTile,
    this.onEraseDrag,
    this.onDragEnd,
    this.showCoordinates = false,
    this.selectedElement,
    this.onRightClick,
    this.selectedTiles = const [],
    this.isMultiSelectMode = false,
    this.editorState,
  }) : super(key: key);

  @override
  State<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<BoardGrid> {
  Offset? _localMousePosition;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final double boardWidth = widget.board.config.columns * widget.board.config.tileSize;
    final double boardHeight = widget.board.config.rows * widget.board.config.tileSize;

    final showOverlay = widget.mode == 'place' &&
        widget.selectedElement != null &&
        !widget.selectedElement!.isSelectionTool &&
        _isHovering &&
        _localMousePosition != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() {
        _isHovering = false;
        _localMousePosition = null;
      }),
      onHover: (event) {
        setState(() {
          _localMousePosition = event.localPosition;
        });
      },
      child: GestureDetector(
        onSecondaryTap: widget.onRightClick,
        child: Container(
          width: boardWidth,
          height: boardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Cuadrícula de fondo
              CustomPaint(
                size: Size(boardWidth, boardHeight),
                painter: _GridPainter(
                  columns: widget.board.config.columns,
                  rows: widget.board.config.rows,
                  cellSize: widget.board.config.tileSize,
                ),
              ),

              // Celdas del tablero
              ...widget.board.tiles.map((tile) => _buildTileWidget(context, tile)),

              // Contornos de selección mejorados
              ..._buildSelectionOverlays(),

              // Overlay del elemento a colocar
              if (showOverlay) _buildPlacementOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // Método mejorado para construir overlays de selección
  List<Widget> _buildSelectionOverlays() {
    List<Widget> overlays = [];

    if (widget.editorState != null) {
      final state = widget.editorState!;

      // Selección individual con soporte para elementos fusionados
      if (state.hasSelectedTile && state.selectedTile != null && !state.isMultiSelectMode) {
        final selectedTile = state.selectedTile!;

        if (selectedTile.isMerged && selectedTile.mergedGroupId != null) {
          // Mostrar selección para todo el grupo fusionado
          final groupTiles = state.getMergedElementTiles(selectedTile.mergedGroupId!);
          for (final tile in groupTiles) {
            overlays.add(_buildSelectionOverlay(tile, Colors.blue, isMergedGroup: true));
          }
        } else {
          // Selección individual normal
          overlays.add(_buildSelectionOverlay(selectedTile, Colors.blue));
        }
      }

      // Selección múltiple
      if (state.isMultiSelectMode && state.selectedTiles.isNotEmpty) {
        // Agrupar tiles por grupos fusionados
        Map<String, List<Tile>> mergedGroups = {};
        List<Tile> individualTiles = [];

        for (final tile in state.selectedTiles) {
          if (tile.isMerged && tile.mergedGroupId != null) {
            if (!mergedGroups.containsKey(tile.mergedGroupId)) {
              mergedGroups[tile.mergedGroupId!] = [];
            }
            mergedGroups[tile.mergedGroupId!]!.add(tile);
          } else {
            individualTiles.add(tile);
          }
        }

        // Overlays para grupos fusionados
        for (final group in mergedGroups.values) {
          for (final tile in group) {
            overlays.add(_buildSelectionOverlay(
              tile,
              Colors.lightBlue,
              isMergedGroup: true,
              isMultiSelect: true,
            ));
          }
        }

        // Overlays para tiles individuales
        for (final tile in individualTiles) {
          overlays.add(_buildSelectionOverlay(
            tile,
            Colors.lightBlue,
            isMultiSelect: true,
          ));
        }
      }
    }

    return overlays;
  }

  Widget _buildSelectionOverlay(
      Tile tile,
      Color color, {
        bool isMergedGroup = false,
        bool isMultiSelect = false,
      }) {
    return Positioned(
      left: (tile.x * widget.board.config.tileSize).toDouble(),
      top: (tile.y * widget.board.config.tileSize).toDouble(),
      width: widget.board.config.tileSize,
      height: widget.board.config.tileSize,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: isMergedGroup ? 3 : 2,
          ),
          color: isMultiSelect
              ? color.withOpacity(0.2)
              : Colors.transparent,
        ),
        child: isMergedGroup ? Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
          ),
          child: Center(
            child: Icon(
              Icons.link,
              color: color,
              size: 12,
            ),
          ),
        ) : null,
      ),
    );
  }

  Widget _buildTileWidget(BuildContext context, Tile tile) {
    final double x = (tile.x * widget.board.config.tileSize).toDouble();
    final double y = (tile.y * widget.board.config.tileSize).toDouble();
    final double size = widget.board.config.tileSize;

    return Positioned(
      left: x,
      top: y,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => widget.onTileTap(tile.x, tile.y),
        onSecondaryTap: widget.onRightClick,
        onPanUpdate: widget.onTileDrag != null
            ? (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localOffset = renderBox.globalToLocal(details.globalPosition);

          final int gridX = (localOffset.dx / widget.board.config.tileSize).floor();
          final int gridY = (localOffset.dy / widget.board.config.tileSize).floor();

          if (gridX >= 0 &&
              gridX < widget.board.config.columns &&
              gridY >= 0 &&
              gridY < widget.board.config.rows) {
            if (widget.mode == 'erase' && widget.onEraseDrag != null) {
              widget.onEraseDrag!(gridX, gridY);
            } else if (widget.onTileDrag != null) {
              widget.onTileDrag!(gridX, gridY);
            }
          }
        }
            : null,
        onPanEnd: widget.onDragEnd != null ? (details) => widget.onDragEnd!() : null,
        child: _TileContent(
          tile: tile,
          size: size,
          showCoordinates: widget.showCoordinates,
          allTiles: widget.board.tiles,
          editorState: widget.editorState,
        ),
      ),
    );
  }

  Widget _buildPlacementOverlay() {
    final elementType = widget.selectedElement!;
    final tileSize = widget.board.config.tileSize;

    double width = elementType.defaultSize.width * tileSize;
    double height = elementType.defaultSize.height * tileSize;

    final gridX = (_localMousePosition!.dx / tileSize).floor();
    final gridY = (_localMousePosition!.dy / tileSize).floor();

    final alignedX = gridX * tileSize;
    final alignedY = gridY * tileSize;

    final canPlace = widget.board.canPlaceElement(gridX, gridY, elementType);

    return Positioned(
      left: alignedX.toDouble(),
      top: alignedY.toDouble(),
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: elementType.color.withOpacity(canPlace ? 0.7 : 0.3),
              border: Border.all(
                color: canPlace ? Colors.white : Colors.red,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Icon(
                elementType.icon,
                color: Colors.white,
                size: (width < height ? width : height) * 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Tile content mejorado
class _TileContent extends StatelessWidget {
  final Tile tile;
  final double size;
  final bool showCoordinates;
  final List<Tile> allTiles;
  final ZoneEditorLoaded? editorState;

  const _TileContent({
    required this.tile,
    required this.size,
    required this.showCoordinates,
    required this.allTiles,
    this.editorState,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMerged = tile.getProperty<bool>('isMerged', false);
    final String mergedGroupId = tile.getProperty<String>('mergedGroupId', '');

    Border? tileBorder = _calculateTileBorder(isMerged, mergedGroupId);

    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(),
        border: tileBorder,
      ),
      child: Stack(
        children: [
          // Elemento principal
          if (tile.type != null)
            Center(
              child: Transform.rotate(
                angle: tile.rotation * (3.1415926535 / 180),
                child: Icon(
                  tile.type!.icon,
                  color: Colors.white,
                  size: size * 0.7,
                ),
              ),
            ),

          // Indicador de fusión
          if (isMerged)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.link,
                  size: 6,
                  color: tile.type?.color ?? Colors.grey,
                ),
              ),
            ),

          // Coordenadas para debugging
          if (showCoordinates)
            Positioned(
              left: 2,
              top: 2,
              child: Text(
                '${tile.x},${tile.y}',
                style: TextStyle(
                  fontSize: 8,
                  color: tile.isNotEmpty ? Colors.white : Colors.black54,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Border? _calculateTileBorder(bool isMerged, String mergedGroupId) {
    if (!isMerged) {
      return Border.all(
        color: Colors.grey.shade300,
        width: 0.5,
      );
    }

    // Para elementos fusionados, calcular bordes basados en vecinos
    bool hasTopNeighbor = false;
    bool hasBottomNeighbor = false;
    bool hasLeftNeighbor = false;
    bool hasRightNeighbor = false;

    for (final neighbor in allTiles) {
      final neighborMergedId = neighbor.getProperty<String>('mergedGroupId', '');
      if (neighborMergedId == mergedGroupId && neighborMergedId.isNotEmpty) {
        // Verificar posiciones adyacentes
        if (neighbor.x == tile.x && neighbor.y == tile.y - 1) {
          hasTopNeighbor = true;
        } else if (neighbor.x == tile.x + 1 && neighbor.y == tile.y) {
          hasRightNeighbor = true;
        } else if (neighbor.x == tile.x && neighbor.y == tile.y + 1) {
          hasBottomNeighbor = true;
        } else if (neighbor.x == tile.x - 1 && neighbor.y == tile.y) {
          hasLeftNeighbor = true;
        }
      }
    }

    return Border(
      top: hasTopNeighbor
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 0.5),
      right: hasRightNeighbor
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 0.5),
      bottom: hasBottomNeighbor
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 0.5),
      left: hasLeftNeighbor
          ? BorderSide.none
          : BorderSide(color: Colors.grey.shade300, width: 0.5),
    );
  }

  Color _getTileColor() {
    if (tile.isNotEmpty && tile.type != null) {
      return tile.type!.color;
    }
    return Colors.transparent;
  }
}

// Grid painter (sin cambios)
class _GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellSize;

  _GridPainter({
    required this.columns,
    required this.rows,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    // Dibujar líneas verticales
    for (int i = 0; i <= columns; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Dibujar líneas horizontales
    for (int i = 0; i <= rows; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}