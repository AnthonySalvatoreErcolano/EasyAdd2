import 'package:flutter/material.dart';

import 'calculator_screen.dart';
import 'theme/colors.dart';
import 'theme/typography.dart';
import 'tools/tools_screen.dart';

/// Two tabs: Calculator and Tools. Each keeps its state when switching.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Lets screenshot mode open a tool without taps.
  static final globalKey = GlobalKey<HomeShellState>();

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _toolsNavigator = GlobalKey<NavigatorState>();

  /// Switches to the Tools tab and opens [screen].
  void openTool(Widget screen) {
    setState(() => _tab = 1);
    _toolsNavigator.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _select(int tab) {
    if (tab == _tab && tab == 1) {
      // Tapping Tools again goes back to the list.
      _toolsNavigator.currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            // The calculator is a fixed instrument layout; its text grows
            // only a little with the system text size.
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: const CalculatorScreen(),
            ),
            Navigator(
              key: _toolsNavigator,
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => const ToolsScreen()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: _TabBar(selected: _tab, onSelect: _select),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tab(int index, IconData icon, String label) {
      final active = index == selected;
      final color = active ? AppColors.tapeYellow : AppColors.chalkDim;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onSelect(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppText.style(
                    11.5,
                    weight: active ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.caseGraphite,
        border: Border(top: BorderSide(color: AppColors.keySteel)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              tab(0, Icons.calculate_outlined, 'Calculator'),
              tab(1, Icons.handyman_outlined, 'Tools'),
            ],
          ),
        ),
      ),
    );
  }
}
