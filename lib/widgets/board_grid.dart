import 'package:flutter/material.dart';
import 'package:table_game/bloc/zone_editor_bloc/zone_editor_bloc.dart';
import 'package:table_game/models/board_components/board.dart';
import 'package:table_game/models/board_components/element_type.dart';
import 'package:table_game/models/board_components/tile.dart';
import 'package:table_game/widgets/placement_overlay.dart';
import 'package:table_game/widgets/tile_content.dart';

class BoardGrid extends StatefulWidget {
  final Board board;
  final Function(int x, int y) onTileTap;
  final Function(int x, int y)? onTileDrag;
  final Function(int x, int y)? onEraseDrag;
  final Function()? onDragEnd;
  final Tile? selectedTile;
  final bool showCoordinates;
  final String mode;
  final ElementType? selectedElement;
  final VoidCallback? onRightClick;
  final List<Tile> selectedTiles;
  final bool isMultiSelectMode;
  final ZoneEditorLoaded? editorState;

  const BoardGrid({
    Key? key,
    required this.board,
    required this.onTileTap,
    required this.mode,
    this.onTileDrag,
    this.selectedTile,
    this.onEraseDrag,
    this.onDragEnd,
    this.showCoordinates = false,
    this.selectedElement,
    this.onRightClick,
    this.selectedTiles = const [],
    this.isMultiSelectMode = false,
    this.editorState,
  }) : super(key: key);

  @override
  State<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends State<BoardGrid> {
  final ValueNotifier<Offset?> _mousePositionNotifier = ValueNotifier(null);
  bool _isHovering = false;

  @override
  void dispose() {
    _mousePositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double boardWidth = widget.board.config.columns * widget.board.config.tileSize;
    final double boardHeight = widget.board.config.rows * widget.board.config.tileSize;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) {
        setState(() => _isHovering = false);
        _mousePositionNotifier.value = null;
      },
      onHover: (event) {
        _mousePositionNotifier.value = event.localPosition;
      },
      child: GestureDetector(
        onSecondaryTap: widget.onRightClick,
        child: Container(
          width: boardWidth,
          height: boardHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              CustomPaint(
                size: Size(boardWidth, boardHeight),
                painter: _GridPainter(
                  columns: widget.board.config.columns,
                  rows: widget.board.config.rows,
                  cellSize: widget.board.config.tileSize,
                ),
              ),
              ...widget.board.tiles.map((tile) => _buildTileWidget(context, tile)),
              ..._buildSelectionOverlays(),
              ValueListenableBuilder<Offset?>(
                valueListenable: _mousePositionNotifier,
                builder: (context, localMousePosition, _) {
                  final showOverlay = widget.mode == 'place' &&
                      widget.selectedElement != null &&
                      !widget.selectedElement!.isSelectionTool &&
                      _isHovering &&
                      localMousePosition != null;
                  if (showOverlay) {
                    return PlacementOverlay(
                      elementType: widget.selectedElement!,
                      tileSize: widget.board.config.tileSize,
                      localMousePosition: localMousePosition,
                      board: widget.board,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSelectionOverlays() {
    List<Widget> overlays = [];

    if (widget.editorState != null) {
      final state = widget.editorState!;

      if (state.hasSelectedTile && state.selectedTile != null && !state.isMultiSelectMode) {
        final selectedTile = state.selectedTile!;

        if (selectedTile.isMerged && selectedTile.mergedGroupId != null) {
          final groupTiles = state.getMergedElementTiles(selectedTile.mergedGroupId!);
          for (final tile in groupTiles) {
            overlays.add(_buildSelectionOverlay(tile, Colors.blue, isMergedGroup: true));
          }
        } else {
          overlays.add(_buildSelectionOverlay(selectedTile, Colors.blue));
        }
      }

      if (state.isMultiSelectMode && state.selectedTiles.isNotEmpty) {
        Map<String, List<Tile>> mergedGroups = {};
        List<Tile> individualTiles = [];

        for (final tile in state.selectedTiles) {
          if (tile.isMerged && tile.mergedGroupId != null) {
            mergedGroups.putIfAbsent(tile.mergedGroupId!, () => []).add(tile);
          } else {
            individualTiles.add(tile);
          }
        }

        for (final group in mergedGroups.values) {
          for (final tile in group) {
            overlays.add(_buildSelectionOverlay(tile, Colors.lightBlue, isMergedGroup: true, isMultiSelect: true));
          }
        }

        for (final tile in individualTiles) {
          overlays.add(_buildSelectionOverlay(tile, Colors.lightBlue, isMultiSelect: true));
        }
      }
    }

    return overlays;
  }

  Widget _buildSelectionOverlay(
      Tile tile,
      Color color, {
        bool isMergedGroup = false,
        bool isMultiSelect = false,
      }) {
    return Positioned(
      left: (tile.x * widget.board.config.tileSize).toDouble(),
      top: (tile.y * widget.board.config.tileSize).toDouble(),
      width: widget.board.config.tileSize,
      height: widget.board.config.tileSize,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: isMergedGroup ? 3 : 2,
          ),
          color: isMultiSelect ? color.withOpacity(0.2) : Colors.transparent,
        ),
        child: isMergedGroup
            ? Container(
          decoration: BoxDecoration(color: color.withOpacity(0.1)),
          child: Center(
            child: Icon(
              Icons.link,
              color: color,
              size: 12,
            ),
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildTileWidget(BuildContext context, Tile tile) {
    final double x = (tile.x * widget.board.config.tileSize).toDouble();
    final double y = (tile.y * widget.board.config.tileSize).toDouble();
    final double size = widget.board.config.tileSize;

    return Positioned(
      left: x,
      top: y,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => widget.onTileTap(tile.x, tile.y),
        onSecondaryTap: widget.onRightClick,
        onPanUpdate: widget.onTileDrag != null
            ? (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localOffset = renderBox.globalToLocal(details.globalPosition);
          final int gridX = (localOffset.dx / widget.board.config.tileSize).floor();
          final int gridY = (localOffset.dy / widget.board.config.tileSize).floor();

          if (gridX >= 0 &&
              gridX < widget.board.config.columns &&
              gridY >= 0 &&
              gridY < widget.board.config.rows) {
            if (widget.mode == 'erase' && widget.onEraseDrag != null) {
              widget.onEraseDrag!(gridX, gridY);
            } else if (widget.onTileDrag != null) {
              widget.onTileDrag!(gridX, gridY);
            }
          }
        }
            : null,
        onPanEnd: widget.onDragEnd != null ? (details) => widget.onDragEnd!() : null,
        child: TileContent(
          tile: tile,
          size: size,
          showCoordinates: widget.showCoordinates,
          allTiles: widget.board.tiles,
          editorState: widget.editorState,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int columns;
  final int rows;
  final double cellSize;

  _GridPainter({
    required this.columns,
    required this.rows,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    for (int i = 0; i <= columns; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= rows; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
