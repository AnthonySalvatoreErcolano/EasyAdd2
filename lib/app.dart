import 'package:flutter/material.dart';

import 'ui/theme/colors.dart';

class EasyAddApp extends StatelessWidget {
  const EasyAddApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyAdd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.caseGraphite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.tapeYellow,
          brightness: Brightness.dark,
          primary: AppColors.tapeYellow,
          surface: AppColors.caseGraphite,
        ),
      ),
      home: const _PlaceholderScreen(),
    );
  }
}

/// Stand-in until the calculator screen lands in Phase 4.
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'EasyAdd',
          style: TextStyle(
            color: AppColors.tapeYellow,
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
