import 'package:flutter/material.dart';

import 'ui/home_shell.dart';
import 'ui/theme/colors.dart';

class EasyAddApp extends StatelessWidget {
  const EasyAddApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.tapeYellow,
      brightness: Brightness.dark,
      primary: AppColors.tapeYellow,
      onPrimary: AppColors.inkBlack,
      secondary: AppColors.tapeYellow,
      onSecondary: AppColors.inkBlack,
      surface: AppColors.caseGraphite,
      onSurface: AppColors.chalkWhite,
      error: AppColors.studRed,
    );
    return MaterialApp(
      title: 'EasyAdd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: AppColors.caseGraphite,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.caseGraphite,
          foregroundColor: AppColors.chalkWhite,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF26292D),
          showDragHandle: true,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2A2D31)),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.keySteel,
          selectedColor: AppColors.tapeYellow,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
          secondaryLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: AppColors.inkBlack,
          ),
          side: BorderSide.none,
          showCheckmark: false,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.tapeYellow
                  : AppColors.keySteel,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected)
                  ? AppColors.inkBlack
                  : AppColors.chalkWhite,
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.chalkWhite,
          contentTextStyle: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.inkBlack,
            fontWeight: FontWeight.w600,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      // Text grows with the system size, up to 2× so layouts stay usable.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 2, child: child!),
      home: HomeShell(key: HomeShell.globalKey),
    );
  }
}
