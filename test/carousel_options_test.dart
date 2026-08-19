import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// One [CarouselOptions] per field, each differing from `const CarouselOptions()`
/// in that single field only.
const _variants = <CarouselOptions>[
  CarouselOptions(height: 200),
  CarouselOptions(aspectRatio: 4 / 3),
  CarouselOptions(viewportFraction: 0.5),
  CarouselOptions(initialPage: 1),
  CarouselOptions(enableInfiniteScroll: false),
  CarouselOptions(animateToClosest: false),
  CarouselOptions(reverse: true),
  CarouselOptions(autoPlay: true),
  CarouselOptions(autoPlayInterval: Duration(seconds: 1)),
  CarouselOptions(autoPlayAnimationDuration: Duration(seconds: 1)),
  CarouselOptions(autoPlayCurve: Curves.linear),
  CarouselOptions(enlargeCenterPage: true),
  CarouselOptions(scrollPhysics: BouncingScrollPhysics()),
  CarouselOptions(pageSnapping: false),
  CarouselOptions(scrollDirection: Axis.vertical),
  CarouselOptions(pageViewKey: PageStorageKey('key')),
  CarouselOptions(enlargeStrategy: CenterPageEnlargeStrategy.zoom),
  CarouselOptions(enlargeFactor: 0.5),
  CarouselOptions(disableCenter: true),
  CarouselOptions(dragDevices: {PointerDeviceKind.touch}),
  CarouselOptions(padEnds: false),
  CarouselOptions(clipBehavior: Clip.none),
];

void main() {
  group('CarouselOptions', () {
    test('supports value equality', () {
      const options1 = CarouselOptions(height: 200, enableInfiniteScroll: true);
      const options2 = CarouselOptions(height: 200, enableInfiniteScroll: true);
      const options3 = CarouselOptions(
        height: 300,
        enableInfiniteScroll: false,
      );

      expect(options1, equals(options2));
      expect(options1, isNot(equals(options3)));
      expect(options1.hashCode, options2.hashCode);
      expect(options1.hashCode, isNot(options3.hashCode));
    });

    test('is not equal to another type', () {
      // Called directly: `equals(x)` matches by asking *x* whether it equals
      // the value, so `isNot(equals(Object()))` only ever exercises
      // `Object.==` and no change to this class can fail it.
      const options = CarouselOptions();

      expect(options == Object(), isFalse);
    });

    test('every field is part of the equality', () {
      const base = CarouselOptions();

      expect(_variants, hasLength(22));
      for (final variant in _variants) {
        expect(variant, isNot(equals(base)));
      }
    });

    test('default values are correct', () {
      const options = CarouselOptions();
      expect(options.aspectRatio, 16 / 9);
      expect(options.viewportFraction, 0.8);
      expect(options.initialPage, 0);
      expect(options.enableInfiniteScroll, true);
      expect(options.reverse, false);
      expect(options.autoPlay, false);
      expect(options.enlargeCenterPage, false);
      expect(options.scrollDirection, Axis.horizontal);
      expect(options.dragDevices, CarouselOptions.defaultDragDevices);
      // The three the README states in prose, which nothing else pins.
      expect(options.autoPlayInterval, const Duration(seconds: 4));
      expect(
        options.autoPlayAnimationDuration,
        const Duration(milliseconds: 800),
      );
      expect(options.enlargeFactor, 0.3);
      expect(options.autoPlayCurve, Curves.fastOutSlowIn);
      expect(options.enlargeStrategy, CenterPageEnlargeStrategy.scale);
      expect(options.animateToClosest, true);
      expect(options.pageSnapping, true);
      expect(options.padEnds, true);
      expect(options.disableCenter, false);
      expect(options.clipBehavior, Clip.hardEdge);
      expect(options.height, isNull);
      expect(options.scrollPhysics, isNull);
      expect(options.pageViewKey, isNull);
    });

    test('dragDevices is compared by its contents', () {
      const options1 = CarouselOptions(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      );
      final options2 = CarouselOptions(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
      );
      const options3 = CarouselOptions(dragDevices: {PointerDeviceKind.touch});

      expect(options1, equals(options2));
      expect(options1.hashCode, options2.hashCode);
      expect(options1, isNot(equals(options3)));
      expect(options1.hashCode, isNot(options3.hashCode));
    });
  });
}
