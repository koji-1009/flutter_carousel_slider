import 'dart:async';

import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The innermost [Transform] wrapping the item that renders [text].
Transform _transformOf(WidgetTester tester, String text) =>
    tester.widget<Transform>(
      find
          .ancestor(of: find.text(text), matching: find.byType(Transform))
          .first,
    );

/// Both constructors used as `const`. If either stops being usable that way,
/// this file no longer compiles.
const _constDirect = CarouselSlider(items: [Text('A'), Text('B'), Text('C')]);
const _constBuilder = CarouselSlider.builder(
  itemCount: 4,
  itemBuilder: _constItemBuilder,
);

Widget _constItemBuilder(BuildContext context, int index, int realIndex) =>
    const SizedBox.shrink();

const _quick = Duration(milliseconds: 100);

void main() {
  group('CarouselSlider', () {
    testWidgets('renders items correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsNothing); // Should be off-screen
    });

    testWidgets('renders items using builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider.builder(
              itemCount: 3,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              itemBuilder: (context, index, realIndex) {
                return Text('Item ${index + 1}');
              },
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsNothing);
    });

    testWidgets('can scroll to next page', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      // Use fling to ensure page snap
      await tester.fling(find.text('Item 1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 1'), findsNothing);
    });

    testWidgets('onPageChanged is called', (tester) async {
      int? changedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              onPageChanged: (index) {
                changedIndex = index;
              },
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      await tester.fling(find.text('Item 1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
    });
  });

  group('CarouselController', () {
    late CarouselControllerX controller;

    setUp(() {
      controller = CarouselControllerX();
    });

    testWidgets('nextPage moves to next item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      controller.nextPage();
      await tester.pumpAndSettle();

      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('previousPage moves to previous item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                initialPage: 1,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      expect(find.text('Item 2'), findsOneWidget);

      controller.previousPage();
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('jumpToPage moves to specific item without animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      controller.jumpToPage(2);
      await tester.pumpAndSettle();

      expect(find.text('Item 3'), findsOneWidget);
    });
  });

  group('AutoPlay', () {
    testWidgets('advances automatically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 1),
                autoPlayAnimationDuration: Duration(milliseconds: 200),
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);

      // 1. Advance time to trigger the Timer (1s)
      await tester.pump(const Duration(milliseconds: 1005));

      // 2. Pump to start the animation triggered by the timer
      await tester.pump();

      // 3. Advance time to complete the animation (200ms)
      await tester.pump(const Duration(milliseconds: 205));

      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('enlarge strategies scale', () {
    /// The drawn width of the side item and the centre item.
    ///
    /// Measured on what is rendered, with a slide that fills its box: an item
    /// with an intrinsic size of its own stays that size however the box
    /// around it is scaled, so it cannot show the effect.
    Future<(double, double)> widthsWith(
      WidgetTester tester, {
      required bool enlargeCenterPage,
      required CenterPageEnlargeStrategy strategy,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: CarouselOptions(
                height: 300,
                viewportFraction: 0.7,
                initialPage: 1,
                enlargeCenterPage: enlargeCenterPage,
                enlargeFactor: 0.6,
                enlargeStrategy: strategy,
                enableInfiniteScroll: false,
              ),
              items: [
                for (var i = 0; i < 3; i++) Container(key: ValueKey('box$i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (
        tester.getRect(find.byKey(const ValueKey('box0'))).width,
        tester.getRect(find.byKey(const ValueKey('box1'))).width,
      );
    }

    for (final strategy in [
      CenterPageEnlargeStrategy.zoom,
      CenterPageEnlargeStrategy.scale,
    ]) {
      testWidgets('the ${strategy.name} strategy shrinks the side items', (
        tester,
      ) async {
        final (side, centre) = await widthsWith(
          tester,
          enlargeCenterPage: true,
          strategy: strategy,
        );

        expect(side, lessThan(centre));
      });
    }

    testWidgets('nothing is scaled when enlargeCenterPage is off', (
      tester,
    ) async {
      final (side, centre) = await widthsWith(
        tester,
        enlargeCenterPage: false,
        strategy: CenterPageEnlargeStrategy.zoom,
      );

      expect(side, centre);
    });
  });

  group('option validation', () {
    Widget build(CarouselOptions options) => MaterialApp(
      home: Scaffold(
        body: CarouselSlider(
          options: options,
          items: const [Text('Item 0'), Text('Item 1')],
        ),
      ),
    );

    testWidgets('a non-positive autoPlayInterval is reported', (tester) async {
      await tester.pumpWidget(
        build(
          const CarouselOptions(
            autoPlay: true,
            autoPlayInterval: Duration.zero,
            height: 400,
          ),
        ),
      );

      expect(
        tester.takeException().toString(),
        contains('autoPlayInterval must be greater than zero'),
      );
    });

    testWidgets('a non-positive autoPlayAnimationDuration is reported', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          const CarouselOptions(
            autoPlay: true,
            autoPlayAnimationDuration: Duration.zero,
            height: 400,
          ),
        ),
      );

      expect(
        tester.takeException().toString(),
        contains('autoPlayAnimationDuration must be greater than zero'),
      );
    });

    testWidgets('a bad interval is not reported while auto play is off', (
      tester,
    ) async {
      // Nothing reads it, so there is no fault to report — and reporting one
      // would replace the carousel with an error widget over a value that is
      // doing nothing.
      await tester.pumpWidget(
        build(
          const CarouselOptions(autoPlayInterval: Duration.zero, height: 400),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('turning auto play on reports the bad interval then', (
      tester,
    ) async {
      // The report is not lost by waiting: switching autoPlay on rebuilds the
      // carousel, which is the moment the value starts being used.
      await tester.pumpWidget(
        build(
          const CarouselOptions(autoPlayInterval: Duration.zero, height: 400),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        build(
          const CarouselOptions(
            autoPlay: true,
            autoPlayInterval: Duration.zero,
            height: 400,
          ),
        ),
      );

      expect(
        tester.takeException().toString(),
        contains('autoPlayInterval must be greater than zero'),
      );
    });

    testWidgets('a bad duration written after mount is reported there', (
      tester,
    ) async {
      // Not on the next tick: that report names a timer callback rather than
      // the rebuild that wrote the value, and it arrives an interval late.
      Widget carousel(Duration animation) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 400,
              autoPlay: true,
              autoPlayInterval: const Duration(milliseconds: 100),
              autoPlayAnimationDuration: animation,
              viewportFraction: 1.0,
            ),
            items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(const Duration(milliseconds: 50)));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(carousel(Duration.zero));

      expect(
        tester.takeException().toString(),
        contains('autoPlayAnimationDuration must be greater than zero'),
      );
    });

    testWidgets('a bad duration does not end auto play for good', (
      tester,
    ) async {
      // Reporting on the way to arming the timer used to leave auto play
      // holding a timer that had already fired, which nothing replaced.
      int pageChanges = 0;
      Widget carousel(Duration animation) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 400,
              autoPlay: true,
              autoPlayInterval: const Duration(milliseconds: 100),
              autoPlayAnimationDuration: animation,
              viewportFraction: 1.0,
            ),
            onPageChanged: (_) => pageChanges++,
            items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(const Duration(milliseconds: 50)));
      await tester.pumpWidget(carousel(Duration.zero));
      tester.takeException();

      // Time has to pass with the bad value in place, or the tick that used to
      // report it — and die on the way to arming the next one — never happens.
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 60));
        tester.takeException();
      }

      // The interval is unchanged, so nothing reschedules the timer here — it
      // has to have survived on its own.
      await tester.pumpWidget(carousel(const Duration(milliseconds: 50)));
      final before = pageChanges;
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(pageChanges, greaterThan(before));
    });

    testWidgets('a non-positive interval stops auto play instead of spinning', (
      tester,
    ) async {
      // In release the report above is gone, and a zero-length timer that
      // schedules another zero-length timer never lets a frame through.
      int pageChanges = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 400,
                autoPlay: true,
                autoPlayInterval: Duration.zero,
                viewportFraction: 1.0,
              ),
              onPageChanged: (_) => pageChanges++,
              items: const [Text('Item 0'), Text('Item 1')],
            ),
          ),
        ),
      );
      // The bad value is reported on every rebuild it survives.
      tester.takeException();
      await tester.pump(const Duration(seconds: 1));
      tester.takeException();

      expect(pageChanges, 0);
    });

    test('a non-positive aspectRatio is rejected at construction', () {
      expect(() => CarouselOptions(aspectRatio: 0), throwsAssertionError);
      expect(() => CarouselOptions(aspectRatio: -1), throwsAssertionError);
    });

    test('both constructors can be invoked as const', () {
      // [CarouselSlider.itemCount] is a getter rather than a field for this:
      // a list's length is not a constant expression, so initialising a field
      // from `items.length` would make the default constructor non-const.
      //
      // The check is the `const` on these declarations: it is a compile-time
      // error, and an analyzer failure, if either constructor stops being
      // const. The expectations below only pin down what [itemCount] answers.
      const items = CarouselSlider(items: [SizedBox(), SizedBox()]);
      const builder = CarouselSlider.builder(
        itemCount: 3,
        itemBuilder: _emptyItem,
      );

      expect(items.itemCount, 2);
      expect(builder.itemCount, 3);
    });

    test('a non-positive viewportFraction is rejected', () {
      // [PageController] asserts this itself, naming Flutter internals and not
      // the option that caused it.
      expect(() => CarouselOptions(viewportFraction: 0), throwsAssertionError);
      expect(() => CarouselOptions(viewportFraction: -1), throwsAssertionError);
    });

    test('a negative height is rejected at construction', () {
      // A negative height reaches [BoxConstraints] as a non-normalized value,
      // which reports against the framework rather than against the option.
      expect(() => CarouselOptions(height: -1), throwsAssertionError);
      expect(() => CarouselOptions(height: 0), returnsNormally);
    });

    test('a negative builder itemCount is rejected at construction', () {
      expect(
        () => CarouselSlider.builder(
          itemCount: -1,
          itemBuilder: (context, index, realIndex) => const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('a controller call before the first layout is reported', (
      tester,
    ) async {
      // The carousel defers the page view to layout, so a sibling built after
      // it in the same frame finds a controller with no position yet.
      // [PageController] throws on that, in release as well as in debug, so
      // the carousel has to answer for it with something the caller can act on.
      final controller = CarouselControllerX();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          // A [Stack] rather than a [Column]: the failed build is replaced by
          // an error widget, and a column would report its overflow as a
          // second exception on top of the one under test.
          home: Stack(
            children: [
              CarouselSlider(
                carouselController: controller,
                options: const CarouselOptions(height: 100),
                items: const [Text('Item 0'), Text('Item 1')],
              ),
              Builder(
                builder: (context) {
                  controller.jumpToPage(1);
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      );

      expect(
        tester.takeException().toString(),
        contains('had no scroll position to move'),
      );
    });
  });

  group('pre-existing defects fixed in 7.0.0', () {
    testWidgets('a caller-owned controller survives the carousel', (
      tester,
    ) async {
      final controller = CarouselControllerX();
      Widget build(Key key) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: key,
            carouselController: controller,
            options: const CarouselOptions(viewportFraction: 1.0, height: 400),
            items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      // Replacing the carousel disposes the outgoing state after the incoming
      // one has installed its callbacks, so disposing a controller it does not
      // own would detach the carousel that is still on screen.
      await tester.pumpWidget(build(const ValueKey(1)));
      await tester.pumpWidget(build(const ValueKey(2)));
      await tester.pumpAndSettle();

      controller.jumpToPage(2);
      await tester.pumpAndSettle();

      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('both constructors can be used as const', (tester) async {
      // `items.length` is not a constant expression in Dart, so deriving
      // itemCount in the initialiser would make the default constructor
      // impossible to invoke as const even though the list is const.
      expect(_constDirect.itemCount, 3);
      expect(_constBuilder.itemCount, 4);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox(height: 400, child: _constDirect)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('rebuilding the page view from scratch does not throw', (
      tester,
    ) async {
      Widget build({double? height}) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: height,
              aspectRatio: 2.0,
              viewportFraction: 1.0,
              enlargeCenterPage: true,
            ),
            items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
          ),
        ),
      );

      // Swapping a fixed height for an aspect ratio replaces the widget above
      // the page view, so for one frame two scroll positions are attached to
      // the one controller. Reading the page then throws — in release too,
      // where `positions.single` throws instead of an assertion.
      await tester.pumpWidget(build(height: 400));
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('a finite carousel wraps from the page it can reach', (
      tester,
    ) async {
      final seen = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 1),
                autoPlayAnimationDuration: Duration(milliseconds: 100),
                enableInfiniteScroll: false,
                // The last pages share a screen, so the furthest reachable
                // page is 1.75 — fractional, so no test against an integer
                // index can name it.
                padEnds: false,
                viewportFraction: 0.8,
                height: 400,
              ),
              onPageChanged: seen.add,
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(seen, [1, 2, 0, 1, 2]);
    });

    testWidgets('the zoom strategy anchors towards the centre under reverse', (
      tester,
    ) async {
      Future<List<double>> centresFor({required bool reverse}) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  viewportFraction: 0.7,
                  initialPage: 1,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.5,
                  enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                  reverse: reverse,
                  enableInfiniteScroll: false,
                ),
                items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return [
          tester.getCenter(find.text('Item 0')).dx,
          tester.getCenter(find.text('Item 2')).dx,
        ];
      }

      final forward = await centresFor(reverse: false);
      final reversed = await centresFor(reverse: true);

      // Reversing mirrors the layout, so the side items must sit the same
      // distance from the centre, just swapped.
      expect(reversed[0], closeTo(forward[1], 0.01));
      expect(reversed[1], closeTo(forward[0], 0.01));
    });

    testWidgets('a slide is built once at mount', (tester) async {
      // The carousel used to ask for a second build of every visible slide as
      // soon as the first frame was done, for output that never differed.
      final builds = <int, int>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider.builder(
              itemCount: 5,
              options: const CarouselOptions(height: 300, initialPage: 2),
              itemBuilder: (context, index, realIndex) {
                builds[index] = (builds[index] ?? 0) + 1;
                return Text('Item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(builds.values, everyElement(1));
    });

    testWidgets('every strategy fills the slot when disableCenter is on', (
      tester,
    ) async {
      // The height strategy sizes its own box, so it has to be careful not to
      // decide where the slide sits inside it — that is what disableCenter is
      // for, and the other two strategies leave it alone.
      Future<Rect> rectFor(CenterPageEnlargeStrategy strategy) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  viewportFraction: 0.7,
                  initialPage: 1,
                  enlargeCenterPage: true,
                  disableCenter: true,
                  enlargeStrategy: strategy,
                  enableInfiniteScroll: false,
                ),
                items: [
                  for (var i = 0; i < 3; i++)
                    SizedBox(key: ValueKey('box$i'), width: 50, height: 40),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getRect(find.byKey(const ValueKey('box1')));
      }

      final zoom = await rectFor(CenterPageEnlargeStrategy.zoom);
      final height = await rectFor(CenterPageEnlargeStrategy.height);

      expect(height.width, zoom.width);
      expect(height.left, zoom.left);
    });

    testWidgets('the height strategy measures the box the page view got', (
      tester,
    ) async {
      // [CarouselOptions.height] and [aspectRatio] say what the carousel asks
      // for; the constraints it is given can be tighter, and the strategy has
      // to shrink the box that exists rather than the one that was requested.
      Future<(double centre, double side)> heightsIn(
        Widget Function(Widget) frame,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: frame(
                CarouselSlider(
                  options: const CarouselOptions(
                    height: 400,
                    viewportFraction: 0.7,
                    initialPage: 1,
                    enlargeCenterPage: true,
                    enlargeStrategy: CenterPageEnlargeStrategy.height,
                    enableInfiniteScroll: false,
                  ),
                  items: [
                    for (var i = 0; i < 3; i++)
                      Container(key: ValueKey('box$i')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return (
          tester.getRect(find.byKey(const ValueKey('box1'))).height,
          tester.getRect(find.byKey(const ValueKey('box0'))).height,
        );
      }

      final (roomyCentre, roomySide) = await heightsIn((child) => child);
      expect(roomySide, lessThan(roomyCentre));

      // The carousel asks for 400 and is given 150.
      final (tightCentre, tightSide) = await heightsIn(
        (child) => SizedBox(height: 150, child: child),
      );
      expect(tightCentre, 150);
      expect(tightSide, lessThan(tightCentre));
      expect(tightSide / tightCentre, closeTo(roomySide / roomyCentre, 0.001));
    });

    for (final axis in Axis.values) {
      testWidgets('the height strategy shrinks side items on the '
          '${axis.name} axis', (tester) async {
        // Measured on what is drawn, not on the SizedBox's height property:
        // the page view constrains slides tightly, so that property can be
        // set and have no effect at all.
        //
        // The extent that shrinks is the one across the scroll axis. Along it
        // the page view pins every slide to its slot, so a box asking to be
        // smaller there is simply pushed back out — which is what made this
        // strategy a no-op on the vertical axis. [enlargeFactor] is left at its
        // default here for the same reason: a large enough factor takes the
        // requested size below the slot and hides the defect.
        Future<Map<int, (double across, double along)>> extentsWith({
          required bool enlargeCenterPage,
        }) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CarouselSlider(
                  options: CarouselOptions(
                    scrollDirection: axis,
                    height: 300,
                    viewportFraction: 0.7,
                    initialPage: 1,
                    enlargeCenterPage: enlargeCenterPage,
                    enlargeStrategy: CenterPageEnlargeStrategy.height,
                    enableInfiniteScroll: false,
                  ),
                  items: [
                    for (var i = 0; i < 3; i++)
                      Container(key: ValueKey('box$i')),
                  ],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          return {
            for (var i = 0; i < 2; i++)
              i: switch (axis) {
                Axis.horizontal => (
                  tester.getRect(find.byKey(ValueKey('box$i'))).height,
                  tester.getRect(find.byKey(ValueKey('box$i'))).width,
                ),
                Axis.vertical => (
                  tester.getRect(find.byKey(ValueKey('box$i'))).width,
                  tester.getRect(find.byKey(ValueKey('box$i'))).height,
                ),
              },
          };
        }

        final enlarged = await extentsWith(enlargeCenterPage: true);
        final plain = await extentsWith(enlargeCenterPage: false);

        expect(plain[0]!.$1, plain[1]!.$1);
        expect(enlarged[1]!.$1, plain[1]!.$1);
        expect(enlarged[0]!.$1, lessThan(enlarged[1]!.$1));
        // Along the scroll axis nothing moves: the slide still fills its slot.
        expect(enlarged[0]!.$2, plain[0]!.$2);
        expect(enlarged[1]!.$2, plain[1]!.$2);
      });
    }
  });

  group('rebuilds that move the position', () {
    Widget build({
      double? height,
      double aspectRatio = 16 / 9,
      int items = 5,
      CarouselControllerX? controller,
    }) => MaterialApp(
      home: Scaffold(
        body: CarouselSlider(
          carouselController: controller,
          options: CarouselOptions(
            height: height,
            aspectRatio: aspectRatio,
            viewportFraction: 1.0,
          ),
          items: [for (var i = 0; i < items; i++) Text('Item $i')],
        ),
      ),
    );

    double pageOf(WidgetTester tester) =>
        tester.widget<PageView>(find.byType(PageView)).controller!.page!;

    for (final rebuild in ['sizing', 'pageViewKey']) {
      testWidgets(
        'a controller call while the page view is inflated afresh is declined '
        '($rebuild)',
        (tester) async {
          // Two windows, both of the carousel's own making. Changing
          // [CarouselOptions.pageViewKey] leaves the outgoing and incoming page
          // views attached to the same controller for the frame, and
          // [PageController] throws rather than choosing between them. Swapping
          // the sizing option gives the controller one position with no
          // dimensions yet, and [PageController] holds a move made then until
          // the position has them.
          final controller = CarouselControllerX();
          addTearDown(controller.dispose);
          var callDuringBuild = false;

          Widget carousel({required bool second}) => MaterialApp(
            home: Scaffold(
              body: CarouselSlider.builder(
                carouselController: controller,
                itemCount: 5,
                options: CarouselOptions(
                  height: rebuild == 'sizing' && second ? null : 200,
                  aspectRatio: 2,
                  viewportFraction: 1.0,
                  pageViewKey: PageStorageKey<String>(
                    rebuild == 'pageViewKey' && second ? 'b' : 'a',
                  ),
                ),
                itemBuilder: (context, index, realIndex) {
                  if (callDuringBuild) {
                    controller.jumpToPage(1);
                  }
                  return Text('Item $index');
                },
              ),
            ),
          );

          await tester.pumpWidget(carousel(second: false));
          await tester.pumpAndSettle();

          callDuringBuild = true;
          await tester.pumpWidget(carousel(second: true));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('controller calls on an empty carousel do nothing', (
      tester,
    ) async {
      // There is no item to name, and the clamp that brings a page number into
      // range has no range to clamp to.
      final controller = CarouselControllerX();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(height: 200),
              items: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpToPage(2);
      unawaited(controller.animateToPage(2));
      unawaited(controller.nextPage());
      unawaited(controller.previousPage());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('auto play leaves a single item carousel alone', (
      tester,
    ) async {
      // Not just "no page change": a page view of one slide cannot report one
      // whatever happens to it. Auto play has to decline outright, or it drives
      // a scroll activity on a carousel with nothing to scroll.
      final scrolled = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: Duration(milliseconds: 100),
                autoPlayAnimationDuration: Duration(milliseconds: 50),
              ),
              onScrolled: scrolled.add,
              items: const [Text('Item 0')],
            ),
          ),
        ),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(scrolled, isEmpty);
    });

    testWidgets('items arriving after an empty build report only where the '
        'reader lands', (tester) async {
      // The report has to run after the position has been put back on the
      // virtual offset, not before: the stale position maps through the offset
      // to an arbitrary item, and that item is both reported and painted.
      final changed = <int>[];
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(height: 200, viewportFraction: 1.0),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(3));
      expect(find.text('Item 0'), findsOneWidget);
      await tester.pumpAndSettle();

      expect(changed, isEmpty);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('a list that empties reports nothing', (tester) async {
      // There is no item to name, and a caller indexing its own list with
      // whatever was reported would throw.
      final changed = <int>[];
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(height: 200, viewportFraction: 1.0),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(5));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(changed, [1]);

      await tester.pumpWidget(carousel(0));
      await tester.pumpAndSettle();

      expect(changed, [1]);
    });

    testWidgets('turning infinite scroll on draws and reports the same item', (
      tester,
    ) async {
      // The reset jumps the position before the new content dimensions reach
      // it, so the page reads back clamped to the old ones — a report for an
      // item the reader is not on, which also poisons the record so the next
      // genuine arrival there is swallowed.
      final changed = <int>[];
      Widget carousel({required bool infinite}) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: infinite,
            ),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < 3; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(infinite: false));
      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsOneWidget);

      await tester.pumpWidget(carousel(infinite: true));
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(changed, isEmpty);
    });

    testWidgets('turning infinite scroll off redraws every slide from the '
        'new base', (tester) async {
      // The base each slide's index is taken from moves a frame after the
      // position. Slides already built keep the old one unless something asks
      // for them again, and the page view keeps them for the life of the
      // widget.
      Widget carousel({required bool infinite}) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: 0.5,
              enableInfiniteScroll: infinite,
            ),
            items: [for (var i = 0; i < 3; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(infinite: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(infinite: false));
      await tester.pumpAndSettle();

      // Opens on item 0, with item 1 alongside it. Item 0 must appear once.
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    for (final alsoReplaceController in [false, true]) {
      testWidgets('a shrinking list never leaves the carousel blank '
          '(controller replaced: $alsoReplaceController)', (tester) async {
        // The page the reader is on can stop existing. Aiming the position at
        // it anyway puts it past maxScrollExtent, where there is nothing to
        // draw, until it ballistics back.
        Widget carousel(int items, double fraction) => MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: fraction,
                enableInfiniteScroll: false,
              ),
              items: [for (var i = 0; i < items; i++) Text('Item $i')],
            ),
          ),
        );

        await tester.pumpWidget(carousel(6, 0.8));
        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byType(PageView), const Offset(-700, 0));
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(
          carousel(3, alsoReplaceController ? 0.79 : 0.8),
        );

        // On the frame after the rebuild, not merely by the time it settles: a
        // position past the end draws nothing and is walked back over many
        // frames, and counting blank frames cannot see it sitting there.
        await tester.pump();
        final position = tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .position;
        expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));

        var blank = 0;
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          if (find.textContaining('Item ').evaluate().isEmpty) blank++;
        }
        await tester.pumpAndSettle();

        expect(blank, 0);
        expect(find.textContaining('Item '), findsWidgets);
      });
    }

    for (final shrinkTo in [2, 1]) {
      testWidgets(
        'a list shrinking to $shrinkTo during a controller move leaves nothing '
        'stranded',
        (tester) async {
          // The physics refuse the first step past the new end, the movement
          // goes idle where it stands, and nothing brings it back — the page
          // view has no children there, so the carousel stays blank. At one
          // item it cannot even be dragged out of it.
          final controller = CarouselControllerX();
          addTearDown(controller.dispose);
          var items = 5;
          late StateSetter setOuter;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setOuter = setState;
                    return CarouselSlider(
                      carouselController: controller,
                      options: const CarouselOptions(
                        height: 100,
                        viewportFraction: 1.0,
                        enableInfiniteScroll: false,
                        initialPage: 2,
                      ),
                      items: [for (var i = 0; i < items; i++) Text('I\$i')],
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          unawaited(
            controller.nextPage(duration: const Duration(milliseconds: 300)),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));

          setOuter(() => items = shrinkTo);
          await tester.pumpAndSettle();

          final position = tester
              .widget<PageView>(find.byType(PageView))
              .controller!
              .position;
          expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));
          expect(find.textContaining('I'), findsWidgets);
        },
      );
    }

    testWidgets('a list shrinking mid-movement is brought back in range', (
      tester,
    ) async {
      // A position at rest is clamped by the layout itself when the content
      // shrinks. One that is moving is not: the physics let the movement finish
      // and leave it past the end, where the page view draws nothing.
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              autoPlay: true,
              autoPlayInterval: Duration(milliseconds: 200),
              autoPlayAnimationDuration: Duration(milliseconds: 1200),
            ),
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(6));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
      }

      // Mid-slide towards the last item.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .position
            .isScrollingNotifier
            .value,
        isTrue,
      );

      await tester.pumpWidget(carousel(3));
      await tester.pump();

      final position = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));
      expect(find.textContaining('Item '), findsWidgets);
    });

    testWidgets('a list narrowing to one item never leaves it blank', (
      tester,
    ) async {
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              autoPlay: true,
              autoPlayInterval: Duration(milliseconds: 200),
              autoPlayAnimationDuration: Duration(milliseconds: 800),
            ),
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(5));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpWidget(carousel(1));

      var blank = 0;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('Item 0').evaluate().isEmpty) blank++;
      }

      expect(blank, 0);
      final settled = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      expect(settled.pixels, settled.minScrollExtent);
    });

    testWidgets('the reader keeps the last item at every screen width', (
      tester,
    ) async {
      // Deriving the last reachable page by dividing extents lands a hair under
      // a whole number on a good fraction of real widths, and rounding that
      // down moves the reader off the item they were on.
      for (final width in const [320.0, 360.0, 375.0, 390.0, 412.0, 428.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        Widget carousel(int items) => MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 200,
                enableInfiniteScroll: false,
                initialPage: 4,
              ),
              items: [for (var i = 0; i < items; i++) Text('Item $i')],
            ),
          ),
        );

        await tester.pumpWidget(carousel(6));
        await tester.pumpAndSettle();
        await tester.pumpWidget(carousel(5));
        await tester.pumpAndSettle();

        expect(
          tester.widget<PageView>(find.byType(PageView)).controller!.page,
          4.0,
          reason: 'the reader was moved off item 4 at a width of $width',
        );
      }
    });

    testWidgets('raising viewportFraction does not move the reader back', (
      tester,
    ) async {
      // More of the viewport per slide means more pages are reachable, never
      // fewer, so nothing here may pull the reader towards the start.
      Widget carousel(double fraction) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: fraction,
              enableInfiniteScroll: false,
              initialPage: 4,
            ),
            items: [for (var i = 0; i < 5; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(0.4));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(0.8));
      await tester.pumpAndSettle();

      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        4.0,
      );
    });

    testWidgets('jumping to an item the page view cannot bring to the front', (
      tester,
    ) async {
      // All five fit on screen at once, so there is nowhere to scroll to.
      // jumpToPage does not check, and the position was left past the end,
      // drifting back on its own for the best part of a second.
      final controller = CarouselControllerX();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 0.2,
                padEnds: false,
                enableInfiniteScroll: false,
              ),
              items: [for (var i = 0; i < 5; i++) Text('Item $i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.jumpToPage(4);
      // Two frames: the correction waits for the layout that knows how far the
      // page view will go, so that a caller who grows the list and jumps to one
      // of the new items in the same breath is not pulled back to where the
      // list used to end.
      await tester.pump();
      await tester.pump();

      final position = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('taking padding off the ends brings the reader back in reach', (
      tester,
    ) async {
      // With padEnds off and a viewport fraction below one the last items share
      // a screen, so the furthest the page view goes is short of the last
      // index. A position left past it draws nothing on the far side of the
      // viewport, and the physics walk it back a frame at a time.
      final changed = <int>[];
      Widget carousel({required bool padEnds}) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: 0.5,
              enableInfiniteScroll: false,
              initialPage: 4,
              padEnds: padEnds,
            ),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < 5; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(padEnds: true));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(padEnds: false));
      await tester.pump();
      await tester.pump();

      final position = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      expect(position.pixels, lessThanOrEqualTo(position.maxScrollExtent));
    });

    testWidgets('a viewportFraction change keeps what is inside a slide', (
      tester,
    ) async {
      // Rebuilding the scroll position from scratch is the only way to keep the
      // page-to-item mapping honest, but it throws away everything inside every
      // slide with it — a focused field, a playing video, an expanded card. It
      // is only worth that when the slides are being renumbered anyway.
      Widget carousel(double fraction) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              viewportFraction: fraction,
              enableInfiniteScroll: false,
            ),
            items: const [
              _Counter(key: ValueKey('c0')),
              _Counter(key: ValueKey('c1')),
              _Counter(key: ValueKey('c2')),
            ],
          ),
        ),
      );

      await tester.pumpWidget(carousel(0.8));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('c0')));
      await tester.pumpAndSettle();
      expect(
        tester.state<_CounterState>(find.byKey(const ValueKey('c0'))).taps,
        2,
      );

      await tester.pumpWidget(carousel(0.6));
      await tester.pumpAndSettle();

      expect(
        tester.state<_CounterState>(find.byKey(const ValueKey('c0'))).taps,
        2,
      );
    });

    testWidgets('turning enlarging on keeps what is inside a slide', (
      tester,
    ) async {
      // The wrapper that follows the scroll position is always in the tree, so
      // that switching the effect changes what it does rather than whether it
      // is there. A different widget at that slot would take every slide's
      // state with it.
      Widget carousel({required bool enlarge}) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 200,
              enlargeCenterPage: enlarge,
              enableInfiniteScroll: false,
            ),
            items: const [
              _Counter(key: ValueKey('c0')),
              _Counter(key: ValueKey('c1')),
            ],
          ),
        ),
      );

      await tester.pumpWidget(carousel(enlarge: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('c0')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(enlarge: true));
      await tester.pumpAndSettle();

      expect(
        tester.state<_CounterState>(find.byKey(const ValueKey('c0'))).taps,
        1,
      );
    });

    testWidgets('a stored position does not override a reposition', (
      tester,
    ) async {
      // PageStorage restores the page the carousel was last left on, and does
      // it before the page the fresh controller was given takes effect.
      final bucket = PageStorageBucket();
      Widget carousel(int initialPage) => MaterialApp(
        home: Scaffold(
          body: PageStorage(
            bucket: bucket,
            child: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                pageViewKey: const PageStorageKey<String>('c'),
                initialPage: initialPage,
              ),
              items: [for (var i = 0; i < 5; i++) Text('Item $i')],
            ),
          ),
        ),
      );

      await tester.pumpWidget(carousel(0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(4));
      await tester.pumpAndSettle();

      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        4.0,
      );
      expect(find.text('Item 4'), findsOneWidget);
    });

    testWidgets('a finite carousel opens on initialPage when items arrive '
        'late', (tester) async {
      // The starting position is resolved against the item count, and one
      // resolved against no items says nothing about where to open.
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              initialPage: 3,
            ),
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(0));
      await tester.pumpAndSettle();
      await tester.pumpWidget(carousel(5));
      await tester.pumpAndSettle();

      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('a viewportFraction change does not fail a setState made from '
        'onScrolled', (tester) async {
      // Applying a new viewport fraction to a position that survived the
      // rebuild notified from inside the build phase, and an indicator
      // repainting itself from onScrolled failed its setState there.
      final rebuilds = <double>[];
      Widget carousel(double fraction) => MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setInner) => CarouselSlider(
              options: CarouselOptions(height: 200, viewportFraction: fraction),
              onScrolled: (position) {
                rebuilds.add(position);
                setInner(() {});
              },
              items: [for (var i = 0; i < 5; i++) Text('Item $i')],
            ),
          ),
        ),
      );

      await tester.pumpWidget(carousel(0.8));
      await tester.pumpAndSettle();

      await tester.pumpWidget(carousel(0.5));
      await tester.pumpAndSettle();

      // The position survives the change — a slide's own state is worth more
      // than the notification it costs — so applying the new fraction to it
      // does report, from inside the build phase. It has to arrive after the
      // frame rather than during it.
      expect(tester.takeException(), isNull);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('nextPage does nothing on a single item carousel', (
      tester,
    ) async {
      final controller = CarouselControllerX();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
              ),
              items: const [Text('Item 0')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pc = tester.widget<PageView>(find.byType(PageView)).controller!;
      final before = pc.page;

      unawaited(controller.nextPage());
      unawaited(controller.previousPage());
      await tester.pumpAndSettle();

      expect(pc.page, before);
    });

    testWidgets('an out-of-range initialPage is not reported as a change', (
      tester,
    ) async {
      // The carousel opens on the item the number resolves to, so that is the
      // item onPageChanged has already implicitly told the caller about. Seeding
      // the record with the raw number instead makes the next thing that asks
      // for a report emit one for a slide that never moved.
      final changed = <int>[];
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              initialPage: 10,
            ),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(3));
      await tester.pumpAndSettle();
      expect(find.text('Item 2'), findsOneWidget);
      expect(changed, isEmpty);

      // An item count change asks the carousel to report where the reader is.
      // They have not moved.
      await tester.pumpWidget(carousel(4));
      await tester.pumpAndSettle();

      expect(changed, isEmpty);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('an initialPage past the last item opens on the last item', (
      tester,
    ) async {
      // It used to be passed straight to the [PageController], which put the
      // position beyond the end and then sprang it back — 288ms of a carousel
      // showing nothing at all, while onPageChanged had already reported the
      // slide the reader could not see.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                initialPage: 10,
              ),
              items: [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('growing from a single item does not flash another slide', (
      tester,
    ) async {
      // The index every slide is drawn from counts from a virtual offset. A
      // carousel that leaves that offset while it has one item lands back on it
      // a frame late, and draws one frame of whichever slide the stale position
      // happens to map to.
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(height: 200, viewportFraction: 1.0),
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(1));
      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsOneWidget);

      await tester.pumpWidget(carousel(3));

      expect(find.text('Item 0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('a list that drops to one item and back keeps the page', (
      tester,
    ) async {
      // Search-as-you-type narrowing to a single hit and widening again.
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(height: 200, viewportFraction: 1.0),
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(5));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsOneWidget);

      await tester.pumpWidget(carousel(1));
      await tester.pumpAndSettle();
      expect(find.text('Item 0'), findsOneWidget);

      await tester.pumpWidget(carousel(5));
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
    });

    for (final infinite in [false, true]) {
      testWidgets('a shorter list reports the item the reader lands on '
          '(infinite: $infinite)', (tester) async {
        // The index is taken modulo the item count, and a shorter finite list
        // has its position clamped during layout. Neither moves the page
        // view, so the last index reported used to name an item the list no
        // longer had.
        final changed = <int>[];
        Widget carousel(int items) => MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: infinite,
              ),
              onPageChanged: changed.add,
              items: [for (var i = 0; i < items; i++) Text('Item $i')],
            ),
          ),
        );

        await tester.pumpWidget(carousel(5));
        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          await tester.drag(find.byType(PageView), const Offset(-700, 0));
          await tester.pumpAndSettle();
        }
        expect(changed, [1, 2, 3, 4]);

        await tester.pumpWidget(carousel(2));
        await tester.pumpAndSettle();

        expect(changed.last, lessThan(2));
        final onScreen = [
          for (var i = 0; i < 2; i++)
            if (find.text('Item $i').evaluate().isNotEmpty) i,
        ];
        expect(onScreen, [changed.last]);
      });
    }

    testWidgets('a longer list does not report anything on its own', (
      tester,
    ) async {
      final changed = <int>[];
      Widget carousel(int items) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: const CarouselOptions(height: 200, viewportFraction: 1.0),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < items; i++) Text('Item $i')],
          ),
        ),
      );

      await tester.pumpWidget(carousel(3));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(changed, [1]);

      await tester.pumpWidget(carousel(6));
      await tester.pumpAndSettle();

      expect(changed, [1]);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('the builder is given the page view\'s own page number', (
      tester,
    ) async {
      // realIndex is documented as the page view's page — the value a Hero tag
      // needs so that the same item shown twice does not collide. The item
      // index alone cannot tell one occurrence from the other.
      final seen = <int, int>{};
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider.builder(
              itemCount: 3,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                initialPage: 1,
              ),
              itemBuilder: (context, index, realIndex) {
                seen[realIndex] = index;
                return Text('Item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The carousel opens on item 1, which sits at the virtual offset plus 1,
      // and every page it built maps to its item through that same offset.
      expect(seen[10001], 1);
      expect(seen, isNotEmpty);
      seen.forEach((realIndex, index) {
        expect(index, (realIndex - 10000) % 3, reason: 'page $realIndex');
      });
    });

    testWidgets('a finite carousel never takes the wrapped path', (
      tester,
    ) async {
      // animateToClosest is on by default. Wrapping only exists on a carousel
      // that scrolls forever; choosing it on a finite one names a page before
      // the first item.
      final controller = CarouselControllerX();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: [for (var i = 0; i < 5; i++) Text('Item $i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(pageOf.page, 0.0);

      // Item 4 is one step back only if the list wraps, which it does not.
      unawaited(controller.animateToPage(4));
      await tester.pumpAndSettle();

      expect(pageOf.page, 4.0);
      expect(find.text('Item 4'), findsOneWidget);
    });

    testWidgets('an enlargeFactor of one does not fault the curve', (
      tester,
    ) async {
      // The shrink ratio goes negative for anything more than a page from the
      // centre, and Curves.easeOut asserts on an input outside 0..1.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 0.3,
                initialPage: 2,
                enlargeCenterPage: true,
                enlargeFactor: 1,
                enableInfiniteScroll: false,
              ),
              items: [for (var i = 0; i < 6; i++) Text('Item $i')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('a page number outside the item range is brought into it', (
      tester,
    ) async {
      // On a virtualised carousel it wraps: animateToClosest used to sweep the
      // whole way round to reach a slide that was next door. On any other it is
      // clamped: a jump past the end left the carousel showing nothing while
      // the position sprang back.
      final changed = <int>[];
      Widget carousel({
        required bool infinite,
        required CarouselControllerX controller,
      }) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            carouselController: controller,
            options: CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enableInfiniteScroll: infinite,
            ),
            onPageChanged: changed.add,
            items: [for (var i = 0; i < 5; i++) Text('Item $i')],
          ),
        ),
      );

      final infinite = CarouselControllerX();
      addTearDown(infinite.dispose);
      await tester.pumpWidget(carousel(infinite: true, controller: infinite));
      await tester.pumpAndSettle();

      // 11 names item 1, one slide away — not six. Not awaited: the animation
      // only advances while the tester pumps.
      unawaited(infinite.animateToPage(11));
      await tester.pumpAndSettle();
      expect(changed, [1]);
      expect(find.text('Item 1'), findsOneWidget);

      changed.clear();
      final finite = CarouselControllerX();
      addTearDown(finite.dispose);
      await tester.pumpWidget(carousel(infinite: false, controller: finite));
      await tester.pumpAndSettle();
      changed.clear();

      finite.jumpToPage(9);
      await tester.pump();

      // The last item, on screen at once rather than after a spring back.
      expect(find.text('Item 4'), findsOneWidget);
      expect(changed, [4]);
    });

    testWidgets('items arriving after an empty build restore infinite scroll', (
      tester,
    ) async {
      // With no items the page view is finite and zero pages long, so the
      // position is pinned at zero and the virtual offset the infinite carousel
      // scrolls around is lost.
      await tester.pumpWidget(build(height: 200, items: 0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(height: 200));
      await tester.pumpAndSettle();
      final start = pageOf(tester);

      await tester.drag(find.byType(PageView), const Offset(700, 0));
      await tester.pumpAndSettle();

      expect(pageOf(tester), start - 1);
      expect(find.text('Item 4'), findsOneWidget);
    });
  });

  group('auto play and interaction', () {
    const interval = Duration(seconds: 1);

    Widget buildCarousel(
      void Function(int index) onPageChanged, {
      int items = 3,
      bool enableInfiniteScroll = true,
      CarouselControllerX? controller,
      Duration interval = interval,
      bool pageSnapping = true,
      PageStorageKey<Object>? pageViewKey,
      Axis scrollDirection = Axis.horizontal,
      Duration animation = const Duration(milliseconds: 100),
      bool autoPlay = true,
    }) => MaterialApp(
      home: Scaffold(
        body: CarouselSlider(
          carouselController: controller,
          options: CarouselOptions(
            autoPlay: autoPlay,
            autoPlayInterval: interval,
            autoPlayAnimationDuration: animation,
            viewportFraction: 1.0,
            enableInfiniteScroll: enableInfiniteScroll,
            scrollDirection: scrollDirection,
            pageSnapping: pageSnapping,
            pageViewKey: pageViewKey,
            height: 400,
          ),
          onPageChanged: onPageChanged,
          items: List.generate(items, (i) => Text('Item $i')),
        ),
      ),
    );

    /// Lets [count] auto play intervals elapse, settling each movement.
    Future<void> elapseIntervals(WidgetTester tester, int count) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(interval);
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    testWidgets('turning autoPlay off stops the pending slide', (tester) async {
      // [_scheduleTick] declines to schedule anything once autoPlay is off, so
      // the timer already pending is only stopped by cancelling it outright.
      int pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));
      await elapseIntervals(tester, 1);
      expect(pageChanges, 1);

      await tester.pumpWidget(
        buildCarousel((_) => pageChanges++, autoPlay: false),
      );
      await elapseIntervals(tester, 3);

      expect(pageChanges, 1);
    });

    testWidgets('a held drag holds auto play, releasing resumes it', (
      tester,
    ) async {
      int pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
      await elapseIntervals(tester, 3);

      expect(pageChanges, 0);

      await gesture.up();
      await tester.pumpAndSettle();
      await elapseIntervals(tester, 1);

      expect(pageChanges, 1);
    });

    testWidgets('a press holds auto play without any drag', (tester) async {
      int pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));

      // A lone drag recognizer wins the arena on pointer down, so the position
      // starts a drag activity and reports it even before the finger moves.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      await elapseIntervals(tester, 3);

      expect(pageChanges, 0);

      await gesture.up();
      await tester.pumpAndSettle();
      await elapseIntervals(tester, 1);

      expect(pageChanges, 1);
    });

    testWidgets('a press on a tappable slide holds auto play', (tester) async {
      final tapped = <int>[];
      final shown = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: interval,
                autoPlayAnimationDuration: Duration(milliseconds: 100),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                height: 400,
              ),
              onPageChanged: shown.add,
              items: List.generate(
                3,
                (i) => GestureDetector(
                  onTap: () => tapped.add(i),
                  child: Container(color: const Color(0xFFFFC107)),
                ),
              ),
            ),
          ),
        ),
      );

      // A slide that handles taps keeps the gesture arena open, so the
      // carousel is held rather than scrolling and reports no movement. The
      // press still has to hold auto play, or the card slides away and the
      // tap it was aiming at is swallowed.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      await elapseIntervals(tester, 2);

      expect(shown, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, [0]);
    });

    testWidgets('a trackpad pan holds auto play even when it drives a '
        'scrollable inside a slide', (tester) async {
      int pageChanges = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: interval,
                autoPlayAnimationDuration: Duration(milliseconds: 100),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                height: 400,
              ),
              onPageChanged: (_) => pageChanges++,
              items: List.generate(
                3,
                (i) => ListView(
                  children: List.generate(20, (j) => Text('item $i row $j')),
                ),
              ),
            ),
          ),
        ),
      );

      // The pan moves the inner list, so the carousel's own position never
      // reports movement. Only the pointer tells auto play to stay out.
      final center = tester.getCenter(find.byType(PageView));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(center);
      for (var i = 0; i < 6; i++) {
        await gesture.panZoomUpdate(center, pan: Offset(0, -30.0 * (i + 1)));
        await tester.pump();
      }
      await elapseIntervals(tester, 3);

      expect(pageChanges, 0);

      await gesture.panZoomEnd();
      await tester.pumpAndSettle();
    });

    testWidgets('a trackpad pan holds auto play', (tester) async {
      int pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));

      // A trackpad pan is its own event family, not a pointer going down.
      final center = tester.getCenter(find.byType(PageView));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(center);
      await gesture.panZoomUpdate(center, pan: const Offset(-40, 0));
      await tester.pump();
      await elapseIntervals(tester, 3);

      expect(pageChanges, 0);

      await gesture.panZoomEnd();
      await tester.pumpAndSettle();
    });

    testWidgets('a controller move restarts the interval', (tester) async {
      int pageChanges = 0;
      final controller = CarouselControllerX();
      await tester.pumpWidget(
        buildCarousel((_) => pageChanges++, controller: controller),
      );

      // Move every 800ms, inside the interval. Auto play must never get a turn.
      for (var i = 0; i < 4; i++) {
        controller.nextPage(duration: const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      }

      expect(pageChanges, 4);
      await tester.pumpAndSettle();
    });

    testWidgets('letting go restarts the wait, it does not merely resume', (
      tester,
    ) async {
      final at = <int>[];
      var ms = 0;
      await tester.pumpWidget(buildCarousel((_) => at.add(ms)));

      // Hold from 100ms to 600ms. A tick that merely carried on would land at
      // 1000ms; a restart on release has to push it to 1600ms.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      var released = false;
      while (ms < 2600) {
        if (ms >= 600 && !released) {
          released = true;
          await gesture.up();
        }
        await tester.pump(const Duration(milliseconds: 4));
        ms += 4;
      }

      expect(at, hasLength(1));
      expect(at.single, greaterThan(1500));
    });

    testWidgets('a pointer lifting after disposal leaves no timer', (
      tester,
    ) async {
      await tester.pumpWidget(buildCarousel((_) {}));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );

      // The [Listener] still receives the release from the hit test recorded
      // at pointer down, so a timer armed here would outlive the carousel and
      // never be cancelled.
      await tester.pumpWidget(const SizedBox());
      await gesture.up();
      await elapseIntervals(tester, 3);
    });

    testWidgets('does not move at all when autoPlay is off', (tester) async {
      var pageChanges = 0;
      await tester.pumpWidget(
        buildCarousel((_) => pageChanges++, autoPlay: false),
      );

      await elapseIntervals(tester, 5);

      expect(pageChanges, 0);
    });

    testWidgets('holds until the last of several fingers lifts', (
      tester,
    ) async {
      // Measured on when the slide lands, not on whether one happened: a tick
      // declines while any pointer is down, so a count of page changes cannot
      // tell a held carousel from a moving one.
      final at = <int>[];
      var ms = 0;
      await tester.pumpWidget(buildCarousel((_) => at.add(ms)));

      final centre = tester.getCenter(find.byType(PageView));
      final first = await tester.startGesture(
        centre,
        kind: PointerDeviceKind.touch,
      );
      final second = await tester.startGesture(
        centre + const Offset(20, 0),
        kind: PointerDeviceKind.touch,
      );

      var liftedSecond = false;
      var liftedFirst = false;
      var liftedFirstAt = 0;
      while (ms < 3000) {
        if (ms >= 400 && !liftedSecond) {
          liftedSecond = true;
          await second.up();
        }
        if (ms >= 1200 && !liftedFirst) {
          liftedFirst = true;
          liftedFirstAt = ms;
          await first.up();
        }
        await tester.pump(const Duration(milliseconds: 8));
        ms += 8;
      }

      // One slide, a full interval after the LAST finger left — not after the
      // second one did.
      expect(at, hasLength(1));
      expect(at.single - liftedFirstAt, greaterThanOrEqualTo(1000));
    });

    testWidgets('a cancelled pointer releases the hold', (tester) async {
      var pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      await gesture.cancel();
      await elapseIntervals(tester, 1);

      expect(pageChanges, 1);
    });

    testWidgets('a trackpad pan releases the hold when it ends', (
      tester,
    ) async {
      var pageChanges = 0;
      await tester.pumpWidget(buildCarousel((_) => pageChanges++));

      final centre = tester.getCenter(find.byType(PageView));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(centre);
      await tester.pump();
      await elapseIntervals(tester, 2);
      expect(pageChanges, 0);

      await gesture.panZoomEnd();
      await elapseIntervals(tester, 1);

      expect(pageChanges, 1);
    });

    testWidgets('does not advance while another route covers it', (
      tester,
    ) async {
      var pageChanges = 0;
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: interval,
                autoPlayAnimationDuration: Duration(milliseconds: 100),
                viewportFraction: 1.0,
                height: 400,
              ),
              onPageChanged: (_) => pageChanges++,
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      );
      await tester.pumpAndSettle();
      await elapseIntervals(tester, 3);

      expect(pageChanges, 0);

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await elapseIntervals(tester, 1);

      expect(pageChanges, 1);
    });

    testWidgets('auto play keeps its period, measured slide to slide', (
      tester,
    ) async {
      final at = <int>[];
      var ms = 0;
      await tester.pumpWidget(buildCarousel((_) => at.add(ms)));

      while (ms < 3500) {
        await tester.pump(const Duration(milliseconds: 16));
        ms += 16;
      }

      // One interval apart, not interval + autoPlayAnimationDuration: setting
      // autoPlayInterval to one second has to mean a slide every second.
      expect(at, hasLength(3));
      expect(at[1] - at[0], lessThan(1100));
      expect(at[2] - at[1], lessThan(1100));
    });

    for (final move in <(String, void Function(CarouselControllerX))>[
      ('nextPage', (c) => c.nextPage(duration: _quick)),
      ('previousPage', (c) => c.previousPage(duration: _quick)),
      ('jumpToPage', (c) => c.jumpToPage(2)),
      ('animateToPage', (c) => c.animateToPage(2, duration: _quick)),
    ]) {
      testWidgets('${move.$1} restarts the wait too', (tester) async {
        final at = <int>[];
        var ms = 0;
        final controller = CarouselControllerX();
        await tester.pumpWidget(
          buildCarousel((_) => at.add(ms), controller: controller),
        );

        var moved = false;
        while (ms < 1500) {
          if (ms >= 600 && !moved) {
            moved = true;
            move.$2(controller);
          }
          await tester.pump(const Duration(milliseconds: 4));
          ms += 4;
        }

        // Only the controller's own page change, and it happened when the
        // controller was called — not at ~1000ms, which is where the auto
        // slide would have landed had the move done nothing at all.
        expect(at, hasLength(1));
        expect(at.single, lessThan(800));
      });
    }

    testWidgets('a wheel notch the carousel refuses leaves auto play alone', (
      tester,
    ) async {
      int pageChanges = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: interval,
                autoPlayAnimationDuration: Duration(milliseconds: 100),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                height: 400,
                // Refuses user input, so a notch moves nothing. Auto play
                // drives the position itself and is unaffected.
                scrollPhysics: NeverScrollableScrollPhysics(),
              ),
              onPageChanged: (index) => pageChanges++,
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.byType(PageView))),
      );

      // Notch faster than the interval. A movement that never happens must not
      // keep auto play waiting.
      for (var step = 0; step < 40; step++) {
        if (step % 8 == 0) {
          await tester.sendEventToBinding(pointer.scroll(const Offset(0, 10)));
        }
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(pageChanges, greaterThan(0));
      await tester.pumpAndSettle();
    });

    testWidgets('an interval shorter than the animation still advances once '
        'per cycle', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                // Shorter than the animation: the interval is a rest between
                // movements, so this must not stack ticks on top of a movement
                // already under way.
                autoPlayInterval: Duration(milliseconds: 300),
                autoPlayAnimationDuration: Duration(milliseconds: 800),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                height: 400,
              ),
              onPageChanged: pages.add,
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(pages, [1, 2, 0]);
      await tester.pumpAndSettle();
    });

    testWidgets('a finite carousel wraps and keeps going', (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(
        buildCarousel(pages.add, enableInfiniteScroll: false),
      );

      await elapseIntervals(tester, 5);

      expect(pages, [1, 2, 0, 1, 2]);
      await tester.pumpAndSettle();
    });

    testWidgets('an option change mid-drag does not move the carousel', (
      tester,
    ) async {
      await tester.pumpWidget(buildCarousel((_) {}));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final held = position.pixels;

      // An ordinary rebuild that happens to change an auto play option while a
      // finger is down. Rescheduling here must not let a tick move the carousel
      // out from under the drag.
      await tester.pumpWidget(
        buildCarousel((_) {}, interval: const Duration(milliseconds: 200)),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 150));

      expect(position.pixels, held);

      // Rescheduling must also not have left auto play without a timer: the
      // release settles the drag and auto play carries on from there.
      await gesture.up();
      await tester.pumpAndSettle();
      final settled = position.pixels;
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 150));

      expect(position.pixels, isNot(settled));
    });

    testWidgets('an option change mid-animation does not hijack it', (
      tester,
    ) async {
      final controller = CarouselControllerX();
      await tester.pumpWidget(
        buildCarousel(
          (_) {},
          controller: controller,
          interval: const Duration(seconds: 10),
        ),
      );

      controller.animateToPage(2, duration: const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(
        buildCarousel(
          (_) {},
          controller: controller,
          interval: const Duration(milliseconds: 200),
        ),
      );
      await tester.pumpAndSettle();

      // The controller asked for item 2 and must be the one that decides.
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('without page snapping a tick advances exactly one page', (
      tester,
    ) async {
      await tester.pumpWidget(buildCarousel((_) {}, pageSnapping: false));

      // Come to rest between pages, which only happens without snapping.
      await tester.drag(find.byType(PageView), const Offset(-540, 0));
      await tester.pumpAndSettle();

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final rest = position.pixels / 800;
      expect(rest, closeTo(10000.675, 0.01));

      await elapseIntervals(tester, 1);
      await tester.pumpAndSettle();

      expect(position.pixels / 800, 10001.0);
    });

    testWidgets('a single item carousel does not move', (tester) async {
      // Measured on the position: with one item every index is 0, so no page
      // change can be reported however far auto play drives it.
      final scrolled = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 400,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: interval,
                autoPlayAnimationDuration: Duration(milliseconds: 100),
              ),
              onScrolled: scrolled.add,
              items: const [Text('Item 0')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final position = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position;
      final before = position.pixels;

      await elapseIntervals(tester, 3);

      expect(position.pixels, before);
      expect(scrolled, isEmpty);
    });

    testWidgets('a single item carousel cannot be dragged either', (
      tester,
    ) async {
      // It used to be draggable forever, every slot drawing the one slide it
      // has. Measured on the scroll position, not on what is on screen or on
      // what was reported: with one item every slot draws item 0 and every
      // index reported is 0, so neither can tell a carousel that refused the
      // drag from one that answered it.
      final changed = <int>[];
      await tester.pumpWidget(buildCarousel(changed.add, items: 1));
      await tester.pumpAndSettle();

      double pixels() => tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .position
          .pixels;
      final before = pixels();

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(PageView), const Offset(-700, 0));
        await tester.pumpAndSettle();
      }

      expect(pixels(), before);
      expect(changed, isEmpty);
      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('a second item restores infinite scrolling', (tester) async {
      final changed = <int>[];
      await tester.pumpWidget(buildCarousel(changed.add, items: 1));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildCarousel(changed.add, items: 3));
      await tester.pumpAndSettle();
      changed.clear();

      // Backwards, which only a virtualised page view allows from page zero.
      await tester.drag(find.byType(PageView), const Offset(700, 0));
      await tester.pumpAndSettle();

      expect(changed, [2]);
    });
  });

  group('Infinite Scroll', () {
    testWidgets('wraps around to start', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                initialPage: 0,
              ),
              items: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      // Scroll backwards from start (Item 1)
      await tester.fling(find.text('Item 1'), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Item 3'), findsOneWidget);
    });
  });

  group('Edge Cases & Updates', () {
    testWidgets('renders empty carousel without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(),
              items: const [],
            ),
          ),
        ),
      );

      expect(find.byType(CarouselSlider), findsOneWidget);
    });

    testWidgets('updates when options change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(enableInfiniteScroll: false),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      // Measured on the position: at the default viewport fraction both slides
      // are in the tree whatever the carousel is showing.
      double pageOf() =>
          tester.widget<PageView>(find.byType(PageView)).controller!.page!;

      // A finite carousel cannot go back past its first page.
      final finiteStart = pageOf();
      await tester.fling(find.text('1'), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();
      expect(pageOf(), finiteStart);

      // Update widget with infinite scroll enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(enableInfiniteScroll: true),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      // Turning infinite scroll on puts the carousel back on its starting page,
      // in the virtual space this time — and from there it can go back.
      final infiniteStart = pageOf();
      expect(infiniteStart, greaterThan(finiteStart));

      await tester.fling(find.text('1'), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();
      expect(pageOf(), infiniteStart - 1);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('CarouselController Full API', () {
    late CarouselControllerX controller;

    setUp(() {
      controller = CarouselControllerX();
    });

    testWidgets('animateToPage triggers animation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(enableInfiniteScroll: false),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;
      final before = pageOf.page!;

      unawaited(controller.animateToPage(1));
      await tester.pumpAndSettle();

      // Measured on the position: at the default viewport fraction both slides
      // are in the tree whatever the carousel is showing.
      expect(pageOf.page, before + 1);
    });

    testWidgets('swapping controller updates subscription', (tester) async {
      final controller1 = CarouselControllerX();
      final controller2 = CarouselControllerX();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller1,
              options: const CarouselOptions(enableInfiniteScroll: false),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      // Update widget with new controller
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller2,
              options: const CarouselOptions(enableInfiniteScroll: false),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;
      final before = pageOf.page!;

      // The replacement drives the carousel; the one it replaced does not.
      controller1.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(pageOf.page, before);

      controller2.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(pageOf.page, before + 1);
    });
  });

  group('Complex Logic Coverage', () {
    testWidgets('animateToPage with infinite scroll searches closest', (
      tester,
    ) async {
      final controller = CarouselControllerX();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                enableInfiniteScroll: true,
                initialPage: 0,
                animateToClosest: true,
              ),
              items: const [Text('1'), Text('2'), Text('3'), Text('4')],
            ),
          ),
        ),
      );

      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;
      final before = pageOf.page!;

      unawaited(controller.animateToPage(3));
      await tester.pumpAndSettle();

      // Item 3 of four is one step backwards from item 0, not three forwards.
      // Which item is on screen cannot tell the two apart.
      expect(pageOf.page, before - 1);
    });

    testWidgets('Vertical zoom strategy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.vertical,
                viewportFraction: 0.7,
                initialPage: 1,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              ),
              items: const [Text('0'), Text('1'), Text('2')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The side items shrink towards the centre one, so each anchors on the
      // edge facing it. Which item is on screen says nothing about either.
      expect(
        _transformOf(tester, '1').transform.storage[0],
        closeTo(1.0, 0.01),
      );
      expect(_transformOf(tester, '0').transform.storage[0], lessThan(1.0));
      expect(_transformOf(tester, '0').alignment, Alignment.bottomCenter);
      expect(_transformOf(tester, '2').alignment, Alignment.topCenter);
    });

    testWidgets('Height strategy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 0.7,
                initialPage: 1,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
              ),
              // Boxes that fill their slot: the drawn rect of an item with an
              // intrinsic size says nothing about what happened to its box.
              items: [
                for (var i = 0; i < 3; i++) Container(key: ValueKey('h$i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Rect rectOf(int i) => tester.getRect(find.byKey(ValueKey('h$i')));
      expect(rectOf(1).height, 200);
      expect(rectOf(0).height, lessThan(rectOf(1).height));
      // Across the scroll axis only: the page view pins the extent it scrolls
      // along, whatever the box asks for.
      expect(rectOf(0).width, rectOf(1).width);
    });
  });

  group('onScrolled callback', () {
    testWidgets('is called during scroll', (tester) async {
      final positions = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              onScrolled: (position) {
                positions.add(position);
              },
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      await tester.fling(find.text('Item 1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      // The page view's own position, fractional while the slide moves — not a
      // rounded index. `isNotEmpty` alone would accept either.
      expect(positions, isNotEmpty);
      expect(positions.any((p) => p != p.roundToDouble()), isTrue);
      expect(positions.last, positions.last.roundToDouble());
    });

    testWidgets('is called via controller navigation', (tester) async {
      final controller = CarouselControllerX();
      final positions = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              onScrolled: (position) {
                positions.add(position);
              },
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      unawaited(controller.nextPage());
      await tester.pumpAndSettle();

      // Fractional while the slide runs, whole once it lands. `isNotEmpty`
      // alone would accept a stream of rounded indices.
      expect(positions, isNotEmpty);
      expect(positions.any((p) => p != p.roundToDouble()), isTrue);
      expect(positions.last, positions.last.roundToDouble());
    });
  });

  group('dragDevices', () {
    Widget buildCarousel({
      Set<PointerDeviceKind> dragDevices = CarouselOptions.defaultDragDevices,
      ScrollPhysics? scrollPhysics,
      void Function(int index)? onPageChanged,
    }) => MaterialApp(
      home: Scaffold(
        body: CarouselSlider(
          options: CarouselOptions(
            viewportFraction: 1.0,
            enableInfiniteScroll: false,
            dragDevices: dragDevices,
            scrollPhysics: scrollPhysics,
          ),
          onPageChanged: (index) => onPageChanged?.call(index),
          items: const [Text('Item 1'), Text('Item 2')],
        ),
      ),
    );

    testWidgets('defaults to every PointerDeviceKind', (tester) async {
      await tester.pumpWidget(buildCarousel());

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(
        pageView.scrollBehavior?.dragDevices,
        CarouselOptions.defaultDragDevices,
      );
    });

    testWidgets('takes precedence over an enclosing ScrollConfiguration', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(
              dragDevices: const {PointerDeviceKind.stylus},
            ),
            child: Scaffold(
              body: CarouselSlider(
                items: const [Text('Item 1'), Text('Item 2')],
              ),
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(
        pageView.scrollBehavior?.dragDevices,
        CarouselOptions.defaultDragDevices,
      );
    });

    /// Drags the carousel a page back with a trackpad.
    ///
    /// A trackpad reports a pan as its own event family, so
    /// [WidgetTester.drag] cannot send one.
    Future<void> trackpadDrag(WidgetTester tester) async {
      final center = tester.getCenter(find.byType(PageView));
      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.trackpad,
      );
      await gesture.panZoomStart(center);
      await gesture.panZoomUpdate(center, pan: const Offset(-600, 0));
      await gesture.panZoomEnd();
      await tester.pumpAndSettle();
    }

    testWidgets('a trackpad drag moves the carousel', (tester) async {
      final pageChanges = <int>[];
      await tester.pumpWidget(buildCarousel(onPageChanged: pageChanges.add));

      await trackpadDrag(tester);

      expect(pageChanges, [1]);
    });

    testWidgets('a trackpad drag is refused when it is left out', (
      tester,
    ) async {
      final pageChanges = <int>[];
      await tester.pumpWidget(
        buildCarousel(
          dragDevices: const {PointerDeviceKind.touch},
          onPageChanged: pageChanges.add,
        ),
      );

      await trackpadDrag(tester);

      expect(pageChanges, isEmpty);
    });

    testWidgets('an explicit set narrows the accepted devices', (tester) async {
      final pageChanges = <int>[];
      await tester.pumpWidget(
        buildCarousel(
          dragDevices: const {PointerDeviceKind.touch},
          onPageChanged: pageChanges.add,
        ),
      );

      await tester.drag(
        find.byType(PageView),
        const Offset(-600, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();

      expect(pageChanges, isEmpty);

      await tester.drag(
        find.byType(PageView),
        const Offset(-600, 0),
        kind: PointerDeviceKind.touch,
      );
      await tester.pumpAndSettle();

      expect(pageChanges, [1]);
    });

    testWidgets('NeverScrollableScrollPhysics stops every drag', (
      tester,
    ) async {
      final pageChanges = <int>[];
      await tester.pumpWidget(
        buildCarousel(
          scrollPhysics: const NeverScrollableScrollPhysics(),
          onPageChanged: pageChanges.add,
        ),
      );

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pumpAndSettle();

      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.pixels, 0);
      expect(pageChanges, isEmpty);
    });
  });

  group('animateToClosest option', () {
    testWidgets('when false, does not search for closest path', (tester) async {
      final controller = CarouselControllerX();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                enableInfiniteScroll: true,
                initialPage: 0,
                animateToClosest: false,
              ),
              items: const [Text('1'), Text('2'), Text('3'), Text('4')],
            ),
          ),
        ),
      );

      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;
      final before = pageOf.page!;

      unawaited(controller.animateToPage(3));
      await tester.pumpAndSettle();

      // Straight there: three pages forwards, not the one page backwards the
      // closest occurrence would have been. Both land on item 3, so which item
      // is on screen cannot tell them apart.
      expect(pageOf.page, before + 3);
    });

    testWidgets(
      'when true, chooses backward wrap when it is the shortest path',
      (tester) async {
        // Regression: duplicate condition bug caused backward wrap to never
        // be selected. With 10 items at page 1, animateToPage(9) should go
        // backward 2 steps (1->0->9) instead of forward 8 steps (1->2->...->9).
        final controller = CarouselControllerX();
        int? lastChangedIndex;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CarouselSlider(
                carouselController: controller,
                options: const CarouselOptions(
                  enableInfiniteScroll: true,
                  initialPage: 1,
                  animateToClosest: true,
                  viewportFraction: 1.0,
                ),
                onPageChanged: (index) {
                  lastChangedIndex = index;
                },
                items: List.generate(10, (i) => Text('P$i')),
              ),
            ),
          ),
        );

        expect(find.text('P1'), findsOneWidget);

        // The resulting item is the same either way, so assert the distance
        // that was actually travelled.
        final pageBefore = tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .page!;

        controller.animateToPage(9);
        await tester.pumpAndSettle();

        final pageAfter = tester
            .widget<PageView>(find.byType(PageView))
            .controller!
            .page!;

        expect(pageAfter - pageBefore, -2.0);
        expect(lastChangedIndex, 9);
        expect(find.text('P9'), findsOneWidget);
      },
    );
  });

  group('Enlarge Strategies', () {
    testWidgets('Scale strategy renders with Transform.scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 0.7,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                initialPage: 1,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      // Center item (Item 1) should exist with Transform
      final item1TransformFinder = find
          .ancestor(of: find.text('Item 1'), matching: find.byType(Transform))
          .first;
      final transform1 = tester.widget<Transform>(item1TransformFinder);
      final scale1 = transform1.transform.storage[0];

      expect(scale1, closeTo(1.0, 0.01));

      // A side item is scaled down, so the strategy is doing something.
      final transform0 = tester.widget<Transform>(
        find
            .ancestor(of: find.text('Item 0'), matching: find.byType(Transform))
            .first,
      );
      expect(transform0.transform.storage[0], lessThan(1.0));
    });

    for (final direction in TextDirection.values) {
      testWidgets('the zoom anchor follows a ${direction.name} layout', (
        tester,
      ) async {
        // A right-to-left [Directionality] lays the pages out the other way
        // round, and a non-directional alignment would leave every side item
        // anchored on the edge facing away from the centre.
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: Scaffold(
                body: CarouselSlider(
                  options: const CarouselOptions(
                    viewportFraction: 0.7,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.5,
                    enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                    initialPage: 1,
                    enableInfiniteScroll: false,
                  ),
                  // Filling boxes rather than text: the drawn rect of an item
                  // with an intrinsic size says nothing about its slot.
                  items: [
                    for (var i = 0; i < 3; i++)
                      Container(key: ValueKey('box$i')),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Rect rectOf(int i) => tester.getRect(find.byKey(ValueKey('box$i')));
        final centre = rectOf(1);
        final before = rectOf(0);
        final after = rectOf(2);

        expect(before.width, lessThan(centre.width));
        expect(after.width, lessThan(centre.width));
        switch (direction) {
          case TextDirection.ltr:
            expect(before.right, closeTo(centre.left, 0.01));
            expect(after.left, closeTo(centre.right, 0.01));
          case TextDirection.rtl:
            expect(before.left, closeTo(centre.right, 0.01));
            expect(after.right, closeTo(centre.left, 0.01));
        }
      });
    }

    testWidgets('zoom alignment holds while the carousel is between pages', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                enlargeFactor: 0.4,
              ),
              items: [
                for (var i = 0; i < 5; i++) Container(key: ValueKey('box$i')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag towards the next page and hold, so that `box0` sits before the
      // centre at a fractional offset.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-270, 0));
      await tester.pump();

      final page = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      expect(page, greaterThan(10000.1));
      expect(page, lessThan(10000.9));

      // It has to shrink towards the centre for the whole drag, not only once
      // the offset lands on a whole page: the edge facing the centre stays
      // where the un-scaled slot puts it while the far edge moves in.
      // It has to shrink towards the centre for the whole drag, not only once
      // the offset lands on a whole page. Each slide's slot is fixed, so the
      // edge facing the centre stays on the slot boundary the two share while
      // the far edge moves in.
      final before = tester.getRect(find.byKey(const ValueKey('box0')));
      final after = tester.getRect(find.byKey(const ValueKey('box1')));
      final slot = tester.getSize(find.byType(PageView)).width * 0.8;

      expect(after.left, closeTo(before.right, 0.01));
      expect(before.width, lessThan(slot));
      expect(after.width, lessThan(slot));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('vertical zoom alignment holds while between pages', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.vertical,
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                enlargeFactor: 0.4,
              ),
              items: List.generate(5, (i) => Text('Item $i')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();

      final page = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      expect(page, greaterThan(10000.1));
      expect(page, lessThan(10000.9));

      expect(_transformOf(tester, 'Item 0').alignment, Alignment.bottomCenter);
      expect(_transformOf(tester, 'Item 1').alignment, Alignment.topCenter);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the zoom item does not jump when the scroll settles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                enlargeFactor: 0.4,
              ),
              items: List.generate(5, (i) => Text('Item $i')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(-60, 0));
        await tester.pump();
      }
      await gesture.up();

      // Follow the item that was in the centre all the way to its resting
      // position. It has to stay on screen and move continuously.
      var previousLeft = tester.getRect(find.text('Item 0')).left;
      var largestStep = 0.0;
      void measure() {
        expect(find.text('Item 0'), findsOneWidget);
        final left = tester.getRect(find.text('Item 0')).left;
        final step = (left - previousLeft).abs();
        if (step > largestStep) largestStep = step;
        previousLeft = left;
      }

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        measure();
      }
      await tester.pumpAndSettle();
      measure();

      expect(largestStep, lessThan(20.0));
    });

    testWidgets('the side item is scaled down along the easeOut curve', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 0.7,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                enlargeFactor: 0.3,
                initialPage: 1,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The side item sits exactly one page away, so
      // distortionRatio = 1 - 1 * 0.3.
      final expected = Curves.easeOut.transform(0.7);
      expect(expected, isNot(closeTo(0.7, 0.02)));
      expect(
        _transformOf(tester, 'Item 0').transform.storage[0],
        closeTo(expected, 0.01),
      );
    });

    testWidgets('enlargeFactor is clamped to 1.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                enlargeFactor: 2.0,
                initialPage: 1,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 0'), Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Hold the drag so that the centre item sits at a fractional offset,
      // where an unclamped factor of 2.0 would collapse it to zero.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-370, 0));
      await tester.pump();

      final page = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      final itemOffset = (page - 1).abs();
      expect(itemOffset, greaterThan(0.1));
      expect(itemOffset, lessThan(0.9));

      final expected = Curves.easeOut.transform(
        (1.0 - itemOffset).clamp(0.0, 1.0),
      );
      expect(expected, greaterThan(0.0));
      expect(
        _transformOf(tester, 'Item 1').transform.storage[0],
        closeTo(expected, 0.01),
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('disableCenter', () {
    testWidgets('when true, Center widget is not added', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                disableCenter: true,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1')],
            ),
          ),
        ),
      );

      // Center should not wrap the item text
      expect(
        find.ancestor(of: find.text('Item 1'), matching: find.byType(Center)),
        findsNothing,
      );
    });

    testWidgets('when false, Center widget wraps each item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                disableCenter: false,
                enableInfiniteScroll: false,
              ),
              items: const [Text('Item 1')],
            ),
          ),
        ),
      );

      expect(
        find.ancestor(of: find.text('Item 1'), matching: find.byType(Center)),
        findsOneWidget,
      );
    });
  });

  group('Vertical scrolling', () {
    testWidgets('scrolls vertically', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.vertical,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                height: 400,
              ),
              items: const [Text('Item 1'), Text('Item 2')],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);

      // Fling vertically (upward)
      await tester.fling(find.text('Item 1'), const Offset(0, -500), 2000);
      await tester.pumpAndSettle();

      expect(find.text('Item 2'), findsOneWidget);
    });
  });

  group('didUpdateWidget', () {
    testWidgets('updates page controller when initialPage changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(
                initialPage: 0,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2'), Text('3')],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      // Update with new initialPage
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(
                initialPage: 2,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2'), Text('3')],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('handles autoPlay toggle via options update', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(
                autoPlay: false,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      // Enable auto play
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              key: const ValueKey('carousel'),
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 1),
                autoPlayAnimationDuration: Duration(milliseconds: 200),
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);

      // Wait for auto play
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('replaced carouselController drives the carousel', (
      tester,
    ) async {
      final first = CarouselControllerX();
      final second = CarouselControllerX();

      Widget build(CarouselControllerX controller) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: const CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
            ),
            carouselController: controller,
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(first));
      expect(find.text('1'), findsOneWidget);

      // Swap the controller without touching the options.
      await tester.pumpWidget(build(second));
      await tester.pumpAndSettle();

      second.nextPage(duration: const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a replaced carouselController stops driving the carousel', (
      tester,
    ) async {
      final first = CarouselControllerX();
      final second = CarouselControllerX();

      Widget build(CarouselControllerX controller) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: const CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
            ),
            carouselController: controller,
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(first));
      expect(find.text('1'), findsOneWidget);

      await tester.pumpWidget(build(second));
      await tester.pumpAndSettle();

      // The detached controller must not move the carousel any more.
      first.nextPage(duration: const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('resets the position when enableInfiniteScroll changes', (
      tester,
    ) async {
      Widget build(bool enableInfiniteScroll) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: enableInfiniteScroll,
            ),
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(false));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Infinite scroll moves the origin of the virtual index, so the position
      // has to follow it to keep showing the same item.
      await tester.pumpWidget(build(true));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('keeps the scroll position when unrelated options change', (
      tester,
    ) async {
      Widget build(Duration autoPlayInterval) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              autoPlayInterval: autoPlayInterval,
            ),
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(const Duration(seconds: 4)));
      await tester.pumpAndSettle();

      // Hold the drag so that the position stays between two pages.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await tester.pump();
      // The first move only has to pass the drag slop.
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-170, 0));
      await tester.pump();

      final pageBefore = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      expect(pageBefore, greaterThan(0.0));
      expect(pageBefore, lessThan(1.0));

      await tester.pumpWidget(build(const Duration(seconds: 2)));
      await tester.pump();

      final pageAfter = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;
      expect(pageAfter, pageBefore);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the page controller when unrelated options change', (
      tester,
    ) async {
      Widget build(Duration autoPlayInterval) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              autoPlayInterval: autoPlayInterval,
            ),
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(const Duration(seconds: 4)));
      await tester.pumpAndSettle();

      final controllerBefore = tester
          .widget<PageView>(find.byType(PageView))
          .controller;

      await tester.pumpWidget(build(const Duration(seconds: 2)));
      await tester.pumpAndSettle();

      final controllerAfter = tester
          .widget<PageView>(find.byType(PageView))
          .controller;

      expect(identical(controllerBefore, controllerAfter), isTrue);
    });

    testWidgets('a new autoPlayInterval restarts the running timer', (
      tester,
    ) async {
      Widget build(Duration autoPlayInterval) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: autoPlayInterval,
              autoPlayAnimationDuration: const Duration(milliseconds: 100),
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
            ),
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(const Duration(milliseconds: 5000)));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));

      // The original timer would only fire at t=5000ms, well past the end of
      // this test; the restarted one has to fire at t=900ms.
      await tester.pumpWidget(build(const Duration(milliseconds: 300)));

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('recreates the page controller when viewportFraction changes', (
      tester,
    ) async {
      Widget build(double viewportFraction) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            key: const ValueKey('carousel'),
            options: CarouselOptions(
              viewportFraction: viewportFraction,
              enableInfiniteScroll: false,
            ),
            items: const [Text('1'), Text('2'), Text('3')],
          ),
        ),
      );

      await tester.pumpWidget(build(1.0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(build(0.5));
      await tester.pumpAndSettle();

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller;

      expect(controller?.viewportFraction, 0.5);
    });
  });

  group('CarouselControllerX dispose safety', () {
    testWidgets('dispose clears the callbacks the carousel installed', (
      tester,
    ) async {
      // A controller that was never attached has null callbacks already, so
      // calling one is silent whatever dispose does. It has to be attached
      // first for the clearing to be observable.
      final controller = CarouselControllerX();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2'), Text('3')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;

      controller.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(pageOf.page, 1.0);

      controller.dispose();
      controller.jumpToPage(2);
      await tester.pumpAndSettle();

      expect(pageOf.page, 1.0);
    });

    testWidgets('a controller outlives the carousel it was driving', (
      tester,
    ) async {
      final controller = CarouselControllerX();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2'), Text('3')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());

      // The callbacks the controller is left holding name a state that is
      // gone, so they decline rather than throwing.
      controller.jumpToPage(2);
      await controller.nextPage();
      await tester.pumpAndSettle();

      // And a carousel built later with the same controller is drivable.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                height: 200,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2'), Text('3')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pageOf = tester.widget<PageView>(find.byType(PageView)).controller!;

      controller.jumpToPage(2);
      await tester.pumpAndSettle();

      expect(pageOf.page, 2.0);
    });
  });

  group('animateToClosest forward wrap', () {
    testWidgets('chooses forward wrap when it is the shortest path', (
      tester,
    ) async {
      // With 10 items at page 9, animateToPage(0) should go forward 1 step
      // (9->0) instead of backward 9 steps (9->8->...->0).
      // distance = |0-9| = 9
      // distanceWithNext = |0+10-9| = 1 (shorter!)
      // distanceWithPrev = |0-10-9| = 19
      final controller = CarouselControllerX();
      int? lastChangedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                enableInfiniteScroll: true,
                initialPage: 9,
                animateToClosest: true,
                viewportFraction: 1.0,
              ),
              onPageChanged: (index) {
                lastChangedIndex = index;
              },
              items: List.generate(10, (i) => Text('P$i')),
            ),
          ),
        ),
      );

      expect(find.text('P9'), findsOneWidget);

      // The resulting item is the same either way, so assert the distance
      // that was actually travelled.
      final pageBefore = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;

      controller.animateToPage(0);
      await tester.pumpAndSettle();

      final pageAfter = tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .page!;

      expect(pageAfter - pageBefore, 1.0);
      expect(lastChangedIndex, 0);
      expect(find.text('P0'), findsOneWidget);
    });
  });

  group('PageStorage', () {
    testWidgets('restores page position when widget is rebuilt', (
      tester,
    ) async {
      final bucket = PageStorageBucket();
      const pageKey = PageStorageKey<String>('carousel_restore_test');

      // First: create carousel and scroll to page 1
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageStorage(
              bucket: bucket,
              child: CarouselSlider(
                options: const CarouselOptions(
                  pageViewKey: pageKey,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                ),
                items: const [Text('A'), Text('B'), Text('C')],
              ),
            ),
          ),
        ),
      );

      // Scroll to page 1
      await tester.fling(find.text('A'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);

      // Torn down and built again, not merely rebuilt: a carousel whose state
      // survives keeps its position without any storage being involved.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageStorage(bucket: bucket, child: SizedBox()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageStorage(
              bucket: bucket,
              child: CarouselSlider(
                options: const CarouselOptions(
                  pageViewKey: pageKey,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                ),
                items: const [Text('A'), Text('B'), Text('C')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The page should be restored from PageStorage
      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1.0,
      );
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('keeps its page across a Navigator push and pop', (
      tester,
    ) async {
      // Not a storage test: a pushed route keeps the one below it in the tree,
      // so the carousel's state — and its position — simply survive. Storage is
      // covered by the teardown test above.
      int? lastPage;

      final navigatorKey = GlobalKey<NavigatorState>();

      Widget buildCarousel() {
        return CarouselSlider(
          options: const CarouselOptions(
            pageViewKey: PageStorageKey<String>('nav_test'),
            enableInfiniteScroll: false,
            viewportFraction: 1.0,
          ),
          onPageChanged: (index) {
            lastPage = index;
          },
          items: const [Text('Page0'), Text('Page1'), Text('Page2')],
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: Scaffold(body: buildCarousel()),
        ),
      );

      // Scroll to page 1
      await tester.fling(find.text('Page0'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.text('Page1'), findsOneWidget);
      expect(lastPage, 1);

      // Push a new route
      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Other')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(
        tester.widget<PageView>(find.byType(PageView)).controller!.page,
        1.0,
      );
      expect(find.text('Page1'), findsOneWidget);
      expect(lastPage, 1);
    });

    testWidgets('the restored position drives the first enlarge pass', (
      tester,
    ) async {
      final bucket = PageStorageBucket();
      const pageKey = PageStorageKey<String>('carousel_enlarge_restore');

      Widget build() => MaterialApp(
        home: Scaffold(
          body: PageStorage(
            bucket: bucket,
            child: CarouselSlider(
              options: const CarouselOptions(
                pageViewKey: pageKey,
                enableInfiniteScroll: false,
                viewportFraction: 1.0,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                enlargeFactor: 0.3,
              ),
              items: const [Text('A'), Text('B'), Text('C')],
            ),
          ),
        ),
      );

      await tester.pumpWidget(build());
      await tester.fling(find.text('A'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);

      // Rebuild from scratch. On the very first frame the new PageController
      // has no clients yet, so the scale has to come from PageStorage rather
      // than from the initial page.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(build());

      expect(
        _transformOf(tester, 'B').transform.storage[0],
        closeTo(1.0, 0.01),
      );
    });

    testWidgets('builds without a PageStorage ancestor', (tester) async {
      // A carousel does not require a [Navigator] above it, so there may be no
      // bucket to restore a position from.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CarouselSlider(
            options: const CarouselOptions(
              height: 200,
              viewportFraction: 1.0,
              enlargeCenterPage: true,
            ),
            items: const [Text('A'), Text('B'), Text('C')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });
  });

  group('resource disposal', () {
    testWidgets('the PageController is disposed with the carousel', (
      tester,
    ) async {
      // A leaked [PageController] keeps its listeners, and this one holds a
      // closure over the [State].
      final disposed = <Object>[];
      void record(ObjectEvent event) {
        if (event is ObjectDisposed && event.object is PageController) {
          disposed.add(event.object);
        }
      }

      FlutterMemoryAllocations.instance.addListener(record);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(record),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: CarouselOptions(height: 400),
              items: [Text('Item 0'), Text('Item 1')],
            ),
          ),
        ),
      );
      expect(disposed, isEmpty);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      expect(disposed, hasLength(1));
    });

    testWidgets('a replaced PageController is disposed too', (tester) async {
      final disposed = <Object>[];
      void record(ObjectEvent event) {
        if (event is ObjectDisposed && event.object is PageController) {
          disposed.add(event.object);
        }
      }

      FlutterMemoryAllocations.instance.addListener(record);
      addTearDown(
        () => FlutterMemoryAllocations.instance.removeListener(record),
      );

      Widget build(double viewportFraction) => MaterialApp(
        home: Scaffold(
          body: CarouselSlider(
            options: CarouselOptions(
              height: 400,
              viewportFraction: viewportFraction,
            ),
            items: const [Text('Item 0'), Text('Item 1')],
          ),
        ),
      );

      await tester.pumpWidget(build(0.8));
      await tester.pumpWidget(build(0.6));
      await tester.pumpAndSettle();

      expect(disposed, hasLength(1));
    });
  });

  group('AutoPlay dispose safety', () {
    testWidgets('no crash when disposed during autoplay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(milliseconds: 100),
                autoPlayAnimationDuration: Duration(milliseconds: 50),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
              ),
              items: const [Text('Item 1'), Text('Item 2'), Text('Item 3')],
            ),
          ),
        ),
      );

      // Let auto play run
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      // Dispose by replacing widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('New Page'))),
      );

      expect(find.text('New Page'), findsOneWidget);

      // Nothing else here: the test ends with the carousel gone and no time
      // elapsed, so a timer that outlived it is still pending, and
      // testWidgets fails the test for it. Pumping past its next firing —
      // which this test used to do — lets it fire, find itself unmounted and
      // return quietly, and the leak goes unnoticed.
    });
  });
}

Widget _emptyItem(BuildContext context, int index, int realIndex) =>
    const SizedBox();

/// A slide that remembers something, so that a rebuild throwing its state away
/// is visible.
class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text('$taps'),
  );
}
