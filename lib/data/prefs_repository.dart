import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/quantity.dart';
import '../state/calc_state.dart';
import '../state/settings.dart';
import 'json_codec.dart';

/// Saves settings, memory and history on the device.
///
/// Reads never fail: missing or damaged data gives the defaults. Writes run
/// in the background.
class PrefsRepository {
  PrefsRepository(this._prefs);

  static const _settingsKey = 'settings.v1';
  static const _memoryKey = 'memory.v1';
  static const _historyKey = 'history.v1';

  final SharedPreferences _prefs;

  Settings loadSettings() =>
      _read(_settingsKey, JsonCodec.decodeSettings) ?? Settings();

  void saveSettings(Settings settings) =>
      _write(_settingsKey, JsonCodec.encodeSettings(settings));

  Quantity? loadMemory() => _read(_memoryKey, JsonCodec.decodeQuantity);

  void saveMemory(Quantity? memory) => memory == null
      ? unawaited(_prefs.remove(_memoryKey))
      : _write(_memoryKey, JsonCodec.encodeQuantity(memory));

  List<HistoryEntry> loadHistory() =>
      _read(_historyKey, (json) {
        if (json is! List) throw const FormatException('Expected a list');
        return [for (final e in json) JsonCodec.decodeHistoryEntry(e)];
      }) ??
      const [];

  void saveHistory(List<HistoryEntry> history) => _write(_historyKey, [
    for (final e in history) JsonCodec.encodeHistoryEntry(e),
  ]);

  T? _read<T>(String key, T Function(Object? json) decode) {
    final text = _prefs.getString(key);
    if (text == null) return null;
    try {
      return decode(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  void _write(String key, Object json) =>
      unawaited(_prefs.setString(key, jsonEncode(json)));
}

/// Overridden in main() with the loaded preferences.
final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => throw UnimplementedError('Override prefsRepositoryProvider'),
);
