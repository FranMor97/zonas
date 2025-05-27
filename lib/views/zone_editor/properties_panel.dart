import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/tile.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
      final state = context.watch<ZoneEditorBloc>().state as ZoneEditorLoaded;
      if (state.selectedTile == null || state.selectedTile!.type == null) {
        return const SizedBox.shrink();
      }
      final tile = state.selectedTile!;
      final elementType = tile.type!;
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
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
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    context.read<ZoneEditorBloc>().add(
                      const TileSelected(Tile(x: -1, y: -1)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Text(
              'Posición: (${tile.x}, ${tile.y})',
              style: const TextStyle(color: Colors.white70),
            ),
            Row(
              children: [
                const Text(
                  'Rotation:',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.rotate_left, color: Colors.white),
                  tooltip: 'Rotar izquierda',
                  onPressed: () {
                    context.read<ZoneEditorBloc>().add(
                      const RotateSelectedElement(false),
                    );
                  },
                ),
                Text(
                  '${tile.rotation}°',
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_right, color: Colors.white),
                  tooltip: 'Rotar derecha',
                  onPressed: () {
                    context.read<ZoneEditorBloc>().add(
                      const RotateSelectedElement(true),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
  }












// Widget _buildPropertiesPanel(BuildContext context, ZoneEditorLoaded state) {
//   if (state.selectedTile == null || state.selectedTile!.type == null) {
//     return const SizedBox.shrink();
//   }
//
//   final tile = state.selectedTile!;
//   final elementType = tile.type!;
//
//   return Container(
//     padding: const EdgeInsets.all(16.0),
//     decoration: BoxDecoration(
//       color: const Color(0xFF333333),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withOpacity(0.3),
//           blurRadius: 4.0,
//           offset: const Offset(0, -2),
//         ),
//       ],
//     ),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(elementType.icon, color: elementType.color),
//             const SizedBox(width: 8.0),
//             Text(
//               elementType.name,
//               style: const TextStyle(
//                 fontSize: 18.0,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const Spacer(),
//             IconButton(
//               icon: const Icon(Icons.close, color: Colors.white),
//               onPressed: () {
//                 context.read<ZoneEditorBloc>().add(
//                   const TileSelected(Tile(x: -1, y: -1)),
//                 );
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 16.0),
//         Text(
//           'Posición: (${tile.x}, ${tile.y})',
//           style: const TextStyle(color: Colors.white70),
//         ),
//         Row(
//           children: [
//             const Text(
//               'Rotation:',
//               style: TextStyle(color: Colors.white70),
//             ),
//             const Spacer(),
//             IconButton(
//               icon: const Icon(Icons.rotate_left, color: Colors.white),
//               tooltip: 'Rotar izquierda',
//               onPressed: () {
//                 context.read<ZoneEditorBloc>().add(
//                   const RotateSelectedElement(false),
//                 );
//               },
//             ),
//             Text(
//               '${tile.rotation}°',
//               style: const TextStyle(color: Colors.white),
//             ),
//             IconButton(
//               icon: const Icon(Icons.rotate_right, color: Colors.white),
//               tooltip: 'Rotar derecha',
//               onPressed: () {
//                 context.read<ZoneEditorBloc>().add(
//                   const RotateSelectedElement(true),
//                 );
//               },
//             ),
//           ],
//         ),
//       ],
//     ),
//   );
// }