# EasyAdd 2.0 — Build Scaffold

The step-by-step plan for rebuilding EasyAdd from scratch in Flutter and shipping it as **version 2.0.0** under the existing App Store listing.

| | |
| --- | --- |
| App name (store and home screen) | **EasyAdd** |
| Bundle id | `com.anthonyercolano.constructioncalculator` |
| App Store | [id6755840605](https://apps.apple.com/us/app/easyadd/id6755840605) |
| Version | `2.0.0+10` (the live MAUI build is 1.1.1, build 9) |
| Repo | https://github.com/AnthonySalvatoreErcolano/EasyAdd2.git |
| Toolchain on this Mac | Flutter 3.41.3 (Dart 3.11.1), Xcode 27.1, CocoaPods, gh |
| Minimum iOS | 15.0 (same as today, so no current user loses updates) |
| Platforms | iOS first (ships 2.0.0), then Android (Phase 8) |
| Brand yellow | `#FEC517`, taken from `EasyAddIcon.png` |

The fuller design rationale is in the plan doc: https://claude.ai/artifact/MxmoZ87H7H63K4gHCuKVkJ

---

## Scope of 2.0

**Core calculator**
- Digit keys 0–9 and `.`, plus fraction keys (eighths on the main strip, sixteenths behind a `16ths` toggle).
- Feet and inches entry, such as `1' 2 1/2"`, with `+ − × ÷`, standard precedence, backspace, C/AC, and repeat-equals.
- Results formatted like a tape measure, such as `3' 4 5/8"`, with stacked fractions. Precision can be set from 1/2 to 1/32 (default 1/16), and a `≈` mark shows when a result was rounded.
- Memory (MC, MR, M+, M−), a history tape of the last 50 results, copy on long-press, and haptics.

**Added in 2.0 (formerly "later")**
1. **Area and volume.** length × length gives area, and length × length × length gives volume. Results switch between sq in / sq ft / sq yd / m² and cu in / cu ft / cu yd / m³.
2. **Concrete tool.** Slab, footing or column dimensions give cubic yards, with a waste % and a count of 60 lb and 80 lb bags.
3. **Metric conversion.** Enter mm, cm or m and mix them with imperial units. Any result can be shown in metric. Conversion is exact: 1 in = 25.4 mm.
4. **Stair stringer tool.** Total rise (plus optional run or tread depth) gives the riser count, riser height, tread count, total run, the diagonal and the angle, with a check against code limits.
5. **Board-foot tool.** Thickness × width × length × quantity gives board feet and an optional total price.
6. **Home-screen widget.** The last result and recent history on the home screen, with taps that open the app or a tool.

---

## Phase 0 — Repo and project setup

- [x] `git init -b main` in `/Users/accoric/Desktop/repos/EasyAdd`.
- [x] Create the Flutter project in place:
      `flutter create --org com.anthonyercolano --project-name easyadd --platforms ios,android .`
- [x] Set the iOS bundle id. In `ios/Runner.xcodeproj/project.pbxproj`, change every `PRODUCT_BUNDLE_IDENTIFIER = com.anthonyercolano.easyadd` to `com.anthonyercolano.constructioncalculator` (the RunnerTests target gets `.RunnerTests` appended).
- [x] In `ios/Runner/Info.plist`, set `CFBundleDisplayName` = `EasyAdd`, `CFBundleName` = `EasyAdd`, and portrait-only orientations for iPhone.
- [x] Set the iOS deployment target to 15.0 in the Podfile and the Xcode project.
- [x] Set Android `applicationId` = `com.anthonyercolano.constructioncalculator` and the label `EasyAdd`.
- [x] Set `version: 2.0.0+10` in `pubspec.yaml`.
- [x] Add dependencies: `flutter_riverpod`, `shared_preferences`, `home_widget`. Add dev dependencies: `flutter_lints`, `flutter_launcher_icons`, `flutter_native_splash`.
- [x] Bundle the Inter font in `assets/fonts/Inter/` and register it in `pubspec.yaml`.
- [x] Use strict `analysis_options.yaml` (flutter_lints, strict casts and strict raw types).
- [x] Add a GitHub Actions workflow at `.github/workflows/ci.yml` that runs `flutter analyze` and `flutter test` on push and PR.
- [x] Commit "Scaffold Flutter project", then `git remote add origin https://github.com/AnthonySalvatoreErcolano/EasyAdd2.git` and push `main`. First check with `gh repo view` that the repo exists and is empty.

**Status: done (2026-10-22).** Notes from setup:

- Flutter 3.41.3 can't run `flutter build ios --simulator` with Xcode 27.1. Its architecture check fails even though the framework has both architectures. Workaround: run on a simulator with `flutter run`, or build with `xcodebuild ... ONLY_ACTIVE_ARCH=YES`. The next Flutter upgrade should fix it.
- Riverpod is held at 3.3.x, because 3.4.1+ needs Dart 3.12 (a newer Flutter).
- No Android SDK is installed on this Mac. Install Android Studio before testing on Android (needed by Phase 8 at the latest).
- The Android adaptive-icon foreground (`assets/icon/app_icon_foreground.png`) was generated from the 1024 px icon, with the drawing scaled into the safe zone.

**Check:** `flutter run` opens the default app on an iPhone simulator, and Xcode shows the bundle id `com.anthonyercolano.constructioncalculator`.

---

## Phase 1 — Math engine (`lib/engine/`, pure Dart, test-first)

Every value is stored exactly, and rounding happens only when a result is displayed.

- [ ] `rational.dart` — an immutable `Rational(num, den)` that is always reduced, with the sign on the numerator. It supports `+ − × ÷`, comparison, `roundTo(Rational step)` with ties away from zero, and `toDouble()`. It throws on a zero denominator.
- [ ] `dimension.dart` — the length exponent: 0 = number, 1 = length, 2 = area, 3 = volume.
- [ ] `quantity.dart` — `Quantity(Rational value, int dim)`. The base unit is inches, so area is in sq in and volume in cu in. Rules:
  - `+` and `−`: the dimensions must match. A bare number next to a length counts as inches.
  - `×`: dimensions add, up to 3. Above 3 the result is an error.
  - `÷`: dimensions subtract. Length ÷ length gives a plain number; a negative dimension is an error.
- [ ] `units.dart` — exact factors: ft = 12 in, yd = 36 in, mm = 5/127 in, cm = 50/127 in, m = 5000/127 in. Area and volume factors are the powers of these.
- [ ] `token.dart` — `Digit(n)`, `DecimalPoint`, `Fraction(n, d)`, `UnitMark(unit)` (ft, in, mm, cm, m), `Op(op)`.
- [ ] `entry_builder.dart` — turns one operand's tokens into a `Quantity` plus display segments for the UI (whole, fraction and unit pieces, so the UI can stack fractions). It also reports which keys are valid next, so invalid keys can be disabled.
- [ ] `evaluator.dart` — a shunting-yard evaluator over operands and operators that returns a `Quantity` or a typed `CalcError` (divide by zero, unit mismatch, dimension overflow).
- [ ] `formatter.dart`:
  - Length: round to the precision, split into feet, inches and a fraction, reduce, carry, and add a sign. Output `3' 4 5/8"`, `7 1/2"`, `3' 0"` or `−1' 3"`. Other modes are inches-only, decimal feet and metric (mm, cm or m to 1 decimal place).
  - Area and volume: a decimal to 2 places in the chosen unit, such as `120 sq ft` or `1.48 cu yd`.
  - Numbers: up to 6 significant decimal places, with trailing zeros trimmed.
  - Output is a list of segments, not a flat string, so the UI can render fractions.

### Engine test table (each row is a unit test; all values worked by hand)

| Input | Expected |
| --- | --- |
| `1' 2 1/2" + 3 7/8"` | `1' 6 3/8"` |
| `5' 3 1/4" − 2' 7 3/4"` | `2' 7 1/2"` |
| `11 15/16" + 1/16"` | `1' 0"` |
| `3/8" + 1/8"` | `1/2"` |
| `2' 3" × 4` | `9' 0"` |
| `6 3/4" × 2` | `1' 1 1/2"` |
| `8' ÷ 3` | `2' 8"` |
| `5' ÷ 7` | `≈ 8 9/16"` |
| `8' ÷ 1' 4"` | `6` |
| `1' − 2'` | `−1' 0"` |
| `2" + 3 × 4` | `1' 2"` |
| `2 + 3` | `5` |
| `2 1/2" ÷ 0` | `Error` |
| `10' × 12'` | `120 sq ft` |
| `12' 6" × 10' 3"` | `128.13 sq ft` (exact 128.125) |
| `3' × 4' × 6"` | `6 cu ft` / `0.22 cu yd` |
| `1' 2 1/2"` shown in metric | `368.3 mm` |
| `1000 mm` shown in ft/in | `≈ 3' 3 3/8"` |
| `1' + 10 cm` | `≈ 1' 3 15/16"` (exact 15.937…") |
| `10' × 12' × 12' × 2` | `Error` (dimension overflow) |

- [ ] Property tests (plain Dart loop, 10,000 random cases): `a + b − b == a`; re-entering a formatted value gives the value back within half a precision step; results always land on the precision grid.

**Check:** `flutter test test/engine` is all green, with 100% line coverage of `lib/engine/`.

---

## Phase 2 — Tool engines (`lib/engine/tools/`, pure Dart, test-first)

- [ ] `concrete.dart` — `ConcreteInput(length, width, depth, count, wastePct)` for slab or footing, or diameter × height for a round column. Outputs cu ft, cu yd, and 60 lb (0.45 cu ft each) and 80 lb (0.60 cu ft each) bag counts, rounded up. Bag yields are settings, so they can match the brand on the label.
- [ ] `stairs.dart` — inputs are total rise, max riser (default 7 3/4"), and tread depth (default 10") or total run. Outputs:
  - riser count = ⌈rise ÷ max riser⌉, and riser height = rise ÷ count
  - tread count = risers − 1, and total run = treads × tread depth
  - diagonal = √(rise² + run²), the one place a double is used, rounded back to 1/16"
  - angle in degrees
  - warnings when the riser is over 7 3/4" or the tread is under 10" (IRC R311.7.5 defaults, editable in settings)
- [ ] `board_feet.dart` — `(thickness in × width in × length ft ÷ 12) × qty`, using nominal sizes by default with an option for actual sizes. An optional price per board foot gives a total.

### Tool test table

| Tool | Input | Expected |
| --- | --- | --- |
| Concrete | 10' × 12' slab, 4" deep, 0% waste | 40 cu ft, `1.48 cu yd`, 67 × 80 lb bags |
| Concrete | same, 10% waste | 44 cu ft, `1.63 cu yd`, 74 × 80 lb bags |
| Stairs | rise `8' 10"`, max riser 7 3/4", tread 10" | 14 risers at `≈ 7 9/16"`, 13 treads, run `10' 10"`, diagonal `≈ 13' 11 3/4"`, 37.1° |
| Board feet | 2×6 × 8', qty 10 | 8 BF each, 80 BF total |
| Board feet | same at $1.25/BF | $100.00 |
| Board feet | 1×4 × 10', qty 1 | 3.33 BF |

**Check:** `flutter test test/engine/tools` is all green.

---

## Phase 3 — State (`lib/state/`)

- [ ] `calc_state.dart` — an immutable state: tokens, committed expression, last result, error, memory, display mode, precision, and the selected area or volume unit.
- [ ] `calc_controller.dart` — a Riverpod `Notifier<CalcState>` with one method per key: `pressDigit`, `pressDecimal`, `pressFraction`, `pressUnit`, `pressOp`, `equals`, `backspace`, `clear` (C, then AC), `memoryAdd/Sub/Recall/Clear`, and `useHistoryEntry`.
- [ ] Backspace removes exactly one token, including one through a committed operator.
- [ ] Repeat-equals: `2' + 3"`, then `=` `=` gives `2' 3"`, then `2' 6"`.
- [ ] Typing a digit after `=` starts a new calculation. Typing an operator after `=` continues from the result.
- [ ] `settings.dart` — precision, display mode, haptics on or off, bag yields, stair limits, and lumber nominal or actual.
- [ ] `tool_controllers.dart` — one small notifier per tool screen, with the inputs and a computed result.
- [ ] `lib/data/prefs_repository.dart` — saves settings, memory and history as JSON in `shared_preferences`, and writes the last result to the widget's shared storage (Phase 6).

**Check:** controller tests that use only key sequences (no UI) cover every key, backspace through each token type, C vs AC, repeat-equals and memory.

---

## Phase 4 — UI (`lib/ui/`)

- [ ] `theme/colors.dart` — tape yellow `#FEC517` (matches the icon), blade shadow `#E0A800`, ink black `#121212`, case graphite `#1E2023`, key steel `#2E3236` (pressed `#3C4146`), stud red `#D7262E`, chalk white `#F2F2EE`.
- [ ] `theme/typography.dart` — Inter with tabular figures. The result is weight 700 and the expression weight 500.
- [ ] `widgets/stacked_fraction.dart` — the numerator raised, the denominator lowered, both at about 60% size, with a slanted bar. Never use Unicode fraction characters.
- [ ] `widgets/measurement_text.dart` — renders formatter segments: whole numbers, `StackedFraction`, smaller `'`/`"` marks, a red `'`, and unit words such as "sq ft". It shrinks to fit and never wraps.
- [ ] `widgets/blade_display.dart` — the yellow blade with inch ticks painted by a `CustomPainter`, the expression line, the result line, and a decimal readout. Tapping the result's unit cycles the display mode (ft-in, in, decimal ft, metric; or sq ft, sq yd, m² for area).
- [ ] `widgets/key_button.dart` — the digit, fraction, operator and utility styles. Pressing scales the key to 96% for 80 ms and plays a light haptic. Includes VoiceOver labels, such as "three eighths".
- [ ] `widgets/fraction_strip.dart` — 1/8 to 7/8 plus a `16ths` toggle that swaps in the odd sixteenths.
- [ ] `widgets/keypad.dart` — the 4 × 5 grid: `AC ⌫ ft in / 7 8 9 ÷ / 4 5 6 × / 1 2 3 − / 0 . = +`. Long-pressing `in` offers mm, cm and m.
- [ ] `widgets/memory_row.dart` — MC, MR, M+, M− and a history icon.
- [ ] `calculator_screen.dart` — puts it all together. Keys are at least 64 pt tall on an iPhone SE.
- [ ] `sheets/history_sheet.dart` and `sheets/settings_sheet.dart`.
- [ ] `tools/tools_screen.dart` — cards for Concrete, Stairs, Board Feet and Convert.
- [ ] `tools/concrete_screen.dart`, `stairs_screen.dart`, `board_feet_screen.dart`, `convert_screen.dart` — each input field opens a compact tape-measure keypad (the same widgets) instead of the system keyboard, so feet and fractions can be entered. Results use `MeasurementText`. The stairs screen includes a simple side-view drawing of the stairs, painted with a `CustomPainter`.
- [ ] Navigation: a bottom bar with two tabs, **Calculator** and **Tools**. On iPad, the history tape is a permanent side panel.
- [ ] Golden tests: the blade with `11 15/16"`, `−1' 0"`, `120 sq ft`, a long expression and `Error`, at iPhone SE and 6.9" sizes, plus each tool screen with sample results.

**Check:** the goldens are approved, the widget tests pass, and the app is usable one-handed on an iPhone SE simulator.

---

## Phase 5 — Polish

- [ ] App icon: the new `EasyAddIcon.png` (a tape measure on yellow). Move it to `assets/icon/app_icon.png` and generate every size with `flutter_launcher_icons`:
  - iOS: `remove_alpha_ios: true`. The file has no transparency, which the App Store requires.
  - The file is **512 × 512 px**, but the App Store needs a **1024 × 1024 px** icon. Export the original artwork at 1024 if possible. Otherwise upscale it once (`sips -z 1024 1024`); it is flat artwork, so it stays fairly clean.
  - Android adaptive icon: background `#FEC517`, with the tape-measure drawing on a transparent foreground layer. Keep the drawing inside the center 66% so launchers don't crop it. Also keep a legacy icon from the full image.
- [ ] Launch screen: solid tape yellow `#FEC517` with no logo, via `flutter_native_splash` (`color: "#FEC517"`). On Android 12 and newer, the system always shows the app icon in the center of the splash screen. Set `android_12: color: "#FEC517"` so it blends in.
- [ ] Animations: the result slides into the expression line on `=`, and the blade ticks shift slightly.
- [ ] Accessibility: VoiceOver reads results as words ("3 feet 4 and 5 eighths inches"), Dynamic Type works on the tool screens, and contrast is checked.
- [ ] Dark-case look on every screen. There is no light theme, because the yellow-on-graphite style is the brand.

**Check:** the manual checklist passes on a real iPhone: haptics, icon, splash, VoiceOver, and every tool against the tool test table.

---

## Phase 6 — Home-screen widget (iOS)

A widget can't host a full keypad, so it shows results and opens the app quickly.

- [ ] In Xcode, add a Widget Extension target `EasyAddWidget` with bundle id `com.anthonyercolano.constructioncalculator.EasyAddWidget` and a deployment target of iOS 15.
- [ ] Add the App Group `group.com.anthonyercolano.constructioncalculator` to both Runner and the widget. Register it in the Apple Developer portal.
- [ ] Flutter side: `home_widget` saves `lastResult`, `lastExpression` and the last 3 history entries after every `=`, then calls `HomeWidget.updateWidget`.
- [ ] Swift side (SwiftUI + WidgetKit):
  - **Small:** the last result on the yellow blade.
  - **Medium:** the last result plus 3 recent results, and tool shortcuts (Concrete, Stairs, Board Feet).
  - **Lock screen (accessoryRectangular):** the last result.
  - Each tap opens a deep link: `easyadd://calculator`, `easyadd://tools/concrete` and so on.
- [ ] Register the `easyadd` URL scheme and route deep links in the app.
- [ ] Use `containerBackground` behind an `if #available(iOS 17, *)` check, with a plain background on older versions.

**Check:** after a calculation in the app, the widget updates within a few seconds, and each widget tap opens the right screen.

---

## Phase 7 — Ship 2.0.0

- [ ] Signing: the same Apple team as the old archives, with automatic signing for Runner and EasyAddWidget. The MAUI `ConstructionCalculator_Profile.mobileprovision` is not needed.
- [ ] `flutter build ipa --release`, then upload through Xcode Organizer or Transporter.
- [ ] TestFlight: at least a week of internal job-site use.
- [ ] App Store Connect: rename the listing to EasyAdd if it isn't already. Add new screenshots (6.9" and 6.5" iPhone, 13" iPad), What's New text covering the rebuild and the new tools, an updated keyword list, and a privacy label (no data collected).
- [ ] Submit 2.0.0 (10) for review.
- [ ] Tag `v2.0.0` in git after approval.

---

## Phase 8 — Android release (after iOS is live)

The Android build has run alongside iOS the whole time, because the Flutter code is shared. This phase adds what only Android needs and publishes it.

- [ ] Check every screen on an Android emulator (Pixel 9) and a small phone (360 dp wide): back-button behavior, haptics through `HapticFeedback`, and edge-to-edge system bars on the graphite background.
- [ ] Android widget: a home-screen widget built with `home_widget` and a small Kotlin `AppWidgetProvider` (Jetpack Glance), showing the same content as the iOS widget, with deep links into the app.
- [ ] Signing: create an upload keystore. Keep it out of git and back it up; losing it blocks future updates. Use Play App Signing.
- [ ] Play Console: create the EasyAdd app with package `com.anthonyercolano.constructioncalculator`. Add the store listing, a data safety form (no data collected), a content rating, and screenshots.
- [ ] Run `flutter build appbundle --release`, upload to internal testing, then closed testing (new personal developer accounts need 12 testers for 14 days before production), then production.

**Check:** EasyAdd 2.0.0 is live on Google Play.

---

## Final folder layout

```
EasyAdd/
  start.md  scaffold.md  README.md
  pubspec.yaml  analysis_options.yaml
  .github/workflows/ci.yml
  assets/fonts/Inter/  assets/icon/
  lib/
    main.dart  app.dart  router.dart
    engine/
      rational.dart  dimension.dart  quantity.dart  units.dart
      token.dart  entry_builder.dart  evaluator.dart  formatter.dart
      tools/  concrete.dart  stairs.dart  board_feet.dart
    state/
      calc_state.dart  calc_controller.dart  settings.dart  tool_controllers.dart
    data/
      prefs_repository.dart  widget_bridge.dart
    ui/
      theme/  colors.dart  typography.dart
      widgets/  stacked_fraction.dart  measurement_text.dart  blade_display.dart
                key_button.dart  keypad.dart  fraction_strip.dart  memory_row.dart
      calculator_screen.dart
      sheets/  history_sheet.dart  settings_sheet.dart
      tools/   tools_screen.dart  concrete_screen.dart  stairs_screen.dart
               board_feet_screen.dart  convert_screen.dart
  test/
    engine/  engine/tools/  state/  widgets/  goldens/
  ios/
    Runner/
    EasyAddWidget/   # SwiftUI WidgetKit extension
  android/
```

---

## Decisions made

- The name is **EasyAdd** in the store and on the home screen.
- Version **2.0.0**, build 10, released as an update to the existing listing.
- All formerly "later" features are in 2.0: area/volume, concrete, metric, stairs, board feet, widget.
- Results show `3' 0"` when the inch part is zero.
- The old app saved no user data, so nothing needs to be carried over.
- Both platforms ship: iOS first (Phase 7), then Android (Phase 8).
- The new icon is `EasyAddIcon.png`. The splash screen is plain tape yellow `#FEC517`, and the app uses the same yellow.

## Still open

- [ ] Can the icon be exported at 1024 × 1024 px? The current file is 512 px.
