import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarouselOptions', () {
    test('supports value equality', () {
      const options1 = CarouselOptions(
        height: 200,
        enableInfiniteScroll: true,
      );
      const options2 = CarouselOptions(
        height: 200,
        enableInfiniteScroll: true,
      );
      const options3 = CarouselOptions(
        height: 300,
        enableInfiniteScroll: false,
      );

      expect(options1, equals(options2));
      expect(options1, isNot(equals(options3)));
    });

    test('props contains all fields', () {
      const options = CarouselOptions();
      expect(options.props.length, 25);
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
