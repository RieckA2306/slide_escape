//This code implements the game board for a sliding puzzle.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/block.dart';
import '../controller/game_controller.dart';
import 'block_widget.dart';

/// BoardView is a Riverpod-powered StatefulWidget that renders the puzzle grid.
class BoardView extends ConsumerStatefulWidget {
  const BoardView({
    super.key,
    this.bossMode = false,
    this.bossExitRow = 3, // 0-based index: horizontal exit marker
    this.bossExitCol = 3, // 0-based index: vertical exit marker
    this.verticalAlignment = 0.0, // -1.0 (top) to 1.0 (bottom)
  });

  /// Indicates if special boss-level exit markers should be rendered.
  final bool bossMode;
  final int bossExitRow;
  final int bossExitCol;

  /// Controls the vertical position of the board within the parent container.
  final double verticalAlignment;

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  // Track the ID of the block currently being dragged
  String? _draggingId;
  // Local translation offsets for the active drag gesture
  double _dragDx = 0;
  double _dragDy = 0;

  @override
  Widget build(BuildContext context) {
    // Listen to the game state and access the controller via Riverpod
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final board = state.board;

    ///Layout Builder computes the size of the grid dynamicly.
    ///It takes the available space and computes the cellsize so that it looks the same on every screen
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the square size of the board based on available space
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / board.width;

        /// Calculates the current visual offset of a block,
        /// accounting for both its base position and active dragging.
        Offset blockOffset(Block b) {
          final baseX = b.col * cellSize;
          final baseY = b.row * cellSize;
          if (_draggingId == b.id) {
            final dx = b.orientation == Orientation2D.h ? _dragDx : 0;
            final dy = b.orientation == Orientation2D.v ? _dragDy : 0;
            return Offset(baseX + dx, baseY + dy);
          }
          return Offset(baseX, baseY);
        }

        /// Determines the movement limits in pixels for a block based on
        /// available empty space on the board.
        ({double minX, double maxX, double minY, double maxY}) pixelBounds(Block b) {
          final br = controller.boundsFor(b);
          return (
          minX: br.minCol * cellSize,
          maxX: br.maxCol * cellSize,
          minY: br.minRow * cellSize,
          maxY: br.maxRow * cellSize,
          );
        }

        /// Called when the user releases a block.
        /// Snaps the block to the nearest valid grid position and updates state.
        void onPanEndFor(Block b) {
          final off = blockOffset(b);
          final newCol = (off.dx / cellSize).round();
          final newRow = (off.dy / cellSize).round();

          final pb = pixelBounds(b);
          // Ensure the target position is within the calculated movement bounds
          final clampedCol = b.orientation == Orientation2D.h
              ? newCol.clamp((pb.minX / cellSize).round(), (pb.maxX / cellSize).round())
              : b.col;
          final clampedRow = b.orientation == Orientation2D.v
              ? newRow.clamp((pb.minY / cellSize).round(), (pb.maxY / cellSize).round())
              : b.row;

          // Execute movement logic in the controller
          controller.tryMove(b, toRow: clampedRow, toCol: clampedCol);

          // Reset local drag state
          setState(() { _draggingId = null; _dragDx = 0; _dragDy = 0; });
        }

        return Align(
          alignment: Alignment(0.0, widget.verticalAlignment),
          child: SizedBox(
            width: size,
            height: size,
            child: IgnorePointer(
              // Disable interactions if the game is over
              ignoring: state.solved || state.failed,
              child: Stack(
                children: [
                  // Layer 1: The background grid lines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(rows: board.height, cols: board.width),
                    ),
                  ),

                  // Layer 2: Exit markers (Visual indicators for the goal)
                  if (!widget.bossMode) ...[
                    // Standard mode: single marker on the right side
                    Positioned(
                      right: -5.5,
                      top: _firstTargetRow(board, fallback: 2) * cellSize + cellSize * 0.25,
                      child: _rightMarker(height: cellSize * 0.5),
                    ),
                  ] else ...[
                    // Boss mode: two markers (side and bottom)
                    Positioned(
                      right: -5.5,
                      top: widget.bossExitRow * cellSize + cellSize * 0.25,
                      child: _rightMarker(height: cellSize * 0.5),
                    ),
                    Positioned(
                      bottom: -5.5,
                      left: widget.bossExitCol * cellSize + cellSize * 0.25,
                      child: _bottomMarker(width: cellSize * 0.5),
                    ),
                  ],

                  // Layer 3: The actual game blocks
                  ...board.blocks.map((b) {
                    final off = blockOffset(b);
                    final w = (b.orientation == Orientation2D.h ? b.length : 1) * cellSize;
                    final h = (b.orientation == Orientation2D.v ? b.length : 1) * cellSize;

                    return AnimatedPositioned(
                      key: ValueKey(b.id),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeInOut,
                      left: off.dx,
                      top: off.dy,
                      width: w,
                      height: h,
                      child: GestureDetector(
                        onPanStart: (_) => setState(() {
                          _draggingId = b.id; _dragDx = 0; _dragDy = 0;
                        }),
                        onPanUpdate: (details) {
                          final pb = pixelBounds(b);
                          setState(() {
                            if (b.orientation == Orientation2D.h) {
                              // Restrict horizontal drag to the calculated bounds
                              _dragDx = (_dragDx + details.delta.dx)
                                  .clamp(pb.minX - b.col * cellSize, pb.maxX - b.col * cellSize);
                            } else {
                              // Restrict vertical drag to the calculated bounds
                              _dragDy = (_dragDy + details.delta.dy)
                                  .clamp(pb.minY - b.row * cellSize, pb.maxY - b.row * cellSize);
                            }
                          });
                        },
                        onPanEnd: (_) => onPanEndFor(b),
                        child: BlockWidget(block: b, cellSize: cellSize),
                      ),
                    );
                  }).toList(),

                  // Layer 4: Overlay when game ends
                  if (state.solved || state.failed)
                    Positioned.fill(child: Container(color: Colors.black.withOpacity(0.05))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Helper to find the grid row where the target block (the one that needs to exit) is located.
  int _firstTargetRow(board, {required int fallback}) {
    final list = board.blocks.where((x) => x.isTarget && x.orientation == Orientation2D.h).toList();
    if (list.isEmpty) return fallback;
    return list.first.row;
  }

  /// Visual widget for a vertical marker on the right edge.
  Widget _rightMarker({required double height}) => Container(
    width: 12, height: height,
    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
  );

  /// Visual widget for a horizontal marker on the bottom edge.
  Widget _bottomMarker({required double width}) => Container(
    width: width, height: 12,
    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
  );
}

/// CustomPainter to draw the grid lines of the game board.
class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  _GridPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Draw vertical lines
    for (var c = 0; c <= cols; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines
    for (var r = 0; r <= rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}