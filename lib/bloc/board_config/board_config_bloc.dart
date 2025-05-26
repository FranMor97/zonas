import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../models/board_config.dart';

part 'board_config_event.dart';

part 'board_config_state.dart';

class BoardConfigBloc extends Bloc<BoardConfigEvent, BoardConfigState> {
  BoardConfigBloc() : super(BoardConfigInitial()) {
    on<BoardConfigInitialized>(_onInitialized);
    on<BoardColumnsChanged>(_onBoardColumnsChanged);
    on<BoardRowsChanged>(_onBoardRowsChanged);
    on<BoardTileSizeChanged>(_onBoardTileSizeChanged);
    on<BoardNameChanged>(_onBoardNameChanged);
    on<BoardConfigSubmitted>(_onBoardConfigSubmitted);
  }

  //en un futuro nos traeriamos la configuracion de un servicio, por eso el await que lo emula
  FutureOr<void> _onInitialized(
      BoardConfigInitialized event, Emitter<BoardConfigState> emit) async {
    emit(BoardConfigLoading());
    await Future.delayed(const Duration(seconds: 1));
    try {
      const config = BoardConfig();
      emit(const BoardConfigLoaded(config));
    } catch (e) {
      emit(BoardConfigError(e.toString()));
    }
  }

  void _onBoardColumnsChanged(BoardColumnsChanged event, Emitter<BoardConfigState> emit) {
    if (state is BoardConfigLoaded) {
      final currentState = state as BoardConfigLoaded;
      final updateConfig = currentState.config.copyWith(columns: event.columns);
      emit(BoardConfigLoaded(updateConfig));
    }
  }

  void _onBoardRowsChanged(BoardRowsChanged event, Emitter<BoardConfigState> emit) {
    if (state is BoardConfigLoaded) {
      final currentState = state as BoardConfigLoaded;
      final updateConfig = currentState.config.copyWith(rows: event.rows);
      emit(BoardConfigLoaded(updateConfig));
    }
  }

  void _onBoardTileSizeChanged(BoardTileSizeChanged event, Emitter<BoardConfigState> emit) {
    if (state is BoardConfigLoaded) {
      final currentState = state as BoardConfigLoaded;
      final updateConfig = currentState.config.copyWith(tileSize: event.tileSize);
      emit(BoardConfigLoaded(updateConfig));
    }
  }

  void _onBoardNameChanged(BoardNameChanged event, Emitter<BoardConfigState> emit) {
    if (state is BoardConfigLoaded) {
      final currentState = state as BoardConfigLoaded;
      final updateConfig = currentState.config.copyWith(name: event.name);
      emit(BoardConfigLoaded(updateConfig));
    }
  }


  //en un futur este evento sera future y guardara tambien en la configuracion las dimensiones y nombres de la zona
  void _onBoardConfigSubmitted(BoardConfigSubmitted event, Emitter<BoardConfigState> emit) {
    if (state is BoardConfigLoaded) {
      final currentState = state as BoardConfigLoaded;
      emit(BoardConfigSubmitSuccess(currentState.config));
    }
  }

}
