import 'package:flutter/material.dart';
import 'package:table_game/models/board_components/board.dart';
import 'package:table_game/models/board_components/element_type.dart';

class PlacementOverlay extends StatelessWidget {
  final ElementType elementType;
  final double tileSize;
  final Offset localMousePosition;
  final Board board;

  const PlacementOverlay({
    super.key,
    required this.elementType,
    required this.tileSize,
    required this.localMousePosition,
    required this.board,
  });

  @override
  Widget build(BuildContext context) {
    double width = elementType.defaultSize.width * tileSize;
    double height = elementType.defaultSize.height * tileSize;

    final alignedX = (localMousePosition.dx / tileSize).floor();
    final alignedY = (localMousePosition.dy / tileSize).floor();

    final canPlace = board.canPlaceElement(alignedX, alignedY, elementType);

    return Positioned(
      left: alignedX * tileSize,
      top: alignedY * tileSize,
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
