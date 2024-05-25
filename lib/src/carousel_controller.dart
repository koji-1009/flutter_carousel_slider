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

  PageChangeCallback? onNextPageCallback;
  PageChangeCallback? onPreviousPageCallback;
  JumpToCallback? onJumpToPageCallback;
  AnimateToPageCallback? onAnimateToPageCallback;
  VoidCallback? onStartAutoPlayCallback;
  VoidCallback? onStopAutoPlayCallback;

  /// Disposes the controller.
  void dispose() {
    onNextPageCallback = null;
    onPreviousPageCallback = null;
    onJumpToPageCallback = null;
    onAnimateToPageCallback = null;
    onStartAutoPlayCallback = null;
    onStopAutoPlayCallback = null;
  }

  /// Sets up the callbacks for the controller.
  /// This method is called by the [CarouselSlider] widget.
  /// Please do not call this method from outside the package.
  void setupCallbacks({
    required PageChangeCallback onNextPage,
    required PageChangeCallback onPreviousPage,
    required JumpToCallback onJumpToPage,
    required AnimateToPageCallback onAnimateToPage,
    required VoidCallback onStartAutoPlay,
    required VoidCallback onStopAutoPlay,
  }) {
    onNextPageCallback = onNextPage;
    onPreviousPageCallback = onPreviousPage;
    onJumpToPageCallback = onJumpToPage;
    onAnimateToPageCallback = onAnimateToPage;
    onStartAutoPlayCallback = onStartAutoPlay;
    onStopAutoPlayCallback = onStopAutoPlay;
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
    await onNextPageCallback?.call(duration, curve);
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
    await onPreviousPageCallback?.call(duration, curve);
  }

  /// Changes which page is displayed in the controlled [CarouselSlider].
  ///
  /// Jumps the page position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  void jumpToPage(int page) {
    onJumpToPageCallback?.call(page);
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
    await onAnimateToPageCallback?.call(page, duration, curve);
  }

  /// Starts the controlled [CarouselSlider] autoplay.
  ///
  /// The carousel will only autoPlay if the [autoPlay] parameter
  /// in [CarouselOptions] is true.
  void startAutoPlay() {
    onStartAutoPlayCallback?.call();
  }

  /// Stops the controlled [CarouselSlider] from autoplaying.
  ///
  /// This is a more on-demand way of doing this. Use the [autoPlay]
  /// parameter in [CarouselOptions] to specify the autoPlay behaviour of the carousel.
  void stopAutoPlay() {
    onStopAutoPlayCallback?.call();
  }
}
