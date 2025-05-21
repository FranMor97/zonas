// lib/screens/board_config_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Configuración del tablero'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<BoardConfigBloc>().add(BoardConfigSubmitted());
            },
            child: const Text('Crear Tablero'),
          ),
        ],
      ),
    );
  }
}