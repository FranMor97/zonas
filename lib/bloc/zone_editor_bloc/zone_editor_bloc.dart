import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:table_game/models/board_components/element_type.dart';
import 'package:table_game/models/board_components/tile.dart';

import '../../models/board_components/board.dart';
import '../../models/board_config.dart';

part 'zone_editor_event.dart';

part 'zone_editor_state.dart';

class ZoneEditorBloc extends Bloc<ZoneEditorEvent, ZoneEditorState> {
  final Queue<Board> _undoStack = Queue<Board>();
  final Queue<Board> _redoStack = Queue<Board>();
  final int _maxHistorySize = 20;
  final Set<String> _draggedTiles = <String>{};
  bool _isDragging = false;
  String? _currentDragElementType;
  bool _autoMergeEnabled = false;

  ZoneEditorBloc() : super(ZoneEditorInitial()) {
    on<ZoneEditorInitialized>(_onInitialized);
    on<ElementTypeSelected>(_onElementTypeSelected);
    on<TileTapped>(_onTileTapped);
    on<SaveCurrentBoard>(_onSaveCurrentBoard);
    on<TileDragged>(_onTileDragged);
    on<EraserModeToggled>(_onEraserModeTaggled);
    on<EditModeChanged>(_onEditModeChanged);
    on<TileSelected>(_onTileSelected);
    on<RotateSelectedElement>(_onRotateSelectedElement);
    on<MoveSelectedElement>(_onMoveSelectedElement);
    on<UpdateElementProperties>(_onUpdateElementProperties);
    on<ClearBoard>(_onBoardCleared);
    on<UndoLastAction>(_onUndoLastAction);
    on<RedoLastAction>(_onRedoLastAction);
    on<DragEnded>(_onDragEnded);
    on<EraseDragg>(_onEraseDragg);
    on<ToggleMultiSelectMode>(_onToggleMultiSelectMode);
    on<AddTileToSelection>(_onAddTileToSelection);
    on<RemoveTileFromSelection>(_onRemoveTileFromSelection);
    on<ClearTileSelection>(_onClearTileSelection);
    on<MergeSelectedTiles>(_onMergeSelectedTiles);
    on<BoardUpdated>(_onBoardUpdated);
    on<ToggleAutoMerge>(_onToggleAutoMerge);
    on<ClearDragTracking>(_onClearDragTracking);
    on<StartDragMode>(_onStartDragMode);

  }

  List<ElementType> get _predefinedElements => [
    ElementType(
      id: 'select_tool',
      name: 'Seleccionar',
      color: Colors.blue.shade500,
      icon: Icons.select_all,
      isSelectionTool: true,
      defaultSize: const Size(1, 1),
    ),
    ElementType(
      id: 'wall',
      name: 'Pared',
      color: Colors.grey.shade800,
      icon: Icons.square,
      isWall: true,
      defaultSize: const Size(1, 1),
    ),
    ElementType(
      id: 'table_rect',
      name: 'Mesa rectangular',
      color: Colors.brown.shade700,
      icon: Icons.table_restaurant,
      defaultSize: const Size(2, 1),
    ),
    ElementType(
      id: 'table_round',
      name: 'Mesa redonda',
      color: Colors.brown.shade500,
      icon: Icons.circle,
      shape: 'circle',
      defaultSize: const Size(1, 1),
    ),
    ElementType(
      id: 'chair',
      name: 'Silla',
      color: Colors.orange.shade700,
      icon: Icons.chair,
      defaultSize: const Size(1, 1),
    ),
    ElementType(
      id: 'bar',
      name: 'Barra',
      color: Colors.amber.shade700,
      icon: Icons.local_bar,
      defaultSize: const Size(3, 1),
    ),
    ElementType(
      id: 'plant',
      name: 'Planta',
      color: Colors.green.shade600,
      icon: Icons.nature,
      defaultSize: const Size(2, 2),
    ),
    ElementType(
      id: 'zone_a',
      name: 'Zona A',
      color: Colors.blue.shade500.withOpacity(0.5),
      icon: Icons.crop_square,
      defaultSize: const Size(2, 2),
    ),
    ElementType(
      id: 'zone_b',
      name: 'Zona B',
      color: Colors.red.shade500.withOpacity(0.5),
      icon: Icons.crop_square,
      defaultSize: const Size(2, 2),
    ),
  ];

  FutureOr<void> _onInitialized(ZoneEditorInitialized event, Emitter<ZoneEditorState> emit) async {
    emit(ZoneEditorLoading());
    try {
      final board = Board.empty(event.config);
      final elements = _predefinedElements;
      emit(ZoneEditorLoaded(board: board, availableElements: elements));

      _undoStack.clear();
      _redoStack.clear();
      _saveToHistory(board);
    } catch (e) {
      emit(ZoneEditorError('Error al inicializar el editor: $e'));
    }
  }

