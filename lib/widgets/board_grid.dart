// lib/widgets/board_grid.dart
import 'package:flutter/material.dart';
import '../models/board_components/board.dart';
import '../models/board_components/tile.dart';
import '../models/board_components/element_type.dart';

/// Widget que muestra el tablero de juego como una cuadrícula interactiva.
class BoardGrid extends StatefulWidget {
  /// El tablero a mostrar
  final Board board;

  /// Callback cuando se hace tap en una celda
  final Function(int x, int y) onTileTap;

  /// Callback cuando se arrastra sobre una celda
  final Function(int x, int y)? onTileDrag;

  final Function(int x, int y)? onEraseDrag;

  final Function()? onDragEnd;

  /// La celda actualmente seleccionada (si hay)
  final Tile? selectedTile;

  /// Si es true, muestra coordenadas en cada celda (útil para debugging)
  final bool showCoordinates;

  /// Modo actual del editor
  final String mode;

  /// Elemento seleccionado para colocar
  final ElementType? selectedElement;

  /// Callback cuando se hace clic derecho
  final VoidCallback? onRightClick;

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
  }) : super(key: key);

  @override
  State<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<BoardGrid> {
  Offset? _localMousePosition;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Calcular dimensiones totales del tablero
    final double boardWidth = widget.board.config.columns * widget.board.config.tileSize;
    final double boardHeight = widget.board.config.rows * widget.board.config.tileSize;

    // Determinar si mostrar el overlay
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

              // Contorno de selección para el tile seleccionado
              if (widget.selectedTile != null && widget.selectedTile!.isNotEmpty)
                Positioned(
                  left: (widget.selectedTile!.x * widget.board.config.tileSize).toDouble(),
                  top: (widget.selectedTile!.y * widget.board.config.tileSize).toDouble(),
                  width: widget.board.config.tileSize,
                  height: widget.board.config.tileSize,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                  ),
                ),

              // Overlay del elemento a colocar
              if (showOverlay)
                _buildPlacementOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementOverlay() {
    final elementType = widget.selectedElement!;
    final tileSize = widget.board.config.tileSize;

    // Calcular el tamaño del elemento
    double width = elementType.defaultSize.width * tileSize;
    double height = elementType.defaultSize.height * tileSize;

    // Calcular la posición ajustada a la grilla
    final gridX = (_localMousePosition!.dx / tileSize).floor();
    final gridY = (_localMousePosition!.dy / tileSize).floor();

    // Posición en píxeles alineada a la grilla
    final alignedX = gridX * tileSize;
    final alignedY = gridY * tileSize;

    // Verificar si la posición es válida
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

  Widget _buildTileWidget(BuildContext context, Tile tile) {
    // Posición del tile en pixels
    final double x = (tile.x * widget.board.config.tileSize).toDouble();
    final double y = (tile.y * widget.board.config.tileSize).toDouble();

    // Tamaño de la celda
    final double size = widget.board.config.tileSize;

    // Widget base (detector de gestos)
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
          // Calculamos la celda sobre la que estamos arrastrando
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localOffset = renderBox.globalToLocal(details.globalPosition);

          // Calcular la posición de la celda
          final int gridX = (localOffset.dx / widget.board.config.tileSize).floor();
          final int gridY = (localOffset.dy / widget.board.config.tileSize).floor();

          // Verificar que estamos dentro del tablero
          if (gridX >= 0 && gridX < widget.board.config.columns &&
              gridY >= 0 && gridY < widget.board.config.rows) {
            if(widget.mode == 'erase' && widget.onEraseDrag != null){
              widget.onEraseDrag!(gridX, gridY);
            }else if(widget.onTileDrag != null){
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
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  final Tile tile;
  final double size;
  final bool showCoordinates;

  const _TileContent({
    required this.tile,
    required this.size,
    required this.showCoordinates,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getTileColor(),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // Si la celda tiene un elemento, mostrarlo
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

  Color _getTileColor() {
    if (tile.isNotEmpty && tile.type != null) {
      return tile.type!.color;
    }
    return Colors.transparent;
  }
}

/// Painter que dibuja la cuadrícula del tablero
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