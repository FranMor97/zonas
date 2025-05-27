import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:table_game/models/board_components/tile.dart';
import 'package:table_game/models/board_config.dart';

import 'element_type.dart';

class Board extends Equatable {
  final BoardConfig config;
  final List<Tile> tiles;
  final int _elementCounter;
  static int _uniqueCounter = 0;
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

    final index = tiles.indexWhere((t) => t.x == tile.x && t.y == tile.y);

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

  Board rotateElement(
      String elementId,
      bool clockwise,
      ) {
    // 1. Encontrar todas las celdas que pertenecen al elemento
    final elementTiles = tiles.where((tile) => tile.elementId == elementId).toList();
    if (elementTiles.isEmpty) {
      return this; // El elemento no existe
    }

    // 2. Encontrar el tile de origen
    final originTile = elementTiles.firstWhere(
          (tile) => tile.isOrigin,
      orElse: () => elementTiles.first,
    );

    // 3. Calcular la nueva rotación
    final currentRotation = originTile.rotation;
    final newRotation = (currentRotation + (clockwise ? 90 : -90)) % 360;

    // 4. Crear una matriz temporal sin el elemento actual
    Board tempBoard = this;
    for (final tile in elementTiles) {
      tempBoard = tempBoard.updateTile(tile.empty());
    }

    // 5. Calcular las nuevas posiciones después de rotar
    List<Point<int>> newPositions = [];
    int originX = originTile.x;
    int originY = originTile.y;

    for (final tile in elementTiles) {
      // Posición relativa al origen
      int relX = tile.x - originX;
      int relY = tile.y - originY;

      // Aplicar rotación
      int newRelX, newRelY;
      if (clockwise) {
        // Rotación 90° horaria: (x,y) -> (-y,x)
        newRelX = -relY;
        newRelY = relX;
      } else {
        // Rotación 90° antihoraria: (x,y) -> (y,-x)
        newRelX = relY;
        newRelY = -relX;
      }

      // Calcular nueva posición absoluta
      int newX = originX + newRelX;
      int newY = originY + newRelY;
      newPositions.add(Point(newX, newY));
    }

    // 6. Verificar si es posible colocar el elemento rotado
    for (var point in newPositions) {
      // Verificar límites del tablero
      if (point.x < 0 || point.x >= config.columns ||
          point.y < 0 || point.y >= config.rows) {
        return this; // Fuera de los límites
      }

      // Verificar colisiones
      final tile = tempBoard.getTile(point.x, point.y);
      if (tile == null || tile.isNotEmpty) {
        return this; // Colisión detectada
      }
    }

    // 7. Colocar el elemento rotado
    Board updatedBoard = tempBoard;

    // Propiedades adicionales a preservar
    Map<String, dynamic> additionalProps = {};
    for (final prop in originTile.properties!.entries) {
      if (!['rotation', 'isOrigin', 'elementX', 'elementY', 'originX', 'originY'].contains(prop.key)) {
        additionalProps[prop.key] = prop.value;
      }
    }

    // Encontrar el nuevo origen (el que estaba más cerca del origen anterior)
    final newOriginPoint = newPositions.reduce((a, b) {
      final distA = (a.x - originX).abs() + (a.y - originY).abs();
      final distB = (b.x - originX).abs() + (b.y - originY).abs();
      return distA <= distB ? a : b;
    });

    for (var point in newPositions) {
      final tile = tempBoard.getTile(point.x, point.y);
      if (tile != null) {
        final isNewOrigin = (point.x == newOriginPoint.x && point.y == newOriginPoint.y);

        final updatedTile = tile.asPartOfElement(
          elementType: originTile.type!,
          elementId: elementId,
          originX: newOriginPoint.x,
          originY: newOriginPoint.y,
          rotation: newRotation,
          additionalProperties: {
            ...additionalProps,
            'isOrigin': isNewOrigin,
          },
        );

        updatedBoard = updatedBoard.updateTile(updatedTile);
      }
    }

    return updatedBoard;
  }

  Board placeElement(
      int x,
      int y,
      ElementType elementType,
      {
        Map<String, dynamic>? properties,
        String? elementId,
        int rotation = 0,
      }
      ) {
    // Obtener dimensiones del elemento considerando rotación
    int width = elementType.defaultSize.width.toInt();
    int height = elementType.defaultSize.height.toInt();

    // Si la rotación es 90° o 270°, intercambiar ancho y alto
    if (rotation == 90 || rotation == 270) {
      final temp = width;
      width = height;
      height = temp;
    }

    // Verificar si podemos colocar el elemento con estos parámetros
    if (!canPlaceElementWithSize(x, y, width, height)) {
      return this; // No se puede colocar, retornar el mismo tablero
    }

    // Generar un ID único para este elemento si no se proporcionó
    final String actualElementId = elementId ?? 'elem_${DateTime.now().millisecondsSinceEpoch}_${_uniqueCounter++}';

    // Crear una copia del tablero actual
    Board updatedBoard = this;

    // Colocar el elemento en todas las celdas que ocupa
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final tile = getTile(x + dx, y + dy);
        if (tile != null) {
          // Crear tile como parte del elemento con propiedades estándar
          final newTile = tile.asPartOfElement(
            elementType: elementType,
            elementId: actualElementId,
            originX: x,
            originY: y,
            rotation: rotation,
            additionalProperties: properties,
          );

          updatedBoard = updatedBoard.updateTile(newTile);
        }
      }
    }

    return updatedBoard;
  }

  /// Verifica si un elemento de tamaño específico puede ser colocado.
  bool canPlaceElementWithSize(int x, int y, int width, int height) {
    // Verificar si está dentro de los límites del tablero
    if (x < 0 || x + width > config.columns || y < 0 || y + height > config.rows) {
      return false;
    }

    // Verificar colisiones con otros elementos
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final tile = getTile(x + dx, y + dy);
        if (tile == null || tile.isNotEmpty) {
          return false; // Colisión detectada
        }
      }
    }

    return true; // No hay colisiones
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