  void _onTileDragged(TileDragged event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if (currentState.editMode == 'place' && currentState.selectedElement != null) {
        final Board board = currentState.board;
        final updatedBoard = board.placeElement(event.x, event.y, currentState.selectedElement!);

        if (updatedBoard != board) {
          // Marcar que estamos en modo drag
          _isDragging = true;
          _currentDragElementType = currentState.selectedElement!.id;

          // Agregar la posición a las tiles arrastradas
          _draggedTiles.add('${event.x},${event.y}');

          emit(currentState.copyWith(board: updatedBoard));
        }
      }
    }
  }


  void _onAddTileToSelection(AddTileToSelection event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      // Comprobar si ya está seleccionado
      if (!currentState.isTileSelected(event.tile.x, event.tile.y)) {
        if (_canAddToSelection(currentState, event.tile)) {
          emit(currentState.copyWith(
            selectedTiles: [...currentState.selectedTiles, event.tile],
          ));
        } else {
          emit(const ZoneEditorSnackError('Solo puedes seleccionar tiles adyacentes'));
          emit(currentState);
        }
      }
    }
  }


  void _onToggleMultiSelectMode(ToggleMultiSelectMode event, Emitter<ZoneEditorState> emit) {
    if(state is ZoneEditorLoaded){
      final currentState = state as ZoneEditorLoaded;
      if (!event.enabled){
        emit(currentState.copyWith(
          isMultiSelectMode: false,
          selectedTiles: [],
        ));
      }else{
        if(currentState.hasSelectedTile && currentState.selectedTile != null){
          emit(currentState.copyWith(
            isMultiSelectMode: true,
            selectedTiles: [currentState.selectedTile!],
          ));
        }else{
          emit(currentState.copyWith(isMultiSelectMode: true));
        }
      }
    }
  }

  void _onToggleAutoMerge(ToggleAutoMerge event, Emitter<ZoneEditorState> emit) {
    _autoMergeEnabled = event.enabled;

    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      // Mostrar mensaje de confirmación
      final message = _autoMergeEnabled
          ? 'Auto-fusión activada'
          : 'Auto-fusión desactivada';

      // Emitir mensaje temporal
      emit(ZoneEditorSnackError(message));

      // Emitir estado actualizado
      emit(currentState.copyWith(autoMergeEnabled: _autoMergeEnabled));
    }
  }

// Handler para ClearDragTracking
  void _onClearDragTracking(ClearDragTracking event, Emitter<ZoneEditorState> emit) {
    _isDragging = false;
    _draggedTiles.clear();
    _currentDragElementType = null;

    // No necesita emitir estado, es solo para limpiar tracking interno
  }

