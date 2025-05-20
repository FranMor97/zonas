part of 'board_config_bloc.dart';

abstract class BoardConfigState extends Equatable {
  const BoardConfigState();

  @override
  List<Object> get props => [];
}

final class BoardConfigInitial extends BoardConfigState {}

final class BoardConfigLoading extends BoardConfigState {}

class BoardConfigLoaded extends BoardConfigState {
  final BoardConfig config;
  const BoardConfigLoaded(this.config);
  @override
  List<Object> get props => [config];
}

class BoardConfigError extends BoardConfigState {
  final String message;
  const BoardConfigError(this.message);
  @override
  List<Object> get props => [message];
}

class BoardConfigSubmitSuccess extends BoardConfigState {
  final BoardConfig config;

  const BoardConfigSubmitSuccess(this.config);

  @override
  List<Object> get props => [config];
}