import 'package:flutter/material.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/tile.dart';

class TileContent extends StatelessWidget {
  final Tile tile;
  final double size;
  final bool showCoordinates;
  final List<Tile> allTiles;
  final ZoneEditorLoaded? editorState;

  const TileContent({
    super.key,
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
      top: hasTopNeighbor ? BorderSide.none : BorderSide(color: Colors.grey.shade300, width: 0.5),
      right:
          hasRightNeighbor ? BorderSide.none : BorderSide(color: Colors.grey.shade300, width: 0.5),
      bottom:
          hasBottomNeighbor ? BorderSide.none : BorderSide(color: Colors.grey.shade300, width: 0.5),
      left: hasLeftNeighbor ? BorderSide.none : BorderSide(color: Colors.grey.shade300, width: 0.5),
    );
  }

  Color _getTileColor() {
    if (tile.isNotEmpty && tile.type != null) {
      return tile.type!.color;
    }
    return Colors.transparent;
  }
}
