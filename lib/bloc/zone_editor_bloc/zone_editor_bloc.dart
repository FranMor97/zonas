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

  void _onElementTypeSelected(ElementTypeSelected event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if(event.elementType.isSelectionTool){
      emit(currentState.copyWith(
        selectedElement: event.elementType,
        eraserMode: false,
        editMode: 'select',
        selectedTile: null,
        hasSelectedTile: false,
      ));}else{
        emit(currentState.copyWith(
          selectedElement: event.elementType,
          eraserMode: false,
          editMode: 'place',
        ));
      }
    }
  }

  void _onTileTapped(TileTapped event, Emitter<ZoneEditorState> emit) {
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
            emit(currentState.copyWith(selectedTile: tile, hasSelectedTile: true));
          } else {
            emit(currentState.copyWith(selectedTile: null, hasSelectedTile: false));
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

  void _saveToHistory(Board board) {
    _undoStack.addFirst(board);
    _redoStack.clear();

    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeLast();
    }
  }

  void _onTileDragged(TileDragged event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      if (currentState.editMode == 'place' && currentState.selectedElement != null) {
        final Board board = currentState.board;
        final updatedBoard = board.placeElement(event.x, event.y, currentState.selectedElement!);
        if (updatedBoard != board) {
          emit(currentState.copyWith(board: updatedBoard));
        }
      }
    }
  }

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

  void _onEditModeChanged(EditModeChanged event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      emit(currentState.copyWith(
        editMode: event.mode,
        eraserMode: event.mode == 'erase',
        selectedElement: event.mode == 'erase' ? null : currentState.selectedElement,
      ));
    }
  }

  void _onTileSelected(
    TileSelected event,
    Emitter<ZoneEditorState> emit,
  ) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      emit(currentState.copyWith(
        selectedTile: event.tile,
        hasSelectedTile: true,
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

  void _onBoardCleared(ClearBoard event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;
      final Board board = currentState.board;
      final boardUpdated = board.clear();
      _saveToHistory(board);
      emit(currentState.copyWith(board: boardUpdated));
    }
  }

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

  void _onDragEnded(DragEnded event, Emitter<ZoneEditorState> emit) {
    if (state is ZoneEditorLoaded) {
      final currentState = state as ZoneEditorLoaded;

      if (_undoStack.isNotEmpty && currentState.board != _undoStack.first) {
        _saveToHistory(currentState.board);
      }
    }
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
