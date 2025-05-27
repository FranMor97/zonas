part of 'zone_editor_bloc.dart';

abstract class ZoneEditorState extends Equatable {
  const ZoneEditorState();

  @override
  List<Object?> get props => [];
}

final class ZoneEditorInitial extends ZoneEditorState {}

final class ZoneEditorLoading extends ZoneEditorState {}

// class ZoneEditorLoaded extends ZoneEditorState {
//   final Board board;
//
//   final List<ElementType> availableElements;
//
//   final ElementType? selectedElement;
//
//   final bool eraserMode;
//
//   final bool hasSelectedTile;
//
//   final Tile? selectedTile;
//
//   final String editMode;
//
//   final List<Tile> selectedTiles;
//
//   final bool isMultiSelectMode;
//
//   const ZoneEditorLoaded({
//     required this.board,
//     required this.availableElements,
//     this.selectedElement,
//     this.eraserMode = false,
//     this.hasSelectedTile = false,
//     this.selectedTile,
//     this.editMode = 'place',
//     this.selectedTiles = const [],
//     this.isMultiSelectMode = false,
//   });
//
//   ZoneEditorLoaded copyWith({
//     Board? board,
//     List<ElementType>? availableElements,
//     ElementType? selectedElement,
//     bool? eraserMode,
//     bool? hasSelectedTile,
//     Tile? selectedTile,
//     String? editMode,
//     List<Tile>? selectedTiles,
//     bool? isMultiSelectMode,
//   }) {
//     return ZoneEditorLoaded(
//       board: board ?? this.board,
//       availableElements: availableElements ?? this.availableElements,
//       selectedElement: selectedElement ?? this.selectedElement,
//       eraserMode: eraserMode ?? this.eraserMode,
//       hasSelectedTile: hasSelectedTile ?? this.hasSelectedTile,
//       selectedTile: selectedTile ?? this.selectedTile,
//       editMode: editMode ?? this.editMode,
//       selectedTiles: selectedTiles ?? this.selectedTiles,
//       isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
//     );
//   }
//
//   BoardConfig get config => board.config;
//
//   List<Tile> get tiles => board.tiles;
//
//   bool isTileSelected(int x, int y) {
//     return selectedTiles.any((tile) => tile.x == x && tile.y == y);
//   }
//
//   bool get hasMultipleSelection => selectedTiles.length > 1;
//   @override
//   List<Object?> get props => [
//         board,
//         availableElements,
//         selectedElement,
//         eraserMode,
//         hasSelectedTile,
//         selectedTile,
//         editMode,
//         selectedTiles,
//         isMultiSelectMode,
//       ];
// }
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
  final bool autoMergeEnabled;

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
    this.autoMergeEnabled = true,
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
    bool? autoMergeEnabled,
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
      autoMergeEnabled: autoMergeEnabled ?? this.autoMergeEnabled,
    );
  }

  BoardConfig get config => board.config;
  List<Tile> get tiles => board.tiles;

  bool isTileSelected(int x, int y) {
    return selectedTiles.any((tile) => tile.x == x && tile.y == y);
  }

  bool get hasMultipleSelection => selectedTiles.length > 1;

  // Nuevo método para verificar si un tile es parte de un elemento seleccionado
  bool isTilePartOfSelectedElement(int x, int y) {
    final tile = board.getTile(x, y);
    if (tile == null || tile.elementId == null) return false;

    // Si tenemos un tile seleccionado individualmente
    if (hasSelectedTile && selectedTile != null && selectedTile!.elementId != null) {
      return tile.elementId == selectedTile!.elementId;
    }

    // Si estamos en modo multi-selección
    if (isMultiSelectMode && selectedTiles.isNotEmpty) {
      return selectedTiles.any((selectedTile) =>
      selectedTile.elementId == tile.elementId);
    }

    return false;
  }

  // Método para obtener todos los tiles de un elemento fusionado
  List<Tile> getMergedElementTiles(String mergedGroupId) {
    return board.tiles
        .where((tile) => tile.mergedGroupId == mergedGroupId && tile.isNotEmpty)
        .toList();
  }

  // Método para verificar si la selección actual contiene elementos fusionados
  bool get hasSelectedMergedElements {
    return selectedTiles.any((tile) => tile.isMerged);
  }

  // Método para obtener información sobre los elementos seleccionados
  Map<String, int> get selectedElementTypes {
    Map<String, int> typeCount = {};

    for (final tile in selectedTiles) {
      if (tile.type != null) {
        final typeId = tile.type!.id;
        typeCount[typeId] = (typeCount[typeId] ?? 0) + 1;
      }
    }

    return typeCount;
  }

  // Método para verificar si todos los elementos seleccionados son del mismo tipo
  bool get allSelectedSameType {
    if (selectedTiles.isEmpty) return true;

    final firstType = selectedTiles.first.type?.id;
    return selectedTiles.every((tile) => tile.type?.id == firstType);
  }

  // Método para obtener grupos fusionados en la selección
  Set<String> get selectedMergedGroups {
    return selectedTiles
        .where((tile) => tile.isMerged && tile.mergedGroupId != null)
        .map((tile) => tile.mergedGroupId!)
        .toSet();
  }

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
    autoMergeEnabled,
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
