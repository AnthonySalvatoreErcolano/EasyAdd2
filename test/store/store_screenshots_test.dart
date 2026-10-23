// App Store screenshots: the real app, framed, with a caption, at the exact
// pixel sizes App Store Connect asks for.
//
//   flutter test --tags golden --update-goldens test/store
//
// writes them to store/screenshots/.
@Tags(['golden'])
library;

import 'package:easyadd/app.dart';
import 'package:easyadd/data/prefs_repository.dart';
import 'package:easyadd/state/tool_forms.dart';
import 'package:easyadd/ui/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/helpers.dart';
import '../state/helpers.dart';
import '../ui/ui_helpers.dart';

/// One App Store screenshot size.
class Device {
  const Device(
    this.folder,
    this.canvas,
    this.pixelRatio,
    this.app,
    this.safeTop,
    this.safeBottom, {
    this.tablet = false,
  });

  final String folder;

  /// The screenshot, in points; × [pixelRatio] gives the required pixels.
  final Size canvas;
  final double pixelRatio;

  /// The screen size the app is laid out at, inside the frame.
  final Size app;
  final double safeTop;
  final double safeBottom;
  final bool tablet;
}

const devices = [
  // 1320 × 2868
  Device('iphone-6.9', Size(440, 956), 3, Size(440, 956), 59, 34),
  // 1242 × 2688
  Device('iphone-6.5', Size(414, 896), 3, Size(414, 896), 47, 34),
  // 2064 × 2752
  Device(
    'ipad-13',
    Size(1032, 1376),
    2,
    Size(1032, 1376),
    24,
    20,
    tablet: true,
  ),
];

class Scene {
  const Scene(this.file, this.title, this.subtitle, this.setUp);

  final String file;
  final String title;
  final String subtitle;
  final Future<void> Function(WidgetTester t, ProviderContainer c) setUp;
}

void _fill(ProviderContainer c, ToolKind tool, ToolField field, String input) {
  final form = c.read(toolFormProvider(tool).notifier)
    ..select(field)
    ..clearField();
  keys(input).forEach(form.input);
}

Future<void> _openTool(WidgetTester t, String name) async {
  await t.tap(find.text('Tools'));
  await t.pumpAndSettle();
  await t.tap(find.text(name));
  await t.pumpAndSettle();
}

final scenes = <Scene>[
  Scene(
    '01-calculator',
    'Add feet, inches\n& fractions',
    'Exact tape-measure math, down to 1/16″',
    (t, c) async {
      press(c, '1\' 2 1/2" + 3 7/8" =');
    },
  ),
  Scene(
    '02-live-answer',
    'Answers as you type',
    'Fraction keys, sixteenths, and a live preview',
    (t, c) async {
      press(c, '12\' 7 13/16" + 8\' 11 5/8');
    },
  ),
  Scene(
    '03-concrete',
    'Concrete in yards\n& bags',
    'Slabs, footings and columns, with waste',
    (t, c) async {
      await _openTool(t, 'Concrete');
      _fill(c, ToolKind.concrete, ToolFields.length, '24');
      _fill(c, ToolKind.concrete, ToolFields.width, '16');
      _fill(c, ToolKind.concrete, ToolFields.depth, '4');
      c.read(toolFormProvider(ToolKind.concrete).notifier).done();
    },
  ),
  Scene(
    '04-stairs',
    'Stairs, figured\nto code',
    'Risers, treads, run and stringer length',
    (t, c) async {
      await _openTool(t, 'Stairs');
      _fill(c, ToolKind.stairs, ToolFields.rise, '8\' 10"');
      c.read(toolFormProvider(ToolKind.stairs).notifier).done();
    },
  ),
  Scene(
    '05-board-feet',
    'Board feet\n& lumber cost',
    'Nominal or actual sizes, any quantity',
    (t, c) async {
      await _openTool(t, 'Board Feet');
      _fill(c, ToolKind.boardFeet, ToolFields.quantity, '24');
      _fill(c, ToolKind.boardFeet, ToolFields.price, '1.35');
      c.read(toolFormProvider(ToolKind.boardFeet).notifier).done();
    },
  ),
  Scene(
    '06-history',
    'Every calculation\nsaved',
    'Tap any past result to use it again',
    (t, c) async {
      press(c, '8\' ÷ 3 = 10\' × 12\' = 5\' ÷ 7 = 2\' + 3" = =');
      await t.pumpAndSettle();
      if (find.byTooltip('History').evaluate().isNotEmpty) {
        await t.tap(find.byTooltip('History'));
      }
    },
  ),
];

/// The yellow card: caption on top, the framed app below.
class StoreFrame extends StatelessWidget {
  const StoreFrame({
    super.key,
    required this.device,
    required this.scene,
    required this.app,
  });

  final Device device;
  final Scene scene;
  final Widget app;

  @override
  Widget build(BuildContext context) {
    final scale = device.tablet ? 1.6 : 1.0;
    final radius = device.tablet ? 28.0 : 46.0;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.tapeYellow,
        child: Column(
          children: [
            SizedBox(height: 46 * scale),
            Text(
              scene.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 36 * scale,
                height: 1.08,
                fontWeight: FontWeight.w800,
                color: AppColors.inkBlack,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 10 * scale),
            Text(
              scene.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.inkDim,
              ),
            ),
            SizedBox(height: 26 * scale),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 34 * scale),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AspectRatio(
                    aspectRatio: device.app.width / device.app.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.inkBlack,
                        borderRadius: BorderRadius.circular(radius + 8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 30,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(radius),
                          child: FittedBox(
                            child: SizedBox.fromSize(
                              size: device.app,
                              child: MediaQuery(
                                data: MediaQueryData(
                                  size: device.app,
                                  devicePixelRatio: device.pixelRatio,
                                  padding: EdgeInsets.only(
                                    top: device.safeTop,
                                    bottom: device.safeBottom,
                                  ),
                                  viewPadding: EdgeInsets.only(
                                    top: device.safeTop,
                                    bottom: device.safeBottom,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    app,
                                    _StatusBar(height: device.safeTop),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.chalkWhite,
              ),
            ),
            const Spacer(),
            for (final icon in const [
              Icons.signal_cellular_alt,
              Icons.wifi,
              Icons.battery_full,
            ])
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Icon(icon, size: 18, color: AppColors.chalkWhite),
              ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final device in devices) {
    for (final scene in scenes) {
      testWidgets('${device.folder} ${scene.file}', (t) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        t.view.physicalSize = device.canvas * device.pixelRatio;
        t.view.devicePixelRatio = device.pixelRatio;
        addTearDown(t.view.reset);

        await t.pumpWidget(
          StoreFrame(
            device: device,
            scene: scene,
            app: ProviderScope(
              overrides: [
                prefsRepositoryProvider.overrideWithValue(
                  PrefsRepository(prefs),
                ),
              ],
              child: const EasyAddApp(),
            ),
          ),
        );
        await t.pumpAndSettle();
        final c = ProviderScope.containerOf(t.element(find.byType(EasyAddApp)));
        await scene.setUp(t, c);
        await t.pumpAndSettle();
        await expectLater(
          find.byType(StoreFrame),
          matchesGoldenFile(
            '../../store/screenshots/${device.folder}/${scene.file}.png',
          ),
        );
      });
    }
  }
}
