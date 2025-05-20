// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_game/bloc/board_config/board_config_bloc.dart';
import 'board_config_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BoardConfigBloc>().add(BoardConfigInitialized());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BoardConfigBloc, BoardConfigState>(
      listener: (context, state) {
        if (state is BoardConfigLoaded) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const BoardConfigScreen(),
            ),
          );
        }
      },
      child: _LoadingView(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade800, Colors.teal.shade500],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Editor de Zonas",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8.0),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 5.0,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Iniciando...",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}