// lib/widgets/element_palette.dart
import 'package:flutter/material.dart';
import 'package:table_game/models/board_components/element_type.dart';

class ElementPalette extends StatelessWidget {
  final List<ElementType> elements;

  final ElementType? selectedElement;

  final bool eraserMode;

  final Function(ElementType) onElementSelected;

  final Function(bool) onEraserToggled;

  const ElementPalette({
    Key? key,
    required this.elements,
    this.selectedElement,
    required this.eraserMode,
    required this.onElementSelected,
    required this.onEraserToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF333333), // Fondo oscuro para la paleta
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título de la paleta
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                'Elementos disponibles',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Elementos en un ListView horizontal
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Borrador
                  _buildElementItem(
                    context,
                    null,
                    isEraser: true,
                    isSelected: eraserMode,
                  ),
                  // Separador
                  const SizedBox(width: 4),
                  Container(
                    width: 1,
                    color: Colors.grey.shade700, // Divisor más oscuro
                  ),
                  const SizedBox(width: 4),
                  // Elementos disponibles
                  ...elements.map((element) => _buildElementItem(
                    context,
                    element,
                    isSelected: !eraserMode && selectedElement?.id == element.id,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementItem(
      BuildContext context,
      ElementType? element, {
        bool isEraser = false,
        bool isSelected = false,
      }) {
    final Color itemColor = isEraser
        ? Colors.red.shade400
        : element?.color ?? Colors.grey;

    final String itemText = isEraser
        ? 'Borrador'
        : element?.name ?? 'Desconocido';

    final IconData itemIcon = isEraser
        ? Icons.delete_outline
        : element?.icon ?? Icons.help_outline;

    String sizeText = '';
    if (!isEraser && element != null) {
      final Size size = element.defaultSize;
      if (size.width != 1 || size.height != 1) {
        sizeText = '${size.width.toInt()}×${size.height.toInt()}';
      }
    }

    return GestureDetector(
      onTap: () {
        if (isEraser) {
          onEraserToggled(true);
        } else if (element != null) {
          onElementSelected(element);
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E88E5) // Azul seleccionado
              : const Color(0xFF424242), // Gris oscuro para los items
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.grey.shade700,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Icon(
              itemIcon,
              color: itemColor,
              size: 36,
            ),
            const SizedBox(height: 4),
            // Nombre del elemento
            Text(
              itemText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Tamaño (si aplica)
            if (sizeText.isNotEmpty)
              Text(
                sizeText,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}