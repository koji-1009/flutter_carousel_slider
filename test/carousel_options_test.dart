import 'package:carousel_slider_x/carousel_slider_x.dart';
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
  CarouselOptions(pauseAutoPlayOnTouch: false),
  CarouselOptions(pauseAutoPlayOnManualNavigate: false),
  CarouselOptions(pauseAutoPlayInFiniteScroll: true),
  CarouselOptions(pageViewKey: PageStorageKey('key')),
  CarouselOptions(enlargeStrategy: CenterPageEnlargeStrategy.zoom),
  CarouselOptions(enlargeFactor: 0.5),
  CarouselOptions(disableCenter: true),
  CarouselOptions(disableGesture: true),
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
      const options = CarouselOptions();

      expect(options, isNot(equals(Object())));
    });

    test('every field is part of the equality', () {
      const base = CarouselOptions();

      expect(_variants, hasLength(25));
      for (final variant in _variants) {
        expect(variant, isNot(equals(base)));
      }
    });

    test('every field is part of the hash code', () {
      const base = CarouselOptions();

      expect(_variants, hasLength(25));
      for (final variant in _variants) {
        expect(variant.hashCode, isNot(base.hashCode));
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
    });
  });
}
