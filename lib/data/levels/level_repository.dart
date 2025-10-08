import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/block.dart';
import '../../domain/entities/board.dart';

class LevelRepository {
  /// Loads a board from an asset json path.
  Future<Board> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final width = (json['width'] as int?) ?? 6;
    final height = (json['height'] as int?) ?? 6;
    final blocksJson = (json['blocks'] as List).cast<Map<String, dynamic>>();

    final blocks = <Block>[];
    for (final m in blocksJson) {
      blocks.add(Block(
        id: m['id'] as String,
        row: m['row'] as int,
        col: m['col'] as int,
        length: m['length'] as int,
        orientation:
        (m['orientation'] as String) == 'h' ? Orientation2D.h : Orientation2D.v,
        isTarget: (m['isTarget'] as bool?) ?? false,
      ));
    }

    _validate(width, height, blocks);
    return Board(width: width, height: height, blocks: blocks);
  }

  void _validate(int w, int h, List<Block> blocks) {
    // Exactly one target block
    if (blocks.where((b) => b.isTarget).length != 1) {
      throw StateError('Level must have exactly one target block.');
    }
    // Inside bounds & no overlaps
    final occ = <(int, int), String>{};
    for (final b in blocks) {
      for (final (r, c) in b.cells()) {
        if (r < 0 || r >= h || c < 0 || c >= w) {
          throw StateError('Block ${b.id} is out of bounds.');
        }
        final key = (r, c);
        if (occ.containsKey(key)) {
          throw StateError('Blocks ${b.id} and ${occ[key]} overlap.');
        }
        occ[key] = b.id;
      }
    }
  }
}
