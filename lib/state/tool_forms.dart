import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/entry_builder.dart';
import '../engine/evaluator.dart';
import '../engine/quantity.dart';
import '../engine/rational.dart';
import '../engine/token.dart';
import '../engine/tools/board_feet.dart';
import '../engine/tools/concrete.dart';
import '../engine/tools/stairs.dart';
import '../engine/units.dart';
import 'settings_controller.dart';

enum ToolKind { concrete, stairs, boardFeet, convert }

enum FieldKind {
  /// A tape-measure value. A plain number uses the field's default unit.
  length,

  /// A whole number of 1 or more.
  count,

  /// A plain number, such as a waste percent or a price.
  number,
}

/// One input on a tool screen. Each field is typed with the same keys as
/// the calculator, so `10' 6"` or even `8' + 4"` works.
final class ToolField {
  const ToolField(
    this.id,
    this.label,
    this.kind, {
    this.defaultUnit = Unit.inches,
    this.initial = const [],
  });

  final String id;
  final String label;
  final FieldKind kind;

  /// What a plain number means in a length field, such as feet for a slab
  /// length and inches for its depth.
  final Unit defaultUnit;
  final List<Token> initial;
}

// Choice keys and values.
const shapeChoice = 'shape';
const stairModeChoice = 'mode';
const sizingChoice = 'sizing';
const treadMode = 'tread';
const runMode = 'run';

const _one = [DigitToken(1)];

abstract final class ToolFields {
  static const length = ToolField(
    'length',
    'Length',
    FieldKind.length,
    defaultUnit: Unit.feet,
  );
  static const width = ToolField(
    'width',
    'Width',
    FieldKind.length,
    defaultUnit: Unit.feet,
  );
  static const depth = ToolField('depth', 'Depth', FieldKind.length);
  static const diameter = ToolField('diameter', 'Diameter', FieldKind.length);
  static const height = ToolField(
    'height',
    'Height',
    FieldKind.length,
    defaultUnit: Unit.feet,
  );
  static const count = ToolField(
    'count',
    'How many',
    FieldKind.count,
    initial: _one,
  );
  static const waste = ToolField(
    'waste',
    'Waste %',
    FieldKind.number,
    initial: [DigitToken(1), DigitToken(0)],
  );

  static const rise = ToolField('rise', 'Total rise', FieldKind.length);
  static const maxRiser = ToolField(
    'maxRiser',
    'Max riser',
    FieldKind.length,
    initial: [DigitToken(7), FractionToken(3, 4), UnitToken(Unit.inches)],
  );
  static const tread = ToolField(
    'tread',
    'Tread depth',
    FieldKind.length,
    initial: [DigitToken(1), DigitToken(0), UnitToken(Unit.inches)],
  );
  static const run = ToolField('run', 'Total run', FieldKind.length);

  static const thickness = ToolField(
    'thickness',
    'Thickness',
    FieldKind.length,
    initial: [DigitToken(2)],
  );
  static const boardWidth = ToolField(
    'boardWidth',
    'Width',
    FieldKind.length,
    initial: [DigitToken(6)],
  );
  static const boardLength = ToolField(
    'boardLength',
    'Length',
    FieldKind.length,
    defaultUnit: Unit.feet,
    initial: [DigitToken(8)],
  );
  static const quantity = ToolField(
    'quantity',
    'Quantity',
    FieldKind.count,
    initial: _one,
  );
  static const price = ToolField('price', r'$ per board ft', FieldKind.number);

  static const value = ToolField('value', 'Measurement', FieldKind.length);

  /// Every field a tool can show, in screen order.
  static List<ToolField> all(ToolKind tool) => switch (tool) {
    ToolKind.concrete => [length, width, depth, diameter, height, count, waste],
    ToolKind.stairs => [rise, maxRiser, tread, run],
    ToolKind.boardFeet => [thickness, boardWidth, boardLength, quantity, price],
    ToolKind.convert => [value],
  };

  /// The fields shown for the current choices.
  static List<ToolField> visible(ToolKind tool, Map<String, String> choices) =>
      switch (tool) {
        ToolKind.concrete =>
          choices[shapeChoice] == ConcreteShape.column.name
              ? [diameter, height, count, waste]
              : [length, width, depth, count, waste],
        ToolKind.stairs =>
          choices[stairModeChoice] == runMode
              ? [rise, maxRiser, run]
              : [rise, maxRiser, tread],
        _ => all(tool),
      };
}

