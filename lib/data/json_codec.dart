import '../engine/quantity.dart';
import '../engine/rational.dart';
import '../engine/token.dart';
import '../engine/tools/board_feet.dart';
import '../engine/tools/concrete.dart';
import '../engine/units.dart';
import '../state/calc_state.dart';
import '../state/settings.dart';

typedef Json = Map<String, Object?>;

/// Converts saved data to and from JSON. Every decoder throws
/// [FormatException] on bad input, so callers can fall back to defaults.
abstract final class JsonCodec {
  // Rational: "29/2" or "12".

  static String encodeRational(Rational r) => r.toString();

  static Rational decodeRational(Object? json) {
    if (json is! String) throw const FormatException('Expected a fraction');
    final parts = json.split('/');
    try {
      return switch (parts) {
        [final n] => Rational.fromBigInt(BigInt.parse(n)),
        [final n, final d] => Rational.fromBigInts(
          BigInt.parse(n),
          BigInt.parse(d),
        ),
        _ => throw FormatException('Bad fraction "$json"'),
      };
    } on ArgumentError {
      throw FormatException('Bad fraction "$json"');
    }
  }

  // Quantity

  static Json encodeQuantity(Quantity q) => {
    'v': encodeRational(q.value),
    'd': q.dimension,
  };

  static Quantity decodeQuantity(Object? json) {
    final map = _map(json);
    final dim = map['d'];
    if (dim is! int || dim < 0 || dim > Quantity.maxDimension) {
      throw const FormatException('Bad dimension');
    }
    return Quantity(decodeRational(map['v']), dim);
  }

  // Token

  static Json encodeToken(Token token) => switch (token) {
    DigitToken(:final digit) => {'t': 'digit', 'v': digit},
    DecimalPointToken() => {'t': 'point'},
    FractionToken(:final numerator, :final denominator) => {
      't': 'frac',
      'n': numerator,
      'd': denominator,
    },
    UnitToken(:final unit) => {'t': 'unit', 'v': unit.name},
    OpToken(:final op) => {'t': 'op', 'v': op.name},
    ValueToken(:final quantity) => {
      't': 'value',
      'q': encodeQuantity(quantity),
    },
  };

  static Token decodeToken(Object? json) {
    final map = _map(json);
    return switch (map['t']) {
      'digit' => switch (map['v']) {
        final int d when d >= 0 && d <= 9 => DigitToken(d),
        _ => throw const FormatException('Bad digit'),
      },
      'point' => const DecimalPointToken(),
      'frac' => switch ((map['n'], map['d'])) {
        (final int n, final int d) when n > 0 && n < d => FractionToken(n, d),
        _ => throw const FormatException('Bad fraction key'),
      },
      'unit' => UnitToken(_enum(Unit.values, map['v'])),
      'op' => OpToken(_enum(Op.values, map['v'])),
      'value' => ValueToken(decodeQuantity(map['q'])),
      _ => throw const FormatException('Unknown token'),
    };
  }

  // History

  static Json encodeHistoryEntry(HistoryEntry e) => {
    'expr': [for (final t in e.expression) encodeToken(t)],
    'result': encodeQuantity(e.result),
    'at': e.at.toIso8601String(),
  };

  static HistoryEntry decodeHistoryEntry(Object? json) {
    final map = _map(json);
    final expr = map['expr'];
    final at = DateTime.tryParse('${map['at']}');
    if (expr is! List || at == null) {
      throw const FormatException('Bad history entry');
    }
    return HistoryEntry(
      expression: [for (final t in expr) decodeToken(t)],
      result: decodeQuantity(map['result']),
      at: at,
    );
  }

  // Settings. Missing or unknown fields fall back to their defaults, so
  // settings saved by an older version still load.

  static Json encodeSettings(Settings s) => {
    'precision': s.precision,
    'lengthDisplay': s.lengthDisplay.name,
    'areaUnit': s.areaUnit.name,
    'volumeUnit': s.volumeUnit.name,
    'haptics': s.haptics,
    'bags': [
      for (final b in s.bags)
        {'lb': b.pounds, 'yield': encodeRational(b.yieldCubicFeet)},
    ],
    'codeMaxRiser': encodeRational(s.codeMaxRiser),
    'codeMinTread': encodeRational(s.codeMinTread),
    'lumberSizing': s.lumberSizing.name,
  };

  static Settings decodeSettings(Object? json) {
    final map = _map(json);
    final defaults = Settings();
    T or<T>(T Function() read, T fallback) {
      try {
        return read();
      } on FormatException {
        return fallback;
      }
    }

    final precision = map['precision'];
    return Settings(
      precision: precision is int && Settings.precisions.contains(precision)
          ? precision
          : defaults.precision,
      lengthDisplay: or(
        () => _enum(LengthDisplay.values, map['lengthDisplay']),
        defaults.lengthDisplay,
      ),
      areaUnit: or(
        () => _enum(AreaUnit.values, map['areaUnit']),
        defaults.areaUnit,
      ),
      volumeUnit: or(
        () => _enum(VolumeUnit.values, map['volumeUnit']),
        defaults.volumeUnit,
      ),
      haptics: map['haptics'] is bool
          ? map['haptics']! as bool
          : defaults.haptics,
      bags: or(() => _decodeBags(map['bags']), defaults.bags),
      codeMaxRiser: or(
        () => decodeRational(map['codeMaxRiser']),
        defaults.codeMaxRiser,
      ),
      codeMinTread: or(
        () => decodeRational(map['codeMinTread']),
        defaults.codeMinTread,
      ),
      lumberSizing: or(
        () => _enum(LumberSizing.values, map['lumberSizing']),
        defaults.lumberSizing,
      ),
    );
  }

  static List<BagSize> _decodeBags(Object? json) {
    if (json is! List || json.isEmpty) {
      throw const FormatException('Bad bags');
    }
    return [
      for (final item in json)
        () {
          final map = _map(item);
          final pounds = map['lb'];
          final yieldCuFt = decodeRational(map['yield']);
          if (pounds is! int || pounds <= 0 || yieldCuFt <= Rational.zero) {
            throw const FormatException('Bad bag');
          }
          return BagSize(
            pounds,
            yieldCuFt.numerator.toInt(),
            yieldCuFt.denominator.toInt(),
          );
        }(),
    ];
  }

  static Json _map(Object? json) {
    if (json is Map<String, Object?>) return json;
    throw const FormatException('Expected an object');
  }

  static T _enum<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw FormatException('Unknown value "$name"');
  }
}
