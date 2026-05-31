import 'package:flutter/material.dart';

import 'package:zapbook/features/book_ingestion/presentation/pages/ingestion_page.dart';
import 'package:zapbook/theme/app_theme.dart';

class ZapBookApp extends StatelessWidget {
  const ZapBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZapBook',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const IngestionPage(),
    );
  }
}