final class ToolFormState {
  const ToolFormState({
    required this.tool,
    required this.entries,
    required this.active,
    this.choices = const {},
    this.editing = true,
  });

  final ToolKind tool;
  final Map<String, List<Token>> entries;

  /// The field the keypad types into.
  final String active;
  final Map<String, String> choices;

  /// Whether the keypad is showing. Done hides it so the full result shows;
  /// tapping a field brings it back.
  final bool editing;

  /// Whether the selected field is the last one, so Next becomes Done.
  bool get onLastField => fields.last.id == active;

  List<ToolField> get fields => ToolFields.visible(tool, choices);

  List<Token> tokensOf(ToolField field) => entries[field.id] ?? const [];

  /// The field's value in inches, or null when it is empty or not a length.
  Rational? inches(ToolField field) {
    final q = _evaluate(tokensOf(field));
    if (q == null) return null;
    if (q.isLength) return q.value;
    if (q.isNumber) return q.value * field.defaultUnit.toInches;
    return null;
  }

  /// The field's plain-number value, or null.
  Rational? number(ToolField field) {
    final q = _evaluate(tokensOf(field));
    return q != null && q.isNumber ? q.value : null;
  }

  /// The field's whole-number value of 1 or more, or null.
  int? count(ToolField field) {
    final n = number(field);
    return n != null && n.isInteger && n >= Rational.one
        ? n.numerator.toInt()
        : null;
  }

  ToolFormState copyWith({
    Map<String, List<Token>>? entries,
    String? active,
    Map<String, String>? choices,
    bool? editing,
  }) => ToolFormState(
    tool: tool,
    entries: entries ?? this.entries,
    active: active ?? this.active,
    choices: choices ?? this.choices,
    editing: editing ?? this.editing,
  );

  static Quantity? _evaluate(List<Token> tokens) {
    try {
      return Evaluator.evaluate(EntryBuilder.parse(tokens));
    } on CalcException {
      return null;
    }
  }
}

final toolFormProvider =
    NotifierProvider.family<ToolFormController, ToolFormState, ToolKind>(
      ToolFormController.new,
    );

class ToolFormController extends Notifier<ToolFormState> {
  ToolFormController(this.tool);

  final ToolKind tool;

  @override
  ToolFormState build() {
    final choices = switch (tool) {
      ToolKind.concrete => {shapeChoice: ConcreteShape.slab.name},
      ToolKind.stairs => {stairModeChoice: treadMode},
      ToolKind.boardFeet => {
        sizingChoice: ref.read(settingsProvider).lumberSizing.name,
      },
      ToolKind.convert => <String, String>{},
    };
    return ToolFormState(
      tool: tool,
      entries: {for (final f in ToolFields.all(tool)) f.id: f.initial},
      active: ToolFields.visible(tool, choices).first.id,
      choices: choices,
    );
  }

  void select(ToolField field) =>
      state = state.copyWith(active: field.id, editing: true);

  /// Moves the keypad to the next field. On the last field, hides the
  /// keypad instead.
  void selectNext() {
    if (state.onLastField) {
      done();
      return;
    }
    final fields = state.fields;
    final i = fields.indexWhere((f) => f.id == state.active);
    state = state.copyWith(active: fields[i + 1].id);
  }

  /// Hides the keypad.
  void done() => state = state.copyWith(editing: false);

  /// The field the keypad types into.
  ToolField get activeField =>
      state.fields.firstWhere((f) => f.id == state.active);

  bool canPress(Token token) {
    final tokens = state.entries[state.active] ?? const [];
    return EntryBuilder.canAppend(tokens, token) ||
        (token is OpToken && tokens.isNotEmpty && tokens.last is OpToken);
  }

  void input(Token token) {
    final tokens = state.entries[state.active] ?? const [];
    if (EntryBuilder.canAppend(tokens, token)) {
      _setActive([...tokens, token]);
    } else if (token is OpToken &&
        tokens.isNotEmpty &&
        tokens.last is OpToken) {
      _setActive([...tokens.sublist(0, tokens.length - 1), token]);
    }
  }

  void backspace() {
    final tokens = state.entries[state.active] ?? const [];
    if (tokens.isNotEmpty) _setActive(tokens.sublist(0, tokens.length - 1));
  }

  void clearField() => _setActive(const []);

  void setChoice(String key, String value) {
    final choices = {...state.choices, key: value};
    final visible = ToolFields.visible(tool, choices);
    final stillShown = visible.any((f) => f.id == state.active);
    state = state.copyWith(
      choices: choices,
      active: stillShown ? null : visible.first.id,
    );
  }

  /// Puts every field back to its starting value.
  void reset() {
    ref.invalidateSelf();
  }

  void _setActive(List<Token> tokens) =>
      state = state.copyWith(entries: {...state.entries, state.active: tokens});
}

// Results. Each is null until the inputs it needs are filled in and valid.

final concreteResultProvider = Provider<ConcreteResult?>((ref) {
  final form = ref.watch(toolFormProvider(ToolKind.concrete));
  final bags = ref.watch(settingsProvider.select((s) => s.bags));
  final count = form.count(ToolFields.count);
  final waste = form.number(ToolFields.waste) ?? Rational.zero;
  if (count == null) return null;

  final ConcreteInput input;
  if (form.choices[shapeChoice] == ConcreteShape.column.name) {
    final diameter = form.inches(ToolFields.diameter);
    final height = form.inches(ToolFields.height);
    if (diameter == null || height == null) return null;
    input = ConcreteInput.column(
      diameter: diameter,
      height: height,
      count: count,
      wastePercent: waste,
      bags: bags,
    );
  } else {
    final length = form.inches(ToolFields.length);
    final width = form.inches(ToolFields.width);
    final depth = form.inches(ToolFields.depth);
    if (length == null || width == null || depth == null) return null;
    input = ConcreteInput.slab(
      length: length,
      width: width,
      depth: depth,
      count: count,
      wastePercent: waste,
      bags: bags,
    );
  }
  return _orNull(() => Concrete.calculate(input));
});

final stairsResultProvider = Provider<StairResult?>((ref) {
  final form = ref.watch(toolFormProvider(ToolKind.stairs));
  final settings = ref.watch(settingsProvider);
  final rise = form.inches(ToolFields.rise);
  final maxRiser = form.inches(ToolFields.maxRiser);
  if (rise == null || maxRiser == null) return null;

  final byRun = form.choices[stairModeChoice] == runMode;
  final tread = byRun ? null : form.inches(ToolFields.tread);
  final run = byRun ? form.inches(ToolFields.run) : null;
  if (tread == null && run == null) return null;

  return _orNull(
    () => Stairs.calculate(
      StairInput(
        totalRise: rise,
        maxRiser: maxRiser,
        treadDepth: tread,
        totalRun: run,
        codeMaxRiser: settings.codeMaxRiser,
        codeMinTread: settings.codeMinTread,
      ),
    ),
  );
});

final boardFeetResultProvider = Provider<BoardResult?>((ref) {
  final form = ref.watch(toolFormProvider(ToolKind.boardFeet));
  final thickness = form.inches(ToolFields.thickness);
  final width = form.inches(ToolFields.boardWidth);
  final length = form.inches(ToolFields.boardLength);
  final quantity = form.count(ToolFields.quantity);
  if (thickness == null ||
      width == null ||
      length == null ||
      quantity == null) {
    return null;
  }
  return _orNull(
    () => BoardFeet.calculate(
      BoardInput(
        thickness: thickness,
        width: width,
        length: length,
        quantity: quantity,
        pricePerBoardFoot: form.number(ToolFields.price),
        sizing: form.choices[sizingChoice] == LumberSizing.actual.name
            ? LumberSizing.actual
            : LumberSizing.nominal,
      ),
    ),
  );
});

/// The measurement to convert, as a length in inches.
final convertValueProvider = Provider<Quantity?>((ref) {
  final form = ref.watch(toolFormProvider(ToolKind.convert));
  final inches = form.inches(ToolFields.value);
  return inches == null ? null : Quantity.inches(inches);
});

T? _orNull<T>(T Function() calculate) {
  try {
    return calculate();
  } on ArgumentError {
    return null;
  }
}
