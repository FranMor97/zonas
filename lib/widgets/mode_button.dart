import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';

class ModeButton extends StatelessWidget {
  final String mode;
  final IconData icon;
  final String label;
  final bool isSelected;

  const ModeButton({
    Key? key,
    required this.mode,
    required this.icon,
    required this.label,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
        size: 18,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 12,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF00BFA5) : const Color(0xFF4D4D4D),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        context.read<ZoneEditorBloc>().add(EditModeChanged(mode));
      },
    );
  }
}