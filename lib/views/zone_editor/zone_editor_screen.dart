import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/views/zone_editor/zone_editor_content.dart';
import '../../bloc/zone_editor_bloc/zone_editor_bloc.dart';


class ZoneEditorScreen extends StatelessWidget {
  const ZoneEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ZoneEditorBloc, ZoneEditorState>(
      listener: (context, state) {
        if (state is ZoneEditorSnackError) {
          // Cierra el SnackBar actual si existe
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: Text(state.message),
              ),
              backgroundColor: Colors.red,
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is ZoneEditorSucces) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: Text(state.message),
              ),
              backgroundColor: Colors.green,
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }else if(state is ZoneEditorSnackSuccess){
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: Text(state.message),
              ),
              backgroundColor: Colors.green,
              dismissDirection: DismissDirection.horizontal,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ZoneEditorLoaded) {
          return ZoneEditorContent(state: state);
        } else if (state is ZoneEditorLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF212121),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ZoneEditorError) {
          return Scaffold(
            backgroundColor: const Color(0xFF212121),
            appBar: AppBar(
              title: const Text('Editor de Zonas'),
              backgroundColor: const Color(0xFF333333),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}',
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                    ),
                    onPressed: () {
                      //TODO: Implementar la lógica para reintentar
                      // Reintentar con la configuración inicial
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Scaffold(
            backgroundColor: Color(0xFF212121),
            body: Center(
              child: Text(
                'Inicializando editor...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      },
    );
  }
}

