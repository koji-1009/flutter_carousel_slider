import 'package:flutter/widgets.dart';

/// How [CarouselControllerX] asks its carousel to step one page.
///
/// Part of [CarouselControllerX.setupCallbacks], which only [CarouselSlider]
/// is meant to call.
typedef PageChangeCallback =
    Future<void> Function(Duration duration, Curve curve);

/// How [CarouselControllerX] asks its carousel to jump to an item.
///
/// Part of [CarouselControllerX.setupCallbacks], which only [CarouselSlider]
/// is meant to call.
typedef JumpToCallback = void Function(int page);

/// How [CarouselControllerX] asks its carousel to animate to an item.
///
/// Part of [CarouselControllerX.setupCallbacks], which only [CarouselSlider]
/// is meant to call.
typedef AnimateToPageCallback =
    Future<void> Function(int page, Duration duration, Curve curve);

/// Controller to operate the [CarouselSlider]. It interacts with the widget through callbacks.
///
/// One controller drives one carousel: handing the same instance to two
/// carousels leaves the later-built one in charge. Give each carousel its own.
class CarouselControllerX {
  /// Creates a new [CarouselControllerX].
  CarouselControllerX();

  PageChangeCallback? _onNextPageCallback;
  PageChangeCallback? _onPreviousPageCallback;
  JumpToCallback? _onJumpToPageCallback;
  AnimateToPageCallback? _onAnimateToPageCallback;

  /// Disposes the controller.
  void dispose() {
    _onNextPageCallback = null;
    _onPreviousPageCallback = null;
    _onJumpToPageCallback = null;
    _onAnimateToPageCallback = null;
  }

  /// Sets up the callbacks for the controller.
  /// This method is called by the [CarouselSlider] widget.
  /// Please do not call this method from outside the package.
  void setupCallbacks({
    required PageChangeCallback onNextPage,
    required PageChangeCallback onPreviousPage,
    required JumpToCallback onJumpToPage,
    required AnimateToPageCallback onAnimateToPage,
  }) {
    _onNextPageCallback = onNextPage;
    _onPreviousPageCallback = onPreviousPage;
    _onJumpToPageCallback = onJumpToPage;
    _onAnimateToPageCallback = onAnimateToPage;
  }

  /// Animates the controlled [CarouselSlider] to the next page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> nextPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    await _onNextPageCallback?.call(duration, curve);
  }

  /// Animates the controlled [CarouselSlider] to the previous page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  Future<void> previousPage({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    await _onPreviousPageCallback?.call(duration, curve);
  }

  /// Changes which page is displayed in the controlled [CarouselSlider].
  ///
  /// Jumps the page position from its current value to the given value, without
  /// animation.
  ///
  /// [page] is an item index. One outside `[0, itemCount)` names no slide, so
  /// it wraps on a carousel with `enableInfiniteScroll` and is clamped on any
  /// other rather than leaving the carousel showing nothing.
  ///
  /// It is resolved against the list the carousel currently has. Calling this
  /// in the same breath as the `setState` that lengthens that list asks for an
  /// item the carousel has not been given yet, and lands on the last one it
  /// has; make the call from the frame after instead.
  void jumpToPage(int page) {
    _onJumpToPageCallback?.call(page);
  }

  /// Animates the controlled [CarouselSlider] from the current page to the given page.
  ///
  /// The animation lasts for the given duration and follows the given curve.
  /// The returned [Future] resolves when the animation completes.
  ///
  /// [page] is an item index, brought into range the same way
  /// [jumpToPage] brings it.
  Future<void> animateToPage(
    int page, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.linear,
  }) async {
    await _onAnimateToPageCallback?.call(page, duration, curve);
  }
}
