/// Converts an index of a set size to the corresponding index of a collection of another size
/// as if they were circular.
///
/// Takes a [position] from collection Foo, a [base] from where Foo's index originated
/// and the [length] of a second collection Baa, for which the correlating index is sought.
///
/// For example; We have a Carousel of 10000(simulating infinity) but only 6 images.
/// We need to repeat the images to give the illusion of a never ending stream.
/// By calling _getRealIndex with position and base we get an offset.
/// This offset modulo our length, 6, will return a number between 0 and 5, which represent the image
/// to be placed in the given position.
int getRealIndex({
  required int position,
  required int base,
  required int? length,
}) {
  final offset = position - base;
  return remainder(
    input: offset,
    source: length,
  );
}

/// Returns the remainder of the modulo operation [input] % [source], and adjust it for
/// negative values.
int remainder({
  required int input,
  required int? source,
}) {
  if (source == null || source == 0) return 0;
  final result = input % source;
  return result < 0 ? source + result : result;
}
