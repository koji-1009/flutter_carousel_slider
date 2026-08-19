import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// How [CarouselOptions.enlargeCenterPage] makes the centre page stand out.
enum CenterPageEnlargeStrategy {
  /// Shrinks the side items' boxes across the scroll axis — their height on a
  /// horizontal carousel and their width on a vertical one, despite the name.
  ///
  /// The extent along the scroll axis cannot be shrunk: the page view pins it
  /// to `viewport * viewportFraction` whatever the box asks for. A slide that
  /// fills its box shrinks with it; one with an intrinsic size of its own keeps
  /// that size for as long as it fits inside the shrunken box, and is squeezed
  /// into it once it does not.
  height,

  /// Scales each side item down on both axes, anchored on the edge facing the
  /// centre so that the slides stay touching.
  zoom,

  /// Scales each side item down on both axes, anchored on its middle.
  scale,
}

/// Everything about a [CarouselSlider] except what it shows.
///
/// Immutable and `const`-constructible: build a new one and rebuild the
/// carousel to change any of it.
///
/// Changing [initialPage] or [enableInfiniteScroll] puts the reader back on
/// [initialPage] — both say where the carousel starts, so both start it again.
///
/// Two are meant to be set once rather than switched at runtime: changing
/// [pageViewKey], or swapping [height] for [aspectRatio], rebuilds the page
/// view from scratch and loses the reader's place along with anything inside a
/// slide.
class CarouselOptions {
  /// Every [PointerDeviceKind], the default for [dragDevices].
  ///
  /// A carousel is paged by a swipe, and there is no kind that should be left
  /// out of it. Per kind:
  ///
  /// * [PointerDeviceKind.touch], [PointerDeviceKind.stylus] and
  ///   [PointerDeviceKind.invertedStylus] are direct manipulation.
  /// * [PointerDeviceKind.trackpad] swipes with two fingers.
  /// * [PointerDeviceKind.mouse] is the only pointer affordance left on the web
  ///   and on desktop, because a carousel hides its scrollbar and a horizontal
  ///   one does not answer a vertical wheel.
  /// * [PointerDeviceKind.unknown] is what assistive tooling such as
  ///   VoiceAccess reports.
  ///
  /// Listed out rather than derived from [PointerDeviceKind.values], because
  /// the set has to be a constant.
  static const defaultDragDevices = <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };

  /// Creates the options for a [CarouselSlider].
  const CarouselOptions({
    this.height,
    this.aspectRatio = 16 / 9,
    this.viewportFraction = 0.8,
    this.initialPage = 0,
    this.enableInfiniteScroll = true,
    this.animateToClosest = true,
    this.reverse = false,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 800),
    this.autoPlayCurve = Curves.fastOutSlowIn,
    this.enlargeCenterPage = false,
    this.scrollPhysics,
    this.pageSnapping = true,
    this.scrollDirection = Axis.horizontal,
    this.pageViewKey,
    this.enlargeStrategy = CenterPageEnlargeStrategy.scale,
    this.enlargeFactor = 0.3,
    this.disableCenter = false,
    this.dragDevices = defaultDragDevices,
    this.padEnds = true,
    this.clipBehavior = Clip.hardEdge,
  }) : assert(
         aspectRatio > 0,
         'CarouselOptions.aspectRatio must be greater than zero.',
       ),
       assert(
         height == null || height >= 0,
         'CarouselOptions.height must not be negative.',
       ),
       assert(
         viewportFraction > 0,
         'CarouselOptions.viewportFraction must be greater than zero.',
       );

  /// Set carousel height and overrides any existing [aspectRatio].
  final double? height;

  /// Aspect ratio is used if no height have been declared.
  ///
  /// Defaults to 16:9 aspect ratio.
  final double aspectRatio;

  /// The fraction of the viewport that each page should occupy.
  ///
  /// Defaults to 0.8, which means each page fills 80% of the carousel.
  final double viewportFraction;

  /// The initial page to show when first creating the [CarouselSlider].
  ///
  /// An item index. One outside `[0, itemCount)` names no slide, so it wraps on
  /// a carousel with [enableInfiniteScroll] and is clamped on any other.
  ///
  /// Defaults to 0.
  final int initialPage;

  /// Determines if carousel should loop infinitely or be limited to item length.
  ///
  /// Defaults to true, i.e. infinite loop.
  final bool enableInfiniteScroll;

  /// Determines if carousel should loop to the closest occurrence of requested page.
  ///
  /// Defaults to true.
  final bool animateToClosest;

  /// Reverse the order of items if set to true.
  ///
  /// Defaults to false.
  final bool reverse;

  /// Enables auto play, sliding one page at a time.
  ///
  /// Use [autoPlayInterval] to determent the frequency of slides.
  /// Defaults to false.
  final bool autoPlay;

  /// How often the carousel moves itself, measured from one slide to the next.
  ///
  /// Auto play never competes with a movement already under way: a tick that
  /// lands while the carousel is moving or held declines and waits another
  /// interval. So if [autoPlayAnimationDuration] is as long as this interval
  /// or longer, the period grows to the next whole multiple that clears it —
  /// 300ms with an 800ms animation slides every 900ms, not every 300ms.
  ///
  /// A finger resting on the carousel holds it too, whether or not it ever
  /// becomes a drag, so a slide is never pulled out from under a press.
  ///
  /// Three things restart the wait rather than merely postponing a tick:
  /// letting go of a press, any [CarouselControllerX] call, and a rebuild that
  /// changes [autoPlay] or [autoPlayInterval]. A mouse wheel notch does not —
  /// it only holds off the ticks that land while it is still settling.
  ///
  /// Must be greater than zero.
  ///
  /// Defaults to 4 seconds.
  final Duration autoPlayInterval;

  /// The animation duration between two transitioning pages while in auto playback.
  ///
  /// Must be greater than zero.
  ///
  /// Defaults to 800 ms.
  final Duration autoPlayAnimationDuration;

  /// Determines the animation curve physics.
  ///
  /// Defaults to [Curves.fastOutSlowIn].
  final Curve autoPlayCurve;

  /// Determines if current page should be larger than the side images,
  /// creating a feeling of depth in the carousel.
  ///
  /// Defaults to false.
  final bool enlargeCenterPage;

  /// The axis along which the page view scrolls.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis scrollDirection;

  /// How the carousel should respond to user input.
  ///
  /// For example, determines how the items continues to animate after the
  /// user stops dragging the page view.
  ///
  /// The physics are modified to snap to page boundaries using
  /// [PageScrollPhysics] prior to being used.
  ///
  /// Ignored below two items, where the carousel refuses to scroll at all.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics? scrollPhysics;

  /// Set to false to disable page snapping, useful for custom scroll behavior.
  ///
  /// Default to `true`.
  final bool pageSnapping;

  /// Pass a [PageStorageKey] if you want to keep the PageView's position when
  /// it was recreated.
  ///
  /// This restores a position when the carousel is built anew — pushed over and
  /// popped back to, say.
  final PageStorageKey<Object>? pageViewKey;

  /// How the centre page is made to stand out.
  ///
  /// [CenterPageEnlargeStrategy.height] shrinks the side items' boxes across
  /// the scroll axis — their height on a horizontal carousel, their width on a
  /// vertical one, despite the name. It cannot shrink them along the scroll
  /// axis, because the page view pins that extent to
  /// `viewport * viewportFraction` whatever the box asks for.
  ///
  /// The other two scale the slide itself, on both axes.
  final CenterPageEnlargeStrategy enlargeStrategy;

  /// How much the pages next to the center page will be scaled down.
  /// If [enlargeCenterPage] is false, this property has no effect.
  final double enlargeFactor;

  /// Whether or not to disable the `Center` widget for each slide.
  final bool disableCenter;

  /// The device kinds that can page the carousel by dragging it.
  ///
  /// Defaults to [defaultDragDevices]. This replaces the set of an enclosing
  /// [ScrollConfiguration] rather than inheriting from it, so
  /// `{PointerDeviceKind.touch}` accepts touch and nothing else.
  ///
  /// This governs dragging only. A mouse wheel is routed past
  /// [ScrollBehavior.dragDevices] by [Scrollable], and [CarouselControllerX]
  /// and auto play do not consult it, so an empty set means "nothing can drag
  /// this" rather than "nothing can move this". To refuse every kind of user
  /// input, including the wheel, use
  /// `scrollPhysics: const NeverScrollableScrollPhysics()`.
  final Set<PointerDeviceKind> dragDevices;

  /// Whether to add padding to both ends of the list.
  /// If this is set to true and [viewportFraction] < 1.0, padding will be added such that the first and last child slivers will be in the center of the viewport when scrolled all the way to the start or end, respectively.
  /// If [viewportFraction] >= 1.0, this property has no effect.
  /// This property defaults to true and must not be null.
  final bool padEnds;

  /// Exposed clipBehavior of PageView
  final Clip clipBehavior;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarouselOptions &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          aspectRatio == other.aspectRatio &&
          viewportFraction == other.viewportFraction &&
          initialPage == other.initialPage &&
          enableInfiniteScroll == other.enableInfiniteScroll &&
          animateToClosest == other.animateToClosest &&
          reverse == other.reverse &&
          autoPlay == other.autoPlay &&
          autoPlayInterval == other.autoPlayInterval &&
          autoPlayAnimationDuration == other.autoPlayAnimationDuration &&
          autoPlayCurve == other.autoPlayCurve &&
          enlargeCenterPage == other.enlargeCenterPage &&
          scrollPhysics == other.scrollPhysics &&
          pageSnapping == other.pageSnapping &&
          scrollDirection == other.scrollDirection &&
          pageViewKey == other.pageViewKey &&
          enlargeStrategy == other.enlargeStrategy &&
          enlargeFactor == other.enlargeFactor &&
          disableCenter == other.disableCenter &&
          setEquals(dragDevices, other.dragDevices) &&
          padEnds == other.padEnds &&
          clipBehavior == other.clipBehavior;

  @override
  int get hashCode => Object.hashAll([
    height,
    aspectRatio,
    viewportFraction,
    initialPage,
    enableInfiniteScroll,
    animateToClosest,
    reverse,
    autoPlay,
    autoPlayInterval,
    autoPlayAnimationDuration,
    autoPlayCurve,
    enlargeCenterPage,
    scrollPhysics,
    pageSnapping,
    scrollDirection,
    pageViewKey,
    enlargeStrategy,
    enlargeFactor,
    disableCenter,
    Object.hashAllUnordered(dragDevices),
    padEnds,
    clipBehavior,
  ]);
}
