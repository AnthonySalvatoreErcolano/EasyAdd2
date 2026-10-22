import 'dart:convert';

import 'package:easyadd/data/json_codec.dart';
import 'package:easyadd/data/prefs_repository.dart';
import 'package:easyadd/engine/quantity.dart';
import 'package:easyadd/engine/rational.dart';
import 'package:easyadd/engine/token.dart';
import 'package:easyadd/engine/tools/board_feet.dart';
import 'package:easyadd/engine/tools/concrete.dart';
import 'package:easyadd/engine/units.dart';
import 'package:easyadd/state/calc_controller.dart';
import 'package:easyadd/state/calc_state.dart';
import 'package:easyadd/state/settings.dart';
import 'package:easyadd/state/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('settings controller', () {
    test('starts with defaults', () async {
      final (c, _) = await makeContainer();
      final s = c.read(settingsProvider);
      expect(s.precision, 16);
      expect(s.lengthDisplay, LengthDisplay.feetInches);
      expect(s.haptics, isTrue);
      expect(s.codeMaxRiser, Rational(31, 4));
      expect(s.formatOptions.precision, 16);
    });

    test('changes are saved and loaded', () async {
      final (c, prefs) = await makeContainer();
      c
          .read(settingsProvider.notifier)
          .update(
            (s) => s.copyWith(
              precision: 32,
              lengthDisplay: LengthDisplay.millimeters,
              areaUnit: AreaUnit.squareMeters,
              volumeUnit: VolumeUnit.cubicYards,
              haptics: false,
              bags: const [BagSize(50, 3, 8)],
              codeMaxRiser: Rational(8),
              codeMinTread: Rational(9),
              lumberSizing: LumberSizing.actual,
            ),
          );
      final (reloaded, _) = await makeContainer({
        'settings.v1': prefs.getString('settings.v1')!,
      });
      final s = reloaded.read(settingsProvider);
      expect(s.precision, 32);
      expect(s.lengthDisplay, LengthDisplay.millimeters);
      expect(s.areaUnit, AreaUnit.squareMeters);
      expect(s.volumeUnit, VolumeUnit.cubicYards);
      expect(s.haptics, isFalse);
      expect(s.bags.single.pounds, 50);
      expect(s.bags.single.yieldCubicFeet, Rational(3, 8));
      expect(s.codeMaxRiser, Rational(8));
      expect(s.codeMinTread, Rational(9));
      expect(s.lumberSizing, LumberSizing.actual);
    });

    test('reset restores the defaults', () async {
      final (c, _) = await makeContainer();
      final notifier = c.read(settingsProvider.notifier);
      notifier.update((s) => s.copyWith(precision: 4));
      notifier.reset();
      expect(c.read(settingsProvider).precision, 16);
    });
  });

  group('damaged saved data falls back to defaults', () {
    test('settings that are not JSON', () async {
      final (c, _) = await makeContainer({'settings.v1': 'not json'});
      expect(c.read(settingsProvider).precision, 16);
    });

    test('settings with some bad fields keep the good ones', () async {
      final (c, _) = await makeContainer({
        'settings.v1': jsonEncode({
          'precision': 5,
          'lengthDisplay': 'bogus',
          'haptics': 'yes',
          'areaUnit': 'squareYards',
          'bags': <Object>[],
          'codeMaxRiser': '1/0',
        }),
      });
      final s = c.read(settingsProvider);
      expect(s.precision, 16);
      expect(s.lengthDisplay, LengthDisplay.feetInches);
      expect(s.haptics, isTrue);
      expect(s.areaUnit, AreaUnit.squareYards);
      expect(s.bags, BagSize.defaults);
      expect(s.codeMaxRiser, Rational(31, 4));
    });

    test('memory and history', () async {
      final (c, _) = await makeContainer({
        'memory.v1': '{"v": "x", "d": 1}',
        'history.v1': '{"not": "a list"}',
      });
      expect(c.read(calcProvider).memory, isNull);
      expect(c.read(calcProvider).history, isEmpty);
    });
  });

  group('JSON codec', () {
    test('every token round-trips', () {
      final tokens = <Token>[
        const DigitToken(7),
        const DecimalPointToken(),
        const FractionToken(3, 16),
        const UnitToken(Unit.centimeters),
        const OpToken(Op.divide),
        ValueToken(Quantity(Rational(-29, 2), 2)),
      ];
      final decoded = [
        for (final t in tokens)
          JsonCodec.decodeToken(
            jsonDecode(jsonEncode(JsonCodec.encodeToken(t))),
          ),
      ];
      expect((decoded[0] as DigitToken).digit, 7);
      expect(decoded[1], isA<DecimalPointToken>());
      expect((decoded[2] as FractionToken).denominator, 16);
      expect((decoded[3] as UnitToken).unit, Unit.centimeters);
      expect((decoded[4] as OpToken).op, Op.divide);
      expect(
        (decoded[5] as ValueToken).quantity,
        Quantity(Rational(-29, 2), 2),
      );
    });

    test('history entries round-trip', () {
      final entry = HistoryEntry(
        expression: const [DigitToken(1), OpToken(Op.add), DigitToken(2)],
        result: Quantity.number(Rational(3)),
        at: DateTime.utc(2026, 10, 22, 16),
      );
      final back = JsonCodec.decodeHistoryEntry(
        jsonDecode(jsonEncode(JsonCodec.encodeHistoryEntry(entry))),
      );
      expect(back.result, entry.result);
      expect(back.at, entry.at);
      expect(back.expression, hasLength(3));
    });

    test('bad values are rejected with FormatException', () {
      final bad = <void Function()>[
        () => JsonCodec.decodeRational(3),
        () => JsonCodec.decodeRational('abc'),
        () => JsonCodec.decodeRational('1/0'),
        () => JsonCodec.decodeRational('1/2/3'),
        () => JsonCodec.decodeQuantity({'v': '1', 'd': 4}),
        () => JsonCodec.decodeQuantity('nope'),
        () => JsonCodec.decodeToken({'t': 'digit', 'v': 12}),
        () => JsonCodec.decodeToken({'t': 'frac', 'n': 3, 'd': 2}),
        () => JsonCodec.decodeToken({'t': 'unit', 'v': 'furlongs'}),
        () => JsonCodec.decodeToken({'t': 'mystery'}),
        () => JsonCodec.decodeHistoryEntry({'expr': 'x', 'at': 'y'}),
      ];
      for (final decode in bad) {
        expect(decode, throwsFormatException);
      }
    });

    test('bad bag sizes fall back to the defaults', () {
      for (final bags in [
        'x',
        <Object>[],
        [
          {'lb': -1, 'yield': '1/2'},
        ],
        [
          {'lb': 60, 'yield': '0'},
        ],
      ]) {
        expect(JsonCodec.decodeSettings({'bags': bags}).bags, BagSize.defaults);
      }
    });

    test(
      'settings that are not an object give defaults via the repository',
      () {
        expect(() => JsonCodec.decodeSettings([1, 2]), throwsFormatException);
        expect(JsonCodec.decodeSettings(<String, Object?>{}).precision, 16);
      },
    );
  });

  test('the repository must be provided by main()', () {
    final container = ProviderContainer.test();
    expect(() => container.read(prefsRepositoryProvider), throwsA(anything));
  });

  test('Settings.copyWith keeps unchanged fields', () {
    final s = Settings(precision: 8).copyWith(haptics: false);
    expect(s.precision, 8);
    expect(s.haptics, isFalse);
  });
}
