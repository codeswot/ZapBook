import 'package:flutter_test/flutter_test.dart';
import 'package:reading_progress/reading_progress.dart';
import 'package:zapbook/features/book_reader/presentation/bloc/reading_progress_cubit.dart';

void main() {
  test('cubit bridges events through the engine to completion', () async {
    var now = 0;
    final effects = <ProgressEffect>[];
    final cubit = ReadingProgressCubit.forDeps(
      deps: ReadingDeps(density: const BookDensity(pageWords: [238, 238])),
      clock: () => now,
      heartbeat: const Duration(hours: 1),
    );
    cubit.effects.listen(effects.add);

    cubit.start();
    expect(cubit.state.currentPage, 0);

    for (final t in [10000, 20000, 30000, 40000]) {
      now = t;
      cubit.tick();
    }

    now = 40500;
    cubit.openPage(1);
    expect(cubit.state.completedPages.contains(0), isTrue);

    for (final t in [50500, 60500, 70500, 80500]) {
      now = t;
      cubit.tick();
    }

    now = 90000;
    cubit.closeSession();

    expect(cubit.state.bookCompleted, isTrue);
    expect(cubit.state.completedPages.length, 2);
    expect(effects.whereType<BookCompleted>(), isNotEmpty);

    await cubit.close();
  });

  test('pause stops tick accrual', () async {
    var now = 0;
    final cubit = ReadingProgressCubit.forDeps(
      deps: ReadingDeps(density: const BookDensity(pageWords: [238])),
      clock: () => now,
      heartbeat: const Duration(hours: 1),
    );

    cubit.start();
    now = 1000;
    cubit.pause();
    now = 50000;
    cubit.tick();

    expect(cubit.state.open!.engagedMs, 0);
    await cubit.close();
  });
}
