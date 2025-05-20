// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/board_config/board_config_bloc.dart';
import 'views/loading_screen.dart';

void main() {
  runApp(const ZoneMapApp());
}

class ZoneMapApp extends StatelessWidget {
  const ZoneMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardConfigBloc>(
      create: (context) => BoardConfigBloc(),
      child: MaterialApp(
        title: 'Editor de Mapa de Zonas',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
        ),
        darkTheme: ThemeData.dark().copyWith(
          primaryColor: Colors.teal,
          colorScheme: ColorScheme.dark(
            primary: Colors.teal.shade700,
            secondary: Colors.tealAccent,
          ),
          scaffoldBackgroundColor: Colors.grey.shade900,
        ),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const LoadingScreen(),
      ),
    );
  }
}