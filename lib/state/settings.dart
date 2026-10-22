import '../engine/formatter.dart';
import '../engine/rational.dart';
import '../engine/tools/board_feet.dart';
import '../engine/tools/concrete.dart';
import '../engine/tools/stairs.dart';
import '../engine/units.dart';

/// Everything the user can change in the settings sheet.
final class Settings {
  Settings({
    this.precision = 16,
    this.lengthDisplay = LengthDisplay.feetInches,
    this.areaUnit = AreaUnit.squareFeet,
    this.volumeUnit = VolumeUnit.cubicFeet,
    this.haptics = true,
    this.bags = BagSize.defaults,
    Rational? codeMaxRiser,
    Rational? codeMinTread,
    this.lumberSizing = LumberSizing.nominal,
  }) : codeMaxRiser = codeMaxRiser ?? StairInput.defaultMaxRiser,
       codeMinTread = codeMinTread ?? StairInput.defaultTread;

  static const precisions = [2, 4, 8, 16, 32, 64];

  /// Lengths round to 1/[precision] inch.
  final int precision;
  final LengthDisplay lengthDisplay;
  final AreaUnit areaUnit;
  final VolumeUnit volumeUnit;
  final bool haptics;
  final List<BagSize> bags;
  final Rational codeMaxRiser;
  final Rational codeMinTread;
  final LumberSizing lumberSizing;

  FormatOptions get formatOptions => FormatOptions(
    precision: precision,
    lengthDisplay: lengthDisplay,
    areaUnit: areaUnit,
    volumeUnit: volumeUnit,
  );

  Settings copyWith({
    int? precision,
    LengthDisplay? lengthDisplay,
    AreaUnit? areaUnit,
    VolumeUnit? volumeUnit,
    bool? haptics,
    List<BagSize>? bags,
    Rational? codeMaxRiser,
    Rational? codeMinTread,
    LumberSizing? lumberSizing,
  }) => Settings(
    precision: precision ?? this.precision,
    lengthDisplay: lengthDisplay ?? this.lengthDisplay,
    areaUnit: areaUnit ?? this.areaUnit,
    volumeUnit: volumeUnit ?? this.volumeUnit,
    haptics: haptics ?? this.haptics,
    bags: bags ?? this.bags,
    codeMaxRiser: codeMaxRiser ?? this.codeMaxRiser,
    codeMinTread: codeMinTread ?? this.codeMinTread,
    lumberSizing: lumberSizing ?? this.lumberSizing,
  );
}
