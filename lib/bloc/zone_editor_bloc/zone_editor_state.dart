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

  final List<Tile> selectedTiles;

  final bool isMultiSelectMode;

  const ZoneEditorLoaded({
    required this.board,
    required this.availableElements,
    this.selectedElement,
    this.eraserMode = false,
    this.hasSelectedTile = false,
    this.selectedTile,
    this.editMode = 'place',
    this.selectedTiles = const [],
    this.isMultiSelectMode = false,
  });

  ZoneEditorLoaded copyWith({
    Board? board,
    List<ElementType>? availableElements,
    ElementType? selectedElement,
    bool? eraserMode,
    bool? hasSelectedTile,
    Tile? selectedTile,
    String? editMode,
    List<Tile>? selectedTiles,
    bool? isMultiSelectMode,
  }) {
    return ZoneEditorLoaded(
      board: board ?? this.board,
      availableElements: availableElements ?? this.availableElements,
      selectedElement: selectedElement ?? this.selectedElement,
      eraserMode: eraserMode ?? this.eraserMode,
      hasSelectedTile: hasSelectedTile ?? this.hasSelectedTile,
      selectedTile: selectedTile ?? this.selectedTile,
      editMode: editMode ?? this.editMode,
      selectedTiles: selectedTiles ?? this.selectedTiles,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
    );
  }

  BoardConfig get config => board.config;

  List<Tile> get tiles => board.tiles;

  bool isTileSelected(int x, int y) {
    return selectedTiles.any((tile) => tile.x == x && tile.y == y);
  }

  bool get hasMultipleSelection => selectedTiles.length > 1;
  @override
  List<Object?> get props => [
        board,
        availableElements,
        selectedElement,
        eraserMode,
        hasSelectedTile,
        selectedTile,
        editMode,
        selectedTiles,
        isMultiSelectMode,
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


class ZoneEditorSnackError extends ZoneEditorState {
  final String message;

  const ZoneEditorSnackError(this.message);

  @override
  List<Object?> get props => [message];
}
