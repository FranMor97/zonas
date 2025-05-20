import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:table_game/models/board_components/element_type.dart';
import 'package:table_game/models/board_components/tile.dart';

import '../../models/board_components/board.dart';
import '../../models/board_config.dart';

part 'zone_editor_event.dart';
part 'zone_editor_state.dart';

class ZoneEditorBloc extends Bloc<ZoneEditorEvent, ZoneEditorState> {
  ZoneEditorBloc() : super(ZoneEditorInitial()) {
    on<ZoneEditorEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
