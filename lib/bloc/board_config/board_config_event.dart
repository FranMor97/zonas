part of 'board_config_bloc.dart';

sealed class BoardConfigEvent extends Equatable {
  const BoardConfigEvent();
  @override
  List<Object> get props => [];
}

final class BoardConfigInitialized extends BoardConfigEvent {}

class BoardColumnsChanged extends BoardConfigEvent {
  final int columns;
  const BoardColumnsChanged(this.columns);
  @override
  List<Object> get props => [columns];
}

class BoardRowsChanged extends BoardConfigEvent {
  final int rows;
  const BoardRowsChanged(this.rows);
  @override
  List<Object> get props => [rows];
}

class BoardTileSizeChanged extends BoardConfigEvent {
  final double tileSize;
  const BoardTileSizeChanged(this.tileSize);
  @override
  List<Object> get props => [tileSize];
}

class BoardNameChanged extends BoardConfigEvent {
  final String name;
  const BoardNameChanged(this.name);
  @override
  List<Object> get props => [name];
}

class BoardConfigSubmitted extends BoardConfigEvent {}
