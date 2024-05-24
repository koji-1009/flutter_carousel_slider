import 'package:flutter/material.dart';

typedef PageChangeCallback = Future<void> Function(
  Duration duration,
  Curve curve,
);
typedef JumpToCallback = void Function(
  int page,
);
typedef AnimateToPageCallback = Future<void> Function(
  int page,
  Duration duration,
  Curve curve,
);

class CarouselController {
  CarouselController();

  final List<PageChangeCallback> _onNextPageCallbacks = [];
  final List<PageChangeCallback> _onPreviousPageCallbacks = [];
  final List<JumpToCallback> _onJumpToPageCallbacks = [];
  final List<AnimateToPageCallback> _onAnimateToPageCallbacks = [];
  final List<VoidCallback> _onStartAutoPlayCallbacks = [];
  final List<VoidCallback> _onStopAutoPlayCallbacks = [];

  void dispose() {
    _onNextPageCallbacks.clear();
    _onPreviousPageCallbacks.clear();
    _onJumpToPageCallbacks.clear();
    _onAnimateToPageCallbacks.clear();
    _onStartAutoPlayCallbacks.clear();
    _onStopAutoPlayCallbacks.clear();
  }

  /// Animates the controlled [CarouselSlider] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> nextPage({
    Duration duration = const Duration(
      milliseconds: 300,
    ),
    Curve curve = Curves.linear,
  }) async {
    for (final callback in _onNextPageCallbacks) {
      await callback(duration, curve);
    }
  }

  /// Animates the controlled [CarouselSlider] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> previousPage({
    Duration duration = const Duration(
      milliseconds: 300,
    ),
    Curve curve = Curves.linear,
  }) async {
    for (final callback in _onPreviousPageCallbacks) {
      await callback(duration, curve);
    }
  }

  /// Changes which page is displayed in the controlled [CarouselSlider].
  ///
  /// Jumps the page position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToPage(int page) {
    for (final callback in _onJumpToPageCallbacks) {
      callback(page);
    }
  }

  /// Animates the controlled [CarouselSlider] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(
      milliseconds: 300,
    ),
    Curve curve = Curves.linear,
  }) async {
    for (final callback in _onAnimateToPageCallbacks) {
      await callback(page, duration, curve);
    }
  }

  /// Starts the controlled [CarouselSlider] autoplay.
  ///
  /// The carousel will only autoPlay if the [autoPlay] parameter
  /// in [CarouselOptions] is true.
  void startAutoPlay() {
    for (final callback in _onStartAutoPlayCallbacks) {
      callback();
    }
  }

  /// Stops the controlled [CarouselSlider] from autoplaying.
  ///
  /// This is a more on-demand way of doing this. Use the [autoPlay]
  /// parameter in [CarouselOptions] to specify the autoPlay behaviour of the carousel.
  void stopAutoPlay() {
    for (final callback in _onStopAutoPlayCallbacks) {
      callback();
    }
  }

  /// Set the [PageChangeCallback] to be called when the controlled [CarouselSlider] moves to the next page.
  void setOnNextPage(PageChangeCallback callback) {
    _onNextPageCallbacks.add(callback);
  }

  /// Set the [PageChangeCallback] to be called when the controlled [CarouselSlider] moves to the previous page.
  void setOnPreviousPage(PageChangeCallback callback) {
    _onPreviousPageCallbacks.add(callback);
  }

  /// Set the [JumpToCallback] to be called when the controlled [CarouselSlider] jumps to a specific page.
  void setOnJumpToPage(JumpToCallback callback) {
    _onJumpToPageCallbacks.add(callback);
  }

  /// Set the [AnimateToPageCallback] to be called when the controlled [CarouselSlider] animates to a specific page.
  void setOnAnimateToPage(AnimateToPageCallback callback) {
    _onAnimateToPageCallbacks.add(callback);
  }

  /// Set the [VoidCallback] to be called when the controlled [CarouselSlider] starts autoplay.
  void setOnStartAutoPlay(VoidCallback callback) {
    _onStartAutoPlayCallbacks.add(callback);
  }

  /// Set the [VoidCallback] to be called when the controlled [CarouselSlider] stops autoplay.
  void setOnStopAutoPlay(VoidCallback callback) {
    _onStopAutoPlayCallbacks.add(callback);
  }
}
