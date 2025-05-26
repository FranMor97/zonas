// lib/views/board_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/utils/config-sliders.dart';
import '../bloc/board_config/board_config_bloc.dart';
import '../bloc/zone_editor_bloc/zone_editor_bloc.dart';
import '../models/board_config.dart';
import 'zone_editor_screen.dart';

class BoardConfigScreen extends StatelessWidget {
  const BoardConfigScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Mapa de Zonas'),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: BlocConsumer<BoardConfigBloc, BoardConfigState>(
        listener: (context, state) {
          if (state is BoardConfigSubmitSuccess) {
            _navigateToEditor(context, state.config);
          } else if (state is BoardConfigError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is BoardConfigLoaded) {
            return _buildConfigForm(context, state.config);
          }

          // Estado de carga o error
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  void _navigateToEditor(BuildContext context, BoardConfig config) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ZoneEditorBloc()..add(ZoneEditorInitialized(config)),
          child: const ZoneEditorScreen(),
        ),
      ),
    );
  }

  Widget _buildConfigForm(BuildContext context, BoardConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.teal.shade200,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Define tu Zonas",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  "Configure el tamaño del tablero y las dimensiones de las celdas.",
                  style: TextStyle(
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          TextFormField(
            initialValue: config.name,
            decoration: const InputDecoration(
              labelText: 'Nombre del mapa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
            ),
            onChanged: (value) {
              context.read<BoardConfigBloc>().add(BoardNameChanged(value));
            },
          ),

          const SizedBox(height: 24.0),

          // Sliders de configuración
          ConfigSliders(
            columns: config.columns,
            rows: config.rows,
            tileSize: config.tileSize,
            onColumnsChanged: (value) {
              context.read<BoardConfigBloc>().add(BoardColumnsChanged(value.round()));
            },
            onRowsChanged: (value) {
              context.read<BoardConfigBloc>().add(BoardRowsChanged(value.round()));
            },
            onTileSizeChanged: (value) {
              context.read<BoardConfigBloc>().add(BoardTileSizeChanged(value));
            },
          ),

          const SizedBox(height: 32.0),

          // Vista previa del tablero
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: CustomPaint(
                painter: GridPreviewPainter(
                  rows: config.rows,
                  columns: config.columns,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32.0),

          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<BoardConfigBloc>().add(BoardConfigSubmitted());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              icon: const Icon(Icons.grid_on),
              label: const Text(
                "Crear Tablero",
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para la vista previa del tablero
class GridPreviewPainter extends CustomPainter {
  final int rows;
  final int columns;

  GridPreviewPainter({
    required this.rows,
    required this.columns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    // Dibujar líneas verticales
    for (int i = 0; i <= columns; i++) {
      final x = i * cellWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Dibujar líneas horizontales
    for (int i = 0; i <= rows; i++) {
      final y = i * cellHeight;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Dibujar borde exterior
    final borderPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is GridPreviewPainter &&
        (oldDelegate.rows != rows || oldDelegate.columns != columns);
  }
}
