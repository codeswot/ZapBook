import 'package:flutter/material.dart';
import 'package:zapbook/core/presentation/theme/app_theme.dart';

import 'package:zapbook/core/presentation/widgets/app_fade_overlay.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_chrome_slot.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_footer.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_header.dart';
import 'package:zapbook/features/book_reader/presentation/widgets/reader_loading.dart';

class ReaderOpeningScaffold extends StatelessWidget {
  const ReaderOpeningScaffold({
    required this.title,
    required this.totalPages,
    required this.chromeVisible,
    required this.onTap,
    required this.onBack,
    super.key,
  });

  final String title;
  final int totalPages;
  final bool chromeVisible;
  final VoidCallback onTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.paper,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: const ReaderPageLoading(message: 'Opening…'),
            ),
          ),
          AppFadeOverlay.top(color: colors.paper, height: 130),
          ReaderChromeSlot(
            alignment: Alignment.topCenter,
            visible: chromeVisible,
            fromTop: true,
            child: ReaderHeader(
              title: title,
              chapterTitle: '',
              onBack: onBack,
              onSearch: () {},
              onOpenContents: () {},
            ),
          ),
          AppFadeOverlay.bottom(color: colors.paper, height: 135),
          ReaderChromeSlot(
            alignment: Alignment.bottomCenter,
            visible: chromeVisible,
            fromTop: false,
            child: ReaderFooter(
              progress: 0,
              currentPage: 0,
              totalPages: totalPages,
            ),
          ),
        ],
      ),
    );
  }
}
