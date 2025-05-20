import 'package:equatable/equatable.dart';
import 'package:table_game/models/board_components/tile.dart';
import 'package:table_game/models/board_config.dart';

import 'element_type.dart';

class Board extends Equatable {
  final BoardConfig config;
  final List<Tile> tiles;
  final int _elementCounter;

  const Board({
    required this.config,
    required this.tiles,
    int elementCounter = 0,
  }) : _elementCounter = elementCounter;

  factory Board.empty(BoardConfig config) {
    final List<Tile> tiles = [];
    for (int y = 0; y < config.rows; y++) {
      for (int x = 0; x < config.columns; x++) {
        tiles.add(Tile(x: x, y: y));
      }
    }
    return Board(config: config, tiles: tiles);
  }

  Tile? getTile(int x, int y) {
    if (x < 0 || x >= config.columns || y < 0 || y >= config.rows) {
      return null;
    }
    return tiles.firstWhere((tile) => tile.x == x && tile.y == y);
  }

  Board updateTile(Tile tile) {
    final List<Tile> updatedTiles = List.from(tiles);

    final index = tiles.indexWhere((tile) => tile.x == tile.x && tile.y == tile.y);

    if (index != -1) {
      updatedTiles[index] = tile;
    }
    return Board(config: config, tiles: updatedTiles);
  }

  bool canPlaceElement(int x, int y, ElementType elementType) {
    final width = elementType.defaultSize.width.toInt();
    final height = elementType.defaultSize.height.toInt();

    if (x < 0 || x + width > config.columns || y < 0 || y + height > config.rows) {
      return false;
    }

    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final tile = getTile(x + dx, y + dy);
        if (tile != null || tile!.isNotEmpty) {
          return false;
        }
      }
    }

    return true;
  }

  String _generateElementId() {
    return 'elem_${_elementCounter + 1}';
  }

  Board placeElement(int x, int y, ElementType elementType) {
    //en un futuro hay que devolver un error donde indique que no se puede colocar la pieza en esta posición
    if (!canPlaceElement(x, y, elementType)) {
      return this;
    }

    final elementId = _generateElementId();

    final width = elementType.defaultSize.width.toInt();
    final height = elementType.defaultSize.height.toInt();

    Board updatedBoard = Board(
      config: config,
      tiles: tiles,
      elementCounter: _elementCounter + 1,
    );

    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final tile = updatedBoard.getTile(dx, dy);
        if (tile != null) {
          final newTile = tile.copyWith(
            type: elementType,
            elementId: elementId,
            properties: elementType.properties,
          );
          updatedBoard = updatedBoard.updateTile(newTile);
        }
      }
    }

    return updatedBoard;
  }

  Board removeElement(int x, int y) {
    final tile = getTile(x, y);

    if (tile == null || tile.isEmpty || tile.elementId == null) {
      return this;
    }

    final elementId = tile.elementId!;

    Board updatedBoard = this;

    tiles.where((t) => t.elementId == elementId).forEach((t) {
      updatedBoard = updatedBoard.updateTile(t.empty());
    });

    return updatedBoard;
  }

  Board clear() {
    return Board.empty(config);
  }

  @override
  List<Object?> get props => [config, tiles, _elementCounter];
}
