// lib/widgets/draggable_element_overlay.dart
import 'package:flutter/material.dart';
import '../models/board_components/tile.dart';
import '../models/board_components/element_type.dart';

class DraggableElementOverlay extends StatelessWidget {
  final Tile? selectedTile;
  final double tileSize;
  final Offset? cursorPosition;
  final bool isVisible;

  const DraggableElementOverlay({
    Key? key,
    required this.selectedTile,
    required this.tileSize,
    required this.cursorPosition,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || selectedTile == null || cursorPosition == null || selectedTile!.type == null) {
      return const SizedBox.shrink();
    }

    final elementType = selectedTile!.type!;
    final rotation = selectedTile!.rotation;

    // Calcular el tamaño del elemento considerando la rotación
    double width = elementType.defaultSize.width * tileSize;
    double height = elementType.defaultSize.height * tileSize;

    if (rotation == 90 || rotation == 270) {
      final temp = width;
      width = height;
      height = temp;
    }

    return Positioned(
      left: cursorPosition!.dx - (width / 2),
      top: cursorPosition!.dy - (height / 2) - 20,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: elementType.color.withOpacity(0.7),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation * (3.1415926535 / 180),
                child: Icon(
                  elementType.icon,
                  color: Colors.white,
                  size: (width < height ? width : height) * 0.6,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}