import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    });

    test('hashCode is consistent with equality', () {
      const options1 = CarouselOptions(height: 200, enableInfiniteScroll: true);
      const options2 = CarouselOptions(height: 200, enableInfiniteScroll: true);
      const options3 = CarouselOptions(
        height: 300,
        enableInfiniteScroll: false,
      );

      expect(options1.hashCode, options2.hashCode);
      expect(options1.hashCode, isNot(options3.hashCode));
    });

    test('every field is part of the equality', () {
      const base = CarouselOptions();
      final variants = <CarouselOptions>[
        const CarouselOptions(height: 200),
        const CarouselOptions(aspectRatio: 4 / 3),
        const CarouselOptions(viewportFraction: 0.5),
        const CarouselOptions(initialPage: 1),
        const CarouselOptions(enableInfiniteScroll: false),
        const CarouselOptions(animateToClosest: false),
        const CarouselOptions(reverse: true),
        const CarouselOptions(autoPlay: true),
        const CarouselOptions(autoPlayInterval: Duration(seconds: 1)),
        const CarouselOptions(autoPlayAnimationDuration: Duration(seconds: 1)),
        const CarouselOptions(autoPlayCurve: Curves.linear),
        const CarouselOptions(enlargeCenterPage: true),
        const CarouselOptions(scrollPhysics: BouncingScrollPhysics()),
        const CarouselOptions(pageSnapping: false),
        const CarouselOptions(scrollDirection: Axis.vertical),
        const CarouselOptions(pauseAutoPlayOnTouch: false),
        const CarouselOptions(pauseAutoPlayOnManualNavigate: false),
        const CarouselOptions(pauseAutoPlayInFiniteScroll: true),
        const CarouselOptions(pageViewKey: PageStorageKey('key')),
        const CarouselOptions(enlargeStrategy: CenterPageEnlargeStrategy.zoom),
        const CarouselOptions(enlargeFactor: 0.5),
        const CarouselOptions(disableCenter: true),
        const CarouselOptions(disableGesture: true),
        const CarouselOptions(padEnds: false),
        const CarouselOptions(clipBehavior: Clip.none),
      ];

      expect(variants, hasLength(25));
      for (final variant in variants) {
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
    });
  });
}
