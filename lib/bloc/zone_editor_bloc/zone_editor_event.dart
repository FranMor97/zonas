part of 'zone_editor_bloc.dart';

abstract class ZoneEditorEvent extends Equatable {
  const ZoneEditorEvent();

  @override
  List<Object?> get props => [];
}

class ZoneEditorInitialized extends ZoneEditorEvent {
  final BoardConfig config;

  const ZoneEditorInitialized(this.config);

  @override
  List<Object?> get props => [config];
}

class ElementTypeSelected extends ZoneEditorEvent {
  final ElementType elementType;

  const ElementTypeSelected(this.elementType);

  @override
  List<Object?> get props => [elementType];
}

//Eventos de interactuación del mapa de zonas

class TileTapped extends ZoneEditorEvent {
  final int x;
  final int y;

  const TileTapped(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

class TileDragged extends ZoneEditorEvent {
  final int x;
  final int y;

  const TileDragged(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

class EraserModeToggled extends ZoneEditorEvent {
  final bool enabled;

  const EraserModeToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class EditModeChanged extends ZoneEditorEvent {
  final String mode;

  const EditModeChanged(this.mode);

  @override
  List<Object?> get props => [mode];
}

class TileSelected extends ZoneEditorEvent {
  final Tile tile;

  const TileSelected(this.tile);

  @override
  List<Object?> get props => [tile];
}

class RotateSelectedElement extends ZoneEditorEvent {
  final bool clockwise;

  const RotateSelectedElement(this.clockwise);

  @override
  List<Object?> get props => [clockwise];
}

class MoveSelectedElement extends ZoneEditorEvent {
  final int newX;
  final int newY;

  const MoveSelectedElement(this.newX, this.newY);

  @override
  List<Object?> get props => [newX, newY];
}

class UpdateElementProperties extends ZoneEditorEvent {
  final Map<String, dynamic> properties;

  const UpdateElementProperties(this.properties);

  @override
  List<Object?> get props => [properties];
}

class BoardCleared extends ZoneEditorEvent {}

class UndoLastAction extends ZoneEditorEvent {}

class RedoLastAction extends ZoneEditorEvent {}

class SaveCurrentBoard extends ZoneEditorEvent {
  final String name;

  const SaveCurrentBoard({this.name = ''});

  @override
  List<Object?> get props => [name];
}
