import 'package:flutter/material.dart';
import '../../../domain/entities/block.dart';

class BlockWidget extends StatelessWidget {
  final Block block;
  final double cellSize;
  final VoidCallback? onTap;

  const BlockWidget({
    super.key,
    required this.block,
    required this.cellSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Color scheme: target = red; others = themed blues/greys
    final color = block.isTarget
        ? Colors.redAccent
        : (block.orientation == Orientation2D.h
        ? Colors.blue.shade400
        : Colors.teal.shade400);

    // Rounded rect visually pleasing
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: (block.orientation == Orientation2D.h
              ? block.length
              : 1) *
              cellSize,
          height: (block.orientation == Orientation2D.v
              ? block.length
              : 1) *
              cellSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(blurRadius: 6, offset: Offset(0, 2), color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
