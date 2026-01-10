import 'package:carousel_slider_x/src/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getIndexInLength', () {
    test('returns correct index within range', () {
      expect(getIndexInLength(position: 0, base: 0, length: 10), 0);
      expect(getIndexInLength(position: 5, base: 0, length: 10), 5);
      expect(getIndexInLength(position: 9, base: 0, length: 10), 9);
    });

    test('returns 0 when length is 0', () {
      expect(getIndexInLength(position: 10, base: 0, length: 0), 0);
    });

    test('handles offset correctly', () {
      expect(getIndexInLength(position: 10, base: 5, length: 10), 5);
    });

    test('handles wrap around (positive)', () {
      expect(getIndexInLength(position: 10, base: 0, length: 5), 0);
      expect(getIndexInLength(position: 12, base: 0, length: 5), 2);
    });

    test('handles wrap around (negative)', () {
      expect(getIndexInLength(position: -1, base: 0, length: 5), 4);
      expect(getIndexInLength(position: -5, base: 0, length: 5), 0);
      expect(getIndexInLength(position: -6, base: 0, length: 5), 4);
    });
  });
}
