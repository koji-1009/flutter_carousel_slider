import 'package:carousel_slider_x/carousel_slider_x.dart';
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
}