// Handler para StartDragMode
  void _onStartDragMode(StartDragMode event, Emitter<ZoneEditorState> emit) {
    _isDragging = true;
    _currentDragElementType = event.elementTypeId;
    _draggedTiles.clear(); // Limpiar tiles anteriores

    // No necesita emitir estado, es solo para configurar tracking interno
  }
  void _onRemoveTileFromSelection(RemoveTileFromSelection event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      List<Tile> updatedSelection = List.from(currentState.selectedTiles)
        ..removeWhere((t) => t.x == event.tile.x && t.y == event.tile.y);

      emit(currentState.copyWith(
        selectedTiles: updatedSelection,
        // Si no quedan tiles seleccionados, desactivamos el modo multiselección
        isMultiSelectMode: updatedSelection.isNotEmpty,
      ));
    }
  }

  void _onClearTileSelection(ClearTileSelection event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      emit(currentState.copyWith(
        selectedTiles: [],
        isMultiSelectMode: false,
        selectedTile: null,
        hasSelectedTile: false,
      ));
    }
  }

  void _onMergeSelectedTiles(MergeSelectedTiles event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if (currentState.selectedTiles.length <= 1) {
        emit(const ZoneEditorSnackError('Selecciona al menos 2 tiles para fusionar'));
        emit(currentState);
        return;
      }

      // Expandir la selección para incluir todos los tiles de elementos completos
      final expandedSelection = _expandSelectionToCompleteElements(currentState.selectedTiles, currentState.board);

      // Comprobar que todos los tiles expandidos son del mismo tipo
      final firstType = expandedSelection.first.type;
      final allSameType = expandedSelection.every((tile) => tile.type?.id == firstType?.id);

      if (!allSameType || firstType == null) {
        emit(const ZoneEditorSnackError('Solo puedes fusionar tiles del mismo tipo'));
        emit(currentState);
        return;
      }

      // Comprobamos que todos los tiles forman un grupo conexo
      if (!_areAllTilesConnected(expandedSelection)) {
        emit(const ZoneEditorSnackError('Todos los tiles deben formar un grupo conexo'));
        emit(currentState);
        return;
      }

      // Proceder con la fusión
      final String mergedId = 'merged_${DateTime.now().millisecondsSinceEpoch}';
      final originTile = expandedSelection.first;

      Board updatedBoard = currentState.board;

      // Remover todos los tiles de la selección expandida
      for (final tile in expandedSelection) {
        updatedBoard = updatedBoard.removeElement(tile.x, tile.y);
      }

      // Colocar todos los tiles con el nuevo ID fusionado
      for (final tile in expandedSelection) {
        final newTile = tile.asPartOfElement(
          elementType: firstType,
          elementId: mergedId,
          originX: originTile.x,
          originY: originTile.y,
          rotation: originTile.rotation,
          additionalProperties: {
            ...tile.properties ?? {},
            'isMerged': true,
            'mergedGroupId': mergedId,
          },
        );

        updatedBoard = updatedBoard.updateTile(newTile);
      }

      _saveToHistory(updatedBoard);
      emit(const ZoneEditorSnackError('Tiles fusionados correctamente'));

      emit(currentState.copyWith(
        board: updatedBoard,
        selectedTiles: [],
        isMultiSelectMode: false,
        selectedTile: null,
        hasSelectedTile: false,
      ));
    }
  }

  List<Tile> _expandSelectionToCompleteElements(List<Tile> selectedTiles, Board board) {
    Set<String> processedElementIds = {};
    List<Tile> expandedSelection = [];

    for (final tile in selectedTiles) {
      if (tile.elementId != null && !processedElementIds.contains(tile.elementId)) {
        // Encontrar todos los tiles que pertenecen a este elemento
        final elementTiles = board.tiles
            .where((t) => t.elementId == tile.elementId)
            .toList();

        expandedSelection.addAll(elementTiles);
        processedElementIds.add(tile.elementId!);
      } else if (tile.elementId == null) {
        // Tile sin elemento, agregar tal como está
        expandedSelection.add(tile);
      }
    }

    return expandedSelection;
  }

  void _onDragEnded(DragEnded event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      // Guardar el estado actual en el historial
      if (_undoStack.isNotEmpty && currentState.board != _undoStack.first) {
        _saveToHistory(currentState.board);
      }

      // Solo hacer auto-merge si hubo drag y hay tiles para procesar
      if (_isDragging && _draggedTiles.isNotEmpty && _currentDragElementType != null) {
        _performSmartAutoMerge(emit);
      }

      // Limpiar el tracking de drag
      _isDragging = false;
      _draggedTiles.clear();
      _currentDragElementType = null;
    }
  }



  // void _onMergeSelectedTiles(MergeSelectedTiles event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //
  //     if (currentState.selectedTiles.length <= 1) {
  //       // Necesitamos al menos 2 tiles para fusionar
  //       emit(const ZoneEditorSnackError('Selecciona al menos 2 tiles para fusionar'));
  //       emit(currentState);
  //       return;
  //     }
  //
  //     // Comprobar que todos los tiles seleccionados son del mismo tipo
  //     final firstType = currentState.selectedTiles.first.type;
  //     final allSameType = currentState.selectedTiles
  //         .every((tile) => tile.type?.id == firstType?.id);
  //
  //     if (!allSameType || firstType == null) {
  //       emit(const ZoneEditorSnackError('Solo puedes fusionar tiles del mismo tipo'));
  //       emit(currentState);
  //       return;
  //     }
  //
  //     // Comprobamos que todos los tiles son adyacentes formando un grupo conexo
  //     if (!_areAllTilesConnected(currentState.selectedTiles)) {
  //       emit(const ZoneEditorSnackError('Todos los tiles deben formar un grupo conexo'));
  //       emit(currentState);
  //       return;
  //     }
  //
  //     final String mergedId = 'merged_${DateTime.now().millisecondsSinceEpoch}';
  //     final originTile = currentState.selectedTiles.first;
  //
  //     Board updatedBoard = currentState.board;
  //
  //     for (final tile in currentState.selectedTiles) {
  //       updatedBoard = updatedBoard.removeElement(tile.x, tile.y);
  //
  //       // Luego colocamos un nuevo elemento con el ID común
  //       final newTile = tile.asPartOfElement(
  //         elementType: firstType,
  //         elementId: mergedId,
  //         originX: originTile.x,
  //         originY: originTile.y,
  //         rotation: originTile.rotation,
  //         additionalProperties: {
  //           ...tile.properties ?? {},
  //           'isMerged': true,
  //           'mergedGroupId': mergedId,
  //         },
  //       );
  //
  //       updatedBoard = updatedBoard.updateTile(newTile);
  //     }
  //
  //     // Guardar en el historial y emitir el nuevo estado
  //     _saveToHistory(updatedBoard);
  //     emit(const ZoneEditorSnackError('Tiles fusionados correctamente'));
  //
  //     emit(currentState.copyWith(
  //       board: updatedBoard,
  //       selectedTiles: [], // Limpiamos la selección
  //       isMultiSelectMode: false,
  //       selectedTile: null,
  //       hasSelectedTile: false,
  //     ));
  //   }
  // }

  void _onBoardUpdated(BoardUpdated event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      _saveToHistory(event.board);
      emit(currentState.copyWith(board: event.board));
    }
  }


  // void _onElementTypeSelected(ElementTypeSelected event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //
  //     if(event.elementType.isSelectionTool){
  //       emit(currentState.copyWith(
  //         selectedElement: event.elementType,
  //         eraserMode: false,
  //         editMode: 'select',
  //         selectedTile: null,
  //         hasSelectedTile: false,
  //       ));}else{
  //       emit(currentState.copyWith(
  //         selectedElement: event.elementType,
  //         eraserMode: false,
  //         editMode: 'place',
  //       ));
  //     }
  //   }
  // }

  void _onTileTapped(TileTapped event, Emitter<ZoneEditorState> emit) {
    // Limpiar tracking de drag en tap (no es drag)
    _isDragging = false;
    _draggedTiles.clear();
    _currentDragElementType = null;

    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      final Board board = currentState.board;
      Board updatedBoard;

      switch (currentState.editMode) {
        case 'place':
          if (currentState.selectedElement != null) {
            updatedBoard = board.placeElement(
              event.x,
              event.y,
              currentState.selectedElement!,
            );

            if (updatedBoard != board) {
              _saveToHistory(updatedBoard);
              emit(currentState.copyWith(board: updatedBoard));
            }
          }
          break;

        case 'erase':
          updatedBoard = board.removeElement(event.x, event.y);
          if (updatedBoard != board) {
            _saveToHistory(updatedBoard);
            emit(currentState.copyWith(board: updatedBoard));
          }
          break;

        case 'select':
          final tile = board.getTile(event.x, event.y);
          if (tile != null && tile.isNotEmpty) {
            if (currentState.isMultiSelectMode) {
              _handleMultiSelectTileTap(tile, currentState, emit);
            } else {
              _handleSingleSelectTileTap(tile, currentState, emit);
            }
          } else {
            emit(currentState.copyWith(
              selectedTile: null,
              hasSelectedTile: false,
              selectedTiles: [],
              isMultiSelectMode: false,
            ));
          }
          break;

        case 'move':
          if (currentState.hasSelectedTile && currentState.selectedTile != null) {
            final tile = currentState.selectedTile!;
            final elementId = tile.elementId;

            if (elementId != null) {
              Board tempoBoard = board.removeElement(tile.x, tile.y);
              updatedBoard = tempoBoard.placeElement(event.x, event.y, tile.type!);

              if (updatedBoard != board) {
                _saveToHistory(updatedBoard);
                emit(currentState.copyWith(
                    board: updatedBoard, selectedTile: null, hasSelectedTile: false));
              }
            }
          }
          break;

        default:
          break;
      }
    }
  }

  void _onElementTypeSelected(ElementTypeSelected event, Emitter<ZoneEditorState> emit) {
    // Limpiar tracking cuando se cambia de elemento
    _isDragging = false;
    _draggedTiles.clear();
    _currentDragElementType = null;

    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if (event.elementType.isSelectionTool) {
        emit(currentState.copyWith(
          selectedElement: event.elementType,
          eraserMode: false,
          editMode: 'select',
          selectedTile: null,
          hasSelectedTile: false,
        ));
      } else {
        emit(currentState.copyWith(
          selectedElement: event.elementType,
          eraserMode: false,
          editMode: 'place',
        ));
      }
    }
  }

  void _onEditModeChanged(EditModeChanged event, Emitter<ZoneEditorState> emit) {
    // Limpiar tracking cuando se cambia de modo
    _isDragging = false;
    _draggedTiles.clear();
    _currentDragElementType = null;

    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      emit(currentState.copyWith(
        editMode: event.mode,
        eraserMode: event.mode == 'erase',
        selectedElement: event.mode == 'erase' ? null : currentState.selectedElement,
      ));
    }}

  // void _onTileTapped(TileTapped event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //     final Board board = currentState.board;
  //     Board updatedBoard;
  //
  //     switch (currentState.editMode) {
  //       case 'place':
  //         if (currentState.selectedElement != null) {
  //           updatedBoard = board.placeElement(
  //             event.x,
  //             event.y,
  //             currentState.selectedElement!,
  //           );
  //
  //           if (updatedBoard != board) {
  //             _saveToHistory(updatedBoard);
  //             emit(currentState.copyWith(board: updatedBoard));
  //           }
  //         }
  //         break;
  //
  //       case 'erase':
  //         updatedBoard = board.removeElement(event.x, event.y);
  //         if (updatedBoard != board) {
  //           _saveToHistory(updatedBoard);
  //           emit(currentState.copyWith(board: updatedBoard));
  //         }
  //         break;
  //
  //       case 'select':
  //         final tile = board.getTile(event.x, event.y);
  //         if (tile != null && tile.isNotEmpty) {
  //           if (currentState.isMultiSelectMode) {
  //             _handleMultiSelectTileTap(tile, currentState, emit);
  //           } else {
  //             _handleSingleSelectTileTap(tile, currentState, emit);
  //           }
  //         } else {
  //           emit(currentState.copyWith(
  //             selectedTile: null,
  //             hasSelectedTile: false,
  //             selectedTiles: [],
  //             isMultiSelectMode: false,
  //           ));
  //         }
  //         break;
  //
  //       case 'move':
  //         if (currentState.hasSelectedTile && currentState.selectedTile != null) {
  //           final tile = currentState.selectedTile!;
  //           final elementId = tile.elementId;
  //
  //           if (elementId != null) {
  //             Board tempoBoard = board.removeElement(tile.x, tile.y);
  //             updatedBoard = tempoBoard.placeElement(event.x, event.y, tile.type!);
  //
  //             if (updatedBoard != board) {
  //               _saveToHistory(updatedBoard);
  //               emit(currentState.copyWith(
  //                   board: updatedBoard, selectedTile: null, hasSelectedTile: false));
  //             }
  //           }
  //         }
  //         break;
  //
  //       default:
  //         break;
  //     }
  //   }
  // }


  bool _canAddToSelection(ZoneEditorLoaded state, Tile newTile) {
    if (state.selectedTiles.isEmpty) return true;

    if (state.selectedTiles.first.type?.id != newTile.type?.id) return false;

    return state.selectedTiles.any((tile) =>
    (tile.x == newTile.x && (tile.y == newTile.y + 1 || tile.y == newTile.y - 1)) ||
        (tile.y == newTile.y && (tile.x == newTile.x + 1 || tile.x == newTile.x - 1))
    );
  }

  void _saveToHistory(Board board) {
    _undoStack.addFirst(board);
    _redoStack.clear();

    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeLast();
    }
  }

  void _handleSingleSelectTileTap(Tile tile, ZoneEditorLoaded currentState, Emitter<ZoneEditorState> emit) {
    // Si el tile está fusionado, seleccionar todo el grupo
    if (tile.isMerged && tile.mergedGroupId != null) {
      final mergedGroupTiles = currentState.board.tiles
          .where((t) => t.mergedGroupId == tile.mergedGroupId && t.isNotEmpty)
          .toList();

      emit(currentState.copyWith(
        selectedTile: tile,
        hasSelectedTile: true,
        selectedTiles: mergedGroupTiles,
        isMultiSelectMode: false,
      ));
    } else {
      // Selección individual normal
      emit(currentState.copyWith(
        selectedTile: tile,
        hasSelectedTile: true,
        selectedTiles: [],
        isMultiSelectMode: false,
      ));
    }
  }

  // void _onTileDragged(TileDragged event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //     if (currentState.editMode == 'place' && currentState.selectedElement != null) {
  //       final Board board = currentState.board;
  //       final updatedBoard = board.placeElement(event.x, event.y, currentState.selectedElement!);
  //       if (updatedBoard != board) {
  //         emit(currentState.copyWith(board: updatedBoard));
  //       }
  //     }
  //   }
  // }

  void _onEraserModeTaggled(
      EraserModeToggled event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      emit(currentState.copyWith(
        eraserMode: event.enabled,
        editMode: event.enabled ? 'erase' : 'place',
        selectedElement: event.enabled ? null : currentState.selectedElement,
      ));
    }
  }

  // void _onEditModeChanged(EditModeChanged event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //
  //     emit(currentState.copyWith(
  //       editMode: event.mode,
  //       eraserMode: event.mode == 'erase',
  //       selectedElement: event.mode == 'erase' ? null : currentState.selectedElement,
  //     ));
  //   }
  // }

  void _onBoardCleared(ClearBoard event, Emitter<ZoneEditorState> emit) {
    _isDragging = false;
    _draggedTiles.clear();
    _currentDragElementType = null;

    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      final Board board = currentState.board;
      final boardUpdated = board.clear();
      _saveToHistory(board);
      emit(currentState.copyWith(board: boardUpdated));
    }
  }

  void _onTileSelected(
      TileSelected event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      // Modified to not automatically enter multi-select mode
      emit(currentState.copyWith(
        selectedTile: event.tile,
        hasSelectedTile: true,
        isMultiSelectMode: false, // Don't enable multi-select by default
      ));
    }
  }

  void _onRotateSelectedElement(
      RotateSelectedElement event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if (currentState.hasSelectedTile && currentState.selectedTile != null) {
        final tile = currentState.selectedTile!;

        if (tile.elementId != null) {
          final Board board = currentState.board;


          final Board updatedBoard = board.rotateElement(
            tile.elementId!,
            event.clockwise,
          );

          // Si el tablero cambió, guardar en el historial
          if (updatedBoard != board) {
            _saveToHistory(updatedBoard);

            // Encontrar el nuevo tile de origen para mantener la selección
            final newOrigin = updatedBoard.tiles.firstWhere(
                  (t) => t.elementId == tile.elementId && t.isOrigin,
              orElse: () => tile,
            );

            emit(currentState.copyWith(
              board: updatedBoard,
              selectedTile: newOrigin,
            ));
          } else {
            emit(const ZoneEditorSnackError('No se puede rotary: no hay espacio disponible'));
            emit(currentState);
          }
        }
      }
    }
  }

  void _onMoveSelectedElement(
      MoveSelectedElement event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      // Verificar si hay un elemento seleccionado
      if (currentState.hasSelectedTile && currentState.selectedTile != null) {
        final tile = currentState.selectedTile!;
        final elementId = tile.elementId;

        if (tile.type != null && elementId != null) {
          final Board board = currentState.board;

          // Primero eliminar el elemento actual
          Board tempBoard = board.removeElement(tile.x, tile.y);

          // Luego intentar colocarlo en la nueva posición
          Board updatedBoard = tempBoard.placeElement(
            event.newX,
            event.newY,
            tile.type!,
            properties: tile.properties,
          );

          if (updatedBoard != board) {
            _saveToHistory(updatedBoard);

            final Tile? updatedTile = updatedBoard.getTile(event.newX, event.newY);

            emit(currentState.copyWith(
              board: updatedBoard,
              selectedTile: updatedTile,
            ));
          }
        }
      }
    }
  }

  void _onUpdateElementProperties(
      UpdateElementProperties event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      // Verificar si hay un elemento seleccionado
      if (currentState.hasSelectedTile && currentState.selectedTile != null) {
        final tile = currentState.selectedTile!;

        // Crear nuevas propiedades combinando las actuales con las nuevas
        final Map<String, dynamic> newProperties = {
          ...tile.properties!,
          ...event.properties,
        };

        // Intentar actualizar el elemento en el tablero
        if (tile.type != null && tile.elementId != null) {
          Board board = currentState.board;

          // Primero eliminar el elemento actual
          Board tempBoard = board.removeElement(tile.x, tile.y);

          // Luego intentar colocarlo con las nuevas propiedades
          Board updatedBoard = tempBoard.placeElement(
            tile.x,
            tile.y,
            tile.type!,
            properties: newProperties,
          );

          // Si el tablero cambió, guardar en el historial
          if (updatedBoard != board) {
            _saveToHistory(updatedBoard);

            // Obtener el nuevo tile actualizado
            final Tile? updatedTile = updatedBoard.getTile(tile.x, tile.y);

            emit(currentState.copyWith(
              board: updatedBoard,
              selectedTile: updatedTile,
            ));
          }
        }
      }
    }
  }

  void _onSaveCurrentBoard(
      SaveCurrentBoard event,
      Emitter<ZoneEditorState> emit,
      ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      emit(ZoneEditorSucces(
        'Tablero guardado correctamente',
        currentState,
      ));

      // Volver al estado anterior después de un breve tiempo
      Future.delayed(const Duration(seconds: 1), () {
        if (state is ZoneEditorSucces) {
          emit((state as ZoneEditorSucces).previousState);
        }
      });
    }
  }

  // void _onBoardCleared(ClearBoard event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //     final Board board = currentState.board;
  //     final boardUpdated = board.clear();
  //     _saveToHistory(board);
  //     emit(currentState.copyWith(board: boardUpdated));
  //   }
  // }

  void _onUndoLastAction(UndoLastAction event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      if (_undoStack.length > 1) {
        _redoStack.addFirst(_undoStack.removeFirst());
        final previousBoard = _undoStack.first;
        emit(currentState.copyWith(
            board: previousBoard, selectedTile: null, hasSelectedTile: false));
      }
    }
  }

  void _onRedoLastAction(RedoLastAction event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      if (_redoStack.isNotEmpty) {
        final nextBoard = _redoStack.removeFirst();
        _undoStack.addFirst(nextBoard);

        emit(currentState.copyWith(
          board: nextBoard,
          selectedTile: null,
          hasSelectedTile: false,
        ));
      }
    }
  }

  // void _onDragEnded(DragEnded event, Emitter<ZoneEditorState> emit) {
  //   if (state is ZoneEditorLoaded) {
  //     final currentState = state as ZoneEditorLoaded;
  //
  //     // First save current state to history if needed
  //     if (_undoStack.isNotEmpty && currentState.board != _undoStack.first) {
  //       _saveToHistory(currentState.board);
  //     }
  //
  //     // If we're in place mode, we should check for elements to merge
  //     if (currentState.editMode == 'place') {
  //       _autoMergeAdjacentElements(emit);
  //     }
  //   }
  // }

  void _performSmartAutoMerge(Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      final board = currentState.board;

      // Obtener solo los tiles que fueron colocados por drag
      List<Tile> draggedTileObjects = [];

      for (final coordString in _draggedTiles) {
        final coords = coordString.split(',');
        final x = int.parse(coords[0]);
        final y = int.parse(coords[1]);
        final tile = board.getTile(x, y);

        if (tile != null &&
            tile.isNotEmpty &&
            tile.type?.id == _currentDragElementType) {
          draggedTileObjects.add(tile);
        }
      }

      if (draggedTileObjects.length < 2) {
        // No hay suficientes tiles para fusionar
        return;
      }

      // Buscar grupos conectados solo entre los tiles arrastrados
      final List<List<Tile>> connectedGroups = _findConnectedGroupsInDraggedTiles(draggedTileObjects);

      Board updatedBoard = board;
      bool didMerge = false;

      // Procesar cada grupo conectado
      for (final group in connectedGroups) {
        if (group.length > 1) {
          // Verificar si tienen diferentes elementIds (necesario para fusionar)
          final Set<String?> elementIds = group
              .map((tile) => tile.elementId)
              .where((id) => id != null)
              .toSet();

          if (elementIds.length > 1) {
            // Fusionar este grupo
            final mergedId = 'merged_${DateTime.now().millisecondsSinceEpoch}_${group.hashCode}';
            final originTile = group.first;

            // Remover todos los tiles del grupo
            for (final tile in group) {
              updatedBoard = updatedBoard.removeElement(tile.x, tile.y);
            }

            // Colocarlos de nuevo con el ID fusionado
            for (final tile in group) {
              final newTile = tile.asPartOfElement(
                elementType: tile.type!,
                elementId: mergedId,
                originX: originTile.x,
                originY: originTile.y,
                rotation: originTile.rotation,
                additionalProperties: {
                  ...tile.properties ?? {},
                  'isMerged': true,
                  'mergedGroupId': mergedId,
                  'autoMerged': true, // Marca para identificar auto-merge
                },
              );

              updatedBoard = updatedBoard.updateTile(newTile);
            }

            didMerge = true;
          }
        }
      }

      // Si hubo fusiones, actualizar el board
      if (didMerge) {
        _saveToHistory(updatedBoard);
        emit((state as ZoneEditorLoaded).copyWith(board: updatedBoard));
      }
    }
  }


  List<List<Tile>> _findConnectedGroupsInDraggedTiles(List<Tile> draggedTiles) {
    List<List<Tile>> groups = [];
    Set<String> visited = {};

    for (final tile in draggedTiles) {
      final key = '${tile.x},${tile.y}';
      if (visited.contains(key)) continue;

      // Iniciar un nuevo grupo con este tile
      List<Tile> group = [];
      List<Tile> queue = [tile];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final currentKey = '${current.x},${current.y}';

        if (visited.contains(currentKey)) continue;
        visited.add(currentKey);
        group.add(current);

        // Buscar vecinos adyacentes SOLO entre los tiles arrastrados
        for (final neighbor in draggedTiles) {
          final neighborKey = '${neighbor.x},${neighbor.y}';
          if (!visited.contains(neighborKey) && _areAdjacent(current, neighbor)) {
            queue.add(neighbor);
          }
        }
      }

      if (group.isNotEmpty) {
        groups.add(group);
      }
    }

    return groups;
  }
  // Helper method to find groups of adjacent tiles

  _findAdjacentGroups(List<Tile> tiles) {
    List<List<Tile>> groups = [];
    Set<String> visited = {};

    for (var tile in tiles) {
      final key = '${tile.x},${tile.y}';
      if (visited.contains(key)) continue;

      // Start a new group with this tile
      List<Tile> group = [];
      List<Tile> queue = [tile];

      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        final currentKey = '${current.x},${current.y}';

        if (visited.contains(currentKey)) continue;
        visited.add(currentKey);
        group.add(current);

        // Add adjacent tiles of the same type to the queue
        for (var otherTile in tiles) {
          final otherKey = '${otherTile.x},${otherTile.y}';
          if (!visited.contains(otherKey)) {
            if (_areAdjacent(current, otherTile)) {
              queue.add(otherTile);
            }
          }
        }
      }

      if (group.isNotEmpty) {
        groups.add(group);
      }
    }

    return groups;
  }

  void _handleMultiSelectTileTap(Tile tile, ZoneEditorLoaded currentState, Emitter<ZoneEditorState> emit) {
    // Si el tile está fusionado, seleccionar todo el grupo fusionado
    if (tile.isMerged && tile.mergedGroupId != null) {
      final mergedGroupTiles = currentState.board.tiles
          .where((t) => t.mergedGroupId == tile.mergedGroupId && t.isNotEmpty)
          .toList();

      // Verificar si algún tile del grupo ya está seleccionado
      final anySelected = mergedGroupTiles.any((t) =>
          currentState.selectedTiles.any((selected) => selected.x == t.x && selected.y == t.y));

      if (anySelected) {
        // Remover todo el grupo de la selección
        List<Tile> updatedSelection = List.from(currentState.selectedTiles);
        for (final groupTile in mergedGroupTiles) {
          updatedSelection.removeWhere((selected) =>
          selected.x == groupTile.x && selected.y == groupTile.y);
        }

        emit(currentState.copyWith(
          selectedTiles: updatedSelection,
          isMultiSelectMode: updatedSelection.isNotEmpty,
        ));
      } else {
        // Agregar todo el grupo a la selección si es compatible
        if (_canAddGroupToSelection(currentState, mergedGroupTiles)) {
          emit(currentState.copyWith(
            selectedTiles: [...currentState.selectedTiles, ...mergedGroupTiles],
          ));
        } else {
          emit(const ZoneEditorSnackError('No se puede agregar este grupo a la selección'));
          emit(currentState);
        }
      }
    } else {
      // Tile individual - manejo normal
      if (currentState.isTileSelected(tile.x, tile.y)) {
        List<Tile> updatedSelection = List.from(currentState.selectedTiles)
          ..removeWhere((t) => t.x == tile.x && t.y == tile.y);

        emit(currentState.copyWith(
          selectedTiles: updatedSelection,
          isMultiSelectMode: updatedSelection.isNotEmpty,
        ));
      } else {
        if (_canAddToSelection(currentState, tile)) {
          emit(currentState.copyWith(
            selectedTiles: [...currentState.selectedTiles, tile],
          ));
        } else {
          emit(const ZoneEditorSnackError('No se puede agregar a la selección'));
          emit(currentState);
        }
      }
    }
  }



  // Helper method to check if two tiles are adjacent
  bool _areAdjacent(Tile a, Tile b) {
    return (a.x == b.x && (a.y == b.y + 1 || a.y == b.y - 1)) ||
        (a.y == b.y && (a.x == b.x + 1 || a.x == b.x - 1));
  }
  bool _canAddGroupToSelection(ZoneEditorLoaded state, List<Tile> groupTiles) {
    if (state.selectedTiles.isEmpty) return true;

    // Verificar que todos los tiles del grupo son del mismo tipo que la selección actual
    final selectedType = state.selectedTiles.first.type?.id;
    final groupType = groupTiles.first.type?.id;

    if (selectedType != groupType) return false;

    // Verificar que al menos un tile del grupo es adyacente a la selección actual
    return groupTiles.any((groupTile) =>
        state.selectedTiles.any((selectedTile) => _areAdjacent(groupTile, selectedTile)));
  }

// Método mejorado para verificar conectividad
  bool _areAllTilesConnected(List<Tile> tiles) {
    if (tiles.isEmpty) return true;
    if (tiles.length == 1) return true;

    Set<String> visited = {};
    List<Tile> queue = [tiles.first];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final key = '${current.x},${current.y}';

      if (visited.contains(key)) continue;
      visited.add(key);

      // Añadir vecinos adyacentes que estén en la lista de tiles
      for (final tile in tiles) {
        final tileKey = '${tile.x},${tile.y}';
        if (!visited.contains(tileKey) && _areAdjacent(current, tile)) {
          queue.add(tile);
        }
      }
    }

    return visited.length == tiles.length;
  }

  void _onEraseDragg(EraseDragg event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      final Board board = currentState.board;
      final updatedBoard = board.removeElement(event.eraseX, event.eraseY);
      emit(currentState.copyWith(board: updatedBoard));
    }
  }
}