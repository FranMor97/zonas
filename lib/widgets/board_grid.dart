// lib/widgets/board_grid.dart
import 'package:flutter/material.dart';
import '../models/board_components/board.dart';
import '../models/board_components/tile.dart';

/// Widget que muestra el tablero de juego como una cuadrícula interactiva.
class BoardGrid extends StatelessWidget {
  /// El tablero a mostrar
  final Board board;

  /// Callback cuando se hace tap en una celda
  final Function(int x, int y) onTileTap;

  /// Callback cuando se arrastra sobre una celda
  final Function(int x, int y)? onTileDrag;

  /// La celda actualmente seleccionada (si hay)
  final Tile? selectedTile;

  /// Si es true, muestra coordenadas en cada celda (útil para debugging)
  final bool showCoordinates;

  const BoardGrid({
    Key? key,
    required this.board,
    required this.onTileTap,
    this.onTileDrag,
    this.selectedTile,
    this.showCoordinates = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular dimensiones totales del tablero
    final double boardWidth = board.config.columns * board.config.tileSize;
    final double boardHeight = board.config.rows * board.config.tileSize;

    return Container(
      width: boardWidth,
      height: boardHeight,
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco para el tablero
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Stack(
        children: [
          // Cuadrícula de fondo
          CustomPaint(
            size: Size(boardWidth, boardHeight),
            painter: _GridPainter(
              columns: board.config.columns,
              rows: board.config.rows,
              cellSize: board.config.tileSize,
            ),
          ),

          // Celdas del tablero
          ...board.tiles.map((tile) => _buildTileWidget(context, tile)),

          // Contorno de selección para el tile seleccionado
          if (selectedTile != null)
            Positioned(
              left: (selectedTile!.x * board.config.tileSize).toDouble(),
              top: (selectedTile!.y * board.config.tileSize).toDouble(),
              width: board.config.tileSize,
              height: board.config.tileSize,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTileWidget(BuildContext context, Tile tile) {
    // Posición del tile en pixels
    final double x = (tile.x * board.config.tileSize).toDouble();
    final double y = (tile.y * board.config.tileSize).toDouble();

    // Tamaño de la celda
    final double size = board.config.tileSize;

    // Widget base (detector de gestos)
    return Positioned(
      left: x,
      top: y,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => onTileTap(tile.x, tile.y),
        onPanUpdate: onTileDrag != null
            ? (details) {
          // Calculamos la celda sobre la que estamos arrastrando
          // Convertir la posición global a la posición dentro del tablero
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localOffset = renderBox.globalToLocal(details.globalPosition);

          // Calcular la posición de la celda
          final int gridX = (localOffset.dx / board.config.tileSize).floor();
          final int gridY = (localOffset.dy / board.config.tileSize).floor();

          // Verificar que estamos dentro del tablero
          if (gridX >= 0 && gridX < board.config.columns &&
              gridY >= 0 && gridY < board.config.rows) {
            onTileDrag!(gridX, gridY);
          }
        }
            : null,
        child: _TileContent(
          tile: tile,
          size: size,
          showCoordinates: showCoordinates,
        ),
      ),
    );
  }
}

/// Widget que muestra el contenido de una celda
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
                angle: tile.rotation * (3.1415926535 / 180), // Convertir grados a radianes
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

  // Determina el color de fondo de la celda
  Color _getTileColor() {
    if (tile.isNotEmpty && tile.type != null) {
      // Usar el color del tipo de elemento
      return tile.type!.color;
    }

    // Celda vacía - color por defecto
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