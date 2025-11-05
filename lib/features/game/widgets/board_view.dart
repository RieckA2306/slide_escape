import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/block.dart';
import '../controller/game_controller.dart';
import 'block_widget.dart';

class BoardView extends ConsumerStatefulWidget {
  const BoardView({
    super.key,
    this.bossMode = false,
    this.bossExitRow = 3, // 0-based: visual marker
    this.bossExitCol = 3, // 0-based: visual marker
  });

  /// When true, render two exit markers (right edge at row, bottom edge at col).
  final bool bossMode;
  final int bossExitRow;
  final int bossExitCol;

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  String? _draggingId;
  double _dragDx = 0;
  double _dragDy = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    final board = state.board;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / board.width;

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

        ({double minX, double maxX, double minY, double maxY}) pixelBounds(Block b) {
          final br = controller.boundsFor(b);
          return (
          minX: br.minCol * cellSize,
          maxX: br.maxCol * cellSize,
          minY: br.minRow * cellSize,
          maxY: br.maxRow * cellSize,
          );
        }

        void onPanEndFor(Block b) {
          final off = blockOffset(b);
          final newCol = (off.dx / cellSize).round();
          final newRow = (off.dy / cellSize).round();

          final pb = pixelBounds(b);
          final clampedCol = b.orientation == Orientation2D.h
              ? newCol.clamp((pb.minX / cellSize).round(), (pb.maxX / cellSize).round())
              : b.col;
          final clampedRow = b.orientation == Orientation2D.v
              ? newRow.clamp((pb.minY / cellSize).round(), (pb.maxY / cellSize).round())
              : b.row;

          controller.tryMove(b, toRow: clampedRow, toCol: clampedCol);

          setState(() { _draggingId = null; _dragDx = 0; _dragDy = 0; });
        }

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: IgnorePointer(
              ignoring: state.solved || state.failed,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GridPainter(rows: board.height, cols: board.width),
                    ),
                  ),

                  // Exit markers
                  if (!widget.bossMode) ...[
                    // Standard: show right-edge marker roughly at the row of the (first) target block
                    Positioned(
                      right: -8,
                      top: _firstTargetRow(board, fallback: 2) * cellSize + cellSize * 0.25,
                      child: _rightMarker(height: cellSize * 0.5),
                    ),
                  ] else ...[
                    // Boss: right-edge marker at bossExitRow
                    Positioned(
                      right: -8,
                      top: widget.bossExitRow * cellSize + cellSize * 0.25,
                      child: _rightMarker(height: cellSize * 0.5),
                    ),
                    // Boss: bottom-edge marker at bossExitCol
                    Positioned(
                      bottom: -8,
                      left: widget.bossExitCol * cellSize + cellSize * 0.25,
                      child: _bottomMarker(width: cellSize * 0.5),
                    ),
                  ],

                  // Blocks (draggable)
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
                        onPanStart: (_) => setState(() { _draggingId = b.id; _dragDx = 0; _dragDy = 0; }),
                        onPanUpdate: (details) {
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

  int _firstTargetRow(board, {required int fallback}) {
    final list = board.blocks.where((x) => x.isTarget && x.orientation == Orientation2D.h).toList();
    if (list.isEmpty) return fallback;
    return list.first.row;
  }

  Widget _rightMarker({required double height}) => Container(
    width: 12, height: height,
    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
  );

  Widget _bottomMarker({required double width}) => Container(
    width: width, height: 12,
    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
  );
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  _GridPainter({required this.rows, required this.cols});

  @override
  void paint(Canvas canvas, Size size) {
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
