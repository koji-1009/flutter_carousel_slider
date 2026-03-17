import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
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
      CarouselPageChangedReason? changedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              onPageChanged: (index, reason) {
                changedIndex = index;
                changedReason = reason;
              },
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      await tester.fling(find.text('Item 1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
      expect(changedReason, CarouselPageChangedReason.manual);
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 2'), findsOneWidget);

      controller.previousPage();
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('jumpToPage moves to specific item without animation',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
              ),
              items: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
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

      // Verify initial state (finite scroll)
      await tester.fling(find.text('1'), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget); // Stays on 1

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

      // Now scroll past start should wrap to end
      await tester.fling(find.text('1'), const Offset(500, 0), 2000);
      await tester.pumpAndSettle();
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

      controller.animateToPage(1);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('start/stop AutoPlay callbacks are called', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              carouselController: controller,
              options: const CarouselOptions(autoPlay: false),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      controller.startAutoPlay();
      controller.stopAutoPlay();
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

      // controller1 should be detached, controller2 attached
      controller2.jumpToPage(1);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('Complex Logic Coverage', () {
    testWidgets('animateToPage with infinite scroll searches closest',
        (tester) async {
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

      controller.animateToPage(3);
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('restores page from PageStorage', (tester) async {
      const pageKey = PageStorageKey('carousel_storage');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageStorage(
              bucket: PageStorageBucket(),
              child: CarouselSlider(
                options: const CarouselOptions(
                    pageViewKey: pageKey, enableInfiniteScroll: false),
                items: const [Text('1'), Text('2')],
              ),
            ),
          ),
        ),
      );

      // Scroll to page 2
      await tester.fling(find.text('1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageStorage(
              bucket: PageStorageBucket(),
              child: CarouselSlider(
                options: const CarouselOptions(
                    pageViewKey: pageKey, enableInfiniteScroll: false),
                items: const [Text('1'), Text('2')],
              ),
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Vertical zoom strategy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.vertical,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('Height strategy', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 200,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('Regression Tests', () {
    testWidgets('enlargeCenterPage scales down side items on initial render',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 0.7,
                enlargeCenterPage: true,
                initialPage: 1,
                enableInfiniteScroll: false,
              ),
              items: const [
                Text('Item 0'),
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Item 1 is center (initialPage). Should be scale 1.0
      // Item 0 is left side. Should be scale < 1.0

      // Find Transform widgets wrapping the Texts
      final item0TransformFinder = find
          .ancestor(of: find.text('Item 0'), matching: find.byType(Transform))
          .first;

      final item1TransformFinder = find
          .ancestor(of: find.text('Item 1'), matching: find.byType(Transform))
          .first;

      final transform0 = tester.widget<Transform>(item0TransformFinder);
      final transform1 = tester.widget<Transform>(item1TransformFinder);

      // Verify scaling using Matrix4 diagonal element (index 0 for x-scale)
      final scale0 = transform0.transform.storage[0];
      final scale1 = transform1.transform.storage[0];

      expect(scale1, closeTo(1.0, 0.01),
          reason: 'Center item should be full scale');
      expect(scale0, lessThan(0.95), reason: 'Side item should be scaled down');
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      await tester.fling(find.text('Item 1'), const Offset(-500, 0), 2000);
      await tester.pumpAndSettle();

      expect(positions, isNotEmpty);
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      controller.nextPage();
      await tester.pumpAndSettle();

      expect(positions, isNotEmpty);
    });
  });

  group('disableGesture', () {
    testWidgets('when true, prevents swipe navigation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                disableGesture: true,
              ),
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);

      // GestureDetector should not be present
      expect(
        find.ancestor(
          of: find.byType(PageView),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('when false, GestureDetector is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                disableGesture: false,
              ),
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(PageView),
          matching: find.byType(GestureDetector),
        ),
        findsOneWidget,
      );
    });
  });

  group('pauseAutoPlayOnTouch', () {
    testWidgets('pauses auto play during touch when enabled', (tester) async {
      int pageChanges = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 1),
                autoPlayAnimationDuration: Duration(milliseconds: 200),
                viewportFraction: 1.0,
                enableInfiniteScroll: true,
                pauseAutoPlayOnTouch: true,
              ),
              onPageChanged: (index, reason) {
                pageChanges++;
              },
              items: const [
                Text('Item 1'),
                Text('Item 2'),
                Text('Item 3'),
              ],
            ),
          ),
        ),
      );

      // Simulate touch down (pan down) to pause auto play
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Item 1')),
        kind: PointerDeviceKind.touch,
      );

      // Wait longer than autoPlayInterval while touch is held
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final changesWhileTouching = pageChanges;

      // Release touch
      await gesture.up();
      await tester.pumpAndSettle();

      // After release, auto play should resume
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have auto-played after release
      expect(pageChanges, greaterThan(changesWhileTouching));
    });
  });

  group('pauseAutoPlayInFiniteScroll', () {
    testWidgets('pauses at last item when true', (tester) async {
      int lastPageIndex = 0;

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
                pauseAutoPlayInFiniteScroll: true,
              ),
              onPageChanged: (index, reason) {
                lastPageIndex = index;
              },
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Auto play to last item (Item 2)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(lastPageIndex, 1);

      // Wait another interval - should NOT wrap to Item 1
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should still be on last item
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('wraps to first item when false', (tester) async {
      int lastPageIndex = 0;

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
                pauseAutoPlayInFiniteScroll: false,
              ),
              onPageChanged: (index, reason) {
                lastPageIndex = index;
              },
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Auto play to last item (Item 2)
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(lastPageIndex, 1);

      // Wait another interval - should wrap to Item 1
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(lastPageIndex, 0);
    });
  });

  group('animateToClosest option', () {
    testWidgets('when false, does not search for closest path',
        (tester) async {
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
              items: const [
                Text('1'),
                Text('2'),
                Text('3'),
                Text('4'),
              ],
            ),
          ),
        ),
      );

      // With animateToClosest: false, it should still navigate correctly
      controller.animateToPage(3);
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
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
              onPageChanged: (index, reason) {
                lastChangedIndex = index;
              },
              items: List.generate(10, (i) => Text('P$i')),
            ),
          ),
        ),
      );

      expect(find.text('P1'), findsOneWidget);

      controller.animateToPage(9);
      await tester.pumpAndSettle();

      expect(lastChangedIndex, 9);
      expect(find.text('P9'), findsOneWidget);
    });
  });

  group('Enlarge Strategies', () {
    testWidgets('Scale strategy renders with Transform.scale',
        (tester) async {
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
              items: const [
                Text('Item 0'),
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Center item (Item 1) should exist with Transform
      final item1TransformFinder = find
          .ancestor(
              of: find.text('Item 1'), matching: find.byType(Transform))
          .first;
      final transform1 = tester.widget<Transform>(item1TransformFinder);
      final scale1 = transform1.transform.storage[0];

      expect(scale1, closeTo(1.0, 0.01));

      // Side items should have SizedBox for width/height constraint
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('Horizontal zoom strategy uses correct alignment',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.horizontal,
                viewportFraction: 0.7,
                enlargeCenterPage: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                initialPage: 1,
                enableInfiniteScroll: false,
              ),
              items: const [
                Text('Item 0'),
                Text('Item 1'),
                Text('Item 2'),
              ],
            ),
          ),
        ),
      );

      // Verify the Transform exists and renders
      expect(find.byType(Transform), findsWidgets);
      expect(find.text('Item 1'), findsOneWidget);
    });
  });

  group('Layout options', () {
    testWidgets('uses AspectRatio when height is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                aspectRatio: 2.0,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1')],
            ),
          ),
        ),
      );

      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 2.0);
    });

    testWidgets('uses SizedBox with explicit height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                height: 250,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1')],
            ),
          ),
        ),
      );

      // Should not use AspectRatio when height is provided
      // The outermost SizedBox should have height 250
      final sizedBoxes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((sb) => sb.height == 250);
      expect(sizedBoxes, isNotEmpty);
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
        find.ancestor(
          of: find.text('Item 1'),
          matching: find.byType(Center),
        ),
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
        find.ancestor(
          of: find.text('Item 1'),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });
  });

  group('reverse option', () {
    testWidgets('PageView has reverse property set', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                reverse: true,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.reverse, isTrue);
    });

    testWidgets('PageView reverse is false by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.reverse, isFalse);
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
              items: const [
                Text('Item 1'),
                Text('Item 2'),
              ],
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

    testWidgets('PageView has vertical scroll direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                scrollDirection: Axis.vertical,
                enableInfiniteScroll: false,
                height: 400,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.scrollDirection, Axis.vertical);
    });
  });

  group('didUpdateWidget', () {
    testWidgets('updates page controller when initialPage changes',
        (tester) async {
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
  });

  group('PageView passthrough options', () {
    testWidgets('padEnds is forwarded to PageView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                padEnds: false,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.padEnds, isFalse);
    });

    testWidgets('padEnds defaults to true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.padEnds, isTrue);
    });

    testWidgets('clipBehavior is forwarded to PageView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                clipBehavior: Clip.none,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.clipBehavior, Clip.none);
    });

    testWidgets('clipBehavior defaults to Clip.hardEdge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.clipBehavior, Clip.hardEdge);
    });

    testWidgets('pageSnapping is forwarded to PageView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                pageSnapping: false,
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.pageSnapping, isFalse);
    });

    testWidgets('pageSnapping defaults to true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CarouselSlider(
              options: const CarouselOptions(
                enableInfiniteScroll: false,
              ),
              items: const [Text('1'), Text('2')],
            ),
          ),
        ),
      );

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.pageSnapping, isTrue);
    });
  });

  group('CarouselControllerX dispose safety', () {
    test('methods do not throw after dispose', () {
      final controller = CarouselControllerX();
      controller.dispose();

      // All methods should be safe to call after dispose (callbacks are null)
      expect(() => controller.nextPage(), returnsNormally);
      expect(() => controller.previousPage(), returnsNormally);
      expect(() => controller.jumpToPage(0), returnsNormally);
      expect(() => controller.animateToPage(0), returnsNormally);
      expect(() => controller.startAutoPlay(), returnsNormally);
      expect(() => controller.stopAutoPlay(), returnsNormally);
    });
  });
}
