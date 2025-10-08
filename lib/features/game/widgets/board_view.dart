import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/block.dart';
import '../../../domain/services/rules.dart';
import '../controller/game_controller.dart';
import 'block_widget.dart';

class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key});

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  /// Transient drag state
  String? _draggingId;
  double _dragDx = 0; // pixels along x (used for horizontal blocks)
  double _dragDy = 0; // pixels along y (used for vertical blocks)

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final board = state.board;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep board square and centered
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / board.width;

        // Helpers to convert block row/col (plus drag) -> pixel offsets
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

        // Drag limit in pixels for the current block
        ({double minX, double maxX, double minY, double maxY}) pixelBounds(Block b) {
          final br = controller.boundsFor(b);
          final minX = br.minCol * cellSize;
          final maxX = br.maxCol * cellSize;
          final minY = br.minRow * cellSize;
          final maxY = br.maxRow * cellSize;
          return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
        }

        // Snap the dragged block to the nearest legal cell on release
        void onPanEndFor(Block b) {
          final off = blockOffset(b);
          final newCol = (off.dx / cellSize).round();
          final newRow = (off.dy / cellSize).round();

          // Clamp to legal bounds just in case of rounding overflows
          final pb = pixelBounds(b);
          final clampedCol = b.orientation == Orientation2D.h
              ? newCol.clamp((pb.minX / cellSize).round(), (pb.maxX / cellSize).round())
              : b.col;
          final clampedRow = b.orientation == Orientation2D.v
              ? newRow.clamp((pb.minY / cellSize).round(), (pb.maxY / cellSize).round())
              : b.row;

          controller.tryMove(
            b,
            toRow: clampedRow,
            toCol: clampedCol,
          );

          // Reset transient drag deltas
          setState(() {
            _draggingId = null;
            _dragDx = 0;
            _dragDy = 0;
          });
        }

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // Board background grid
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GridPainter(rows: board.height, cols: board.width),
                  ),
                ),

                // Exit indicator on the right edge aligned with target row
                Positioned(
                  right: -8,
                  top: board.target.row * cellSize + cellSize * 0.25,
                  child: Container(
                    width: 12,
                    height: cellSize * 0.5,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

                // Blocks (draggable)
                ...board.blocks.map((b) {
                  final off = blockOffset(b);
                  final width = (b.orientation == Orientation2D.h ? b.length : 1) * cellSize;
                  final height = (b.orientation == Orientation2D.v ? b.length : 1) * cellSize;

                  return AnimatedPositioned(
                    key: ValueKey(b.id),
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeInOut,
                    left: off.dx,
                    top: off.dy,
                    width: width,
                    height: height,
                    child: GestureDetector(
                      onPanStart: (_) {
                        setState(() {
                          _draggingId = b.id;
                          _dragDx = 0;
                          _dragDy = 0;
                        });
                      },
                      onPanUpdate: (details) {
                        // Lock movement to orientation
                        final pb = pixelBounds(b);
                        setState(() {
                          if (b.orientation == Orientation2D.h) {
                            _dragDx = (_dragDx + details.delta.dx)
                                .clamp(pb.minX - b.col * cellSize, pb.maxX - b.col * cellSize);
                          } else {
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
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;

  _GridPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
    // Simple subtle grid for aesthetics
    final paint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (var c = 0; c <= cols; c++) {
      final x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var r = 0; r <= rows; r++) {
      final y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
