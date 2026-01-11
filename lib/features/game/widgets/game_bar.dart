import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/level.dart';
import '../controller/game_controller.dart';
import '../state/game_state.dart';

class GameBar extends ConsumerWidget implements PreferredSizeWidget {
  final Level level;
  final VoidCallback onExitRequest;
  final String Function(int? secs) fmtTime;

  const GameBar({
    super.key,
    required this.level,
    required this.onExitRequest,
    required this.fmtTime,
  });

  // --- ANPASSBARE HEADER-EINSTELLUNGEN ---
  static const double headerIconSize = 28.0;
  static const double arrowIconSize = 38.0;
  static const double headerFontSize = 18.0;
  static const FontWeight headerFontWeight = FontWeight.bold;

  static const double titleFontSize = 22.0;
  static const FontWeight titleFontWeight = FontWeight.w400;

  static const double iconTextSpacing = 8.0;
  static const double itemPadding = 20.0;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final isBoss = level.type == LevelType.boss;

    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.5),
      elevation: 0,
      leading: IconButton(
        icon: Image.asset(
          "assets/game_header/arrow_left.png",
          width: arrowIconSize,
          height: arrowIconSize,
        ),
        onPressed: onExitRequest,
      ),
      title: Text(
        'Level ${level.id} • ${level.difficulty}',
        style: const TextStyle(
          fontSize: titleFontSize,
          fontWeight: titleFontWeight,
        ),
      ),
      actions: [
        if (isBoss)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: itemPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/game_header/boss.png",
                  width: 38,
                  height: 38,
                ),
              ],
            ),
          ),

        // Move Counter
        if (state.moveLimit != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: itemPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/game_header/dart_board.png",
                  width: headerIconSize,
                  height: headerIconSize,
                ),
                const SizedBox(width: iconTextSpacing),
                Text(
                  '${state.movesLeft}', // Nutzt nun den berechneten Getter aus dem State
                  style: const TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: headerFontWeight,
                  ),
                ),
              ],
            ),
          ),

        // Timer
        if (state.timeLimit != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: itemPadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/game_header/time_clock.png",
                  width: headerIconSize,
                  height: headerIconSize,
                ),
                const SizedBox(width: iconTextSpacing),
                Text(
                  fmtTime(state.timeLeft),
                  style: const TextStyle(
                    fontSize: headerFontSize,
                    fontWeight: headerFontWeight,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}