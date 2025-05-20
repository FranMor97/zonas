import 'package:flutter/material.dart';

class ConfigSliders extends StatelessWidget {
  final int columns;
  final int rows;
  final double tileSize;
  final Function(double) onColumnsChanged;
  final Function(double) onRowsChanged;
  final Function(double) onTileSizeChanged;

  const ConfigSliders(
      {super.key,
      required this.columns,
      required this.rows,
      required this.tileSize,
      required this.onColumnsChanged,
      required this.onRowsChanged,
      required this.onTileSizeChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlider(context, 'Columnas', columns.toDouble(), 10, 50, onColumnsChanged,
            Icons.swap_horiz, "$columns columnas"),
        const SizedBox(height: 16.0),
        _buildSlider(context, 'Filas', rows.toDouble(), 10, 50, onRowsChanged, Icons.swap_vert,
            "$rows filas"),
        const SizedBox(height: 16.0),
        _buildSlider(context, 'Tamaño de las Celdas', tileSize, 20.0, 60.0, onTileSizeChanged,
            Icons.grid_4x4, "${tileSize.round()} px")
      ],
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
    String valueLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.teal.shade700),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.teal.shade700,
                  inactiveTrackColor: Colors.teal.shade100,
                  thumbColor: Colors.teal.shade700,
                  overlayColor: Colors.teal.shade200.withOpacity(0.3),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: (max - min).round(),
                  onChanged: onChanged,
                ),
              ),
            ),
            Container(
              width: 90,
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                valueLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.teal.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
