import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs_repository.dart';
import 'settings.dart';

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() => ref.read(prefsRepositoryProvider).loadSettings();

  /// Applies [change] and saves the result, for example
  /// `update((s) => s.copyWith(precision: 8))`.
  void update(Settings Function(Settings current) change) {
    state = change(state);
    ref.read(prefsRepositoryProvider).saveSettings(state);
  }

  void reset() => update((_) => Settings());
}
