part of 'zone_editor_bloc.dart';

abstract class ZoneEditorState extends Equatable {
  const ZoneEditorState();

  @override
  List<Object?> get props => [];
}

final class ZoneEditorInitial extends ZoneEditorState {}

final class ZoneEditorLoading extends ZoneEditorState {}

class ZoneEditorLoaded extends ZoneEditorState {
  final Board board;

  final List<ElementType> availableElements;

  final ElementType? selectedElement;

  final bool eraserMode;

  final bool hasSelectedTile;

  final Tile? selectedTile;

  final String editMode;

  const ZoneEditorLoaded({
    required this.board,
    required this.availableElements,
    this.selectedElement,
    this.eraserMode = false,
    this.hasSelectedTile = false,
    this.selectedTile,
    this.editMode = 'place',
  });

  ZoneEditorLoaded copyWith({
    Board? board,
    List<ElementType>? availableElements,
    ElementType? selectedElement,
    bool? eraserMode,
    bool? hasSelectedTile,
    Tile? selectedTile,
    String? editMode,
  }) {
    return ZoneEditorLoaded(
      board: board ?? this.board,
      availableElements: availableElements ?? this.availableElements,
      selectedElement: selectedElement ?? this.selectedElement,
      eraserMode: eraserMode ?? this.eraserMode,
      hasSelectedTile: hasSelectedTile ?? this.hasSelectedTile,
      selectedTile: selectedTile ?? this.selectedTile,
      editMode: editMode ?? this.editMode,
    );
  }

  BoardConfig get config => board.config;

  List<Tile> get tiles => board.tiles;

  @override
  List<Object?> get props => [
        board,
        availableElements,
        selectedElement,
        eraserMode,
        hasSelectedTile,
        selectedTile,
        editMode,
      ];
}

class ZoneEditorError extends ZoneEditorState {
  final String message;

  const ZoneEditorError(this.message);

  @override
  List<Object?> get props => [message];
}

class ZoneEditorSucces extends ZoneEditorState {
  final String message;
  final ZoneEditorState previousState;

  const ZoneEditorSucces(this.message, this.previousState);

  @override
  List<Object?> get props => [message, previousState];
}
