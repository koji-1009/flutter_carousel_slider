library carousel_slider;

import 'dart:async';

import 'package:carousel_slider/carousel_state.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'carousel_controller.dart';
import 'carousel_options.dart';
import 'utils.dart';

export 'carousel_controller.dart';
export 'carousel_options.dart';

typedef ExtendedIndexedWidgetBuilder = Widget Function(
  BuildContext context,
  int index,
  int realIndex,
);

class CarouselSlider extends StatefulWidget {
  CarouselSlider({
    required this.items,
    required this.options,
    this.disableGesture,
    CarouselController? carouselController,
    this.onPageChanged,
    this.onScrolled,
    super.key,
  })  : itemBuilder = null,
        itemCount = items != null ? items.length : 0,
        _carouselController = carouselController ?? CarouselController();

  /// The on demand item builder constructor
  CarouselSlider.builder({
    required this.itemCount,
    required this.itemBuilder,
    required this.options,
    this.disableGesture,
    this.onPageChanged,
    this.onScrolled,
    CarouselController? carouselController,
    super.key,
  })  : items = null,
        _carouselController = carouselController ?? CarouselController();

  /// [CarouselOptions] to create a [CarouselState] with
  final CarouselOptions options;

  final bool? disableGesture;

  /// The widgets to be shown in the carousel of default constructor
  final List<Widget>? items;

  /// The widget item builder that will be used to build item on demand
  /// The third argument is the PageView's real index, can be used to cooperate
  /// with Hero.
  final ExtendedIndexedWidgetBuilder? itemBuilder;

  /// A [MapController], used to control the map.
  final CarouselController _carouselController;

  final int? itemCount;

  /// Called whenever the page in the center of the viewport changes.
  final void Function(int index, CarouselPageChangedReason reason)?
      onPageChanged;

  /// Called whenever the carousel is scrolled
  final void Function(double? position)? onScrolled;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider>
    with TickerProviderStateMixin {
  CarouselController get carouselController => widget._carouselController;

  CarouselOptions get options => widget.options;

  Timer? _timer;
  CarouselState? _carouselState;
  PageController? _pageController;

  /// mode is related to why the page is being changed
  CarouselPageChangedReason _mode = CarouselPageChangedReason.controller;

  void changeMode(CarouselPageChangedReason mode) {
    _mode = mode;
  }

  @override
  void didUpdateWidget(CarouselSlider oldWidget) {
    _carouselState!.options = options;
    _carouselState!.itemCount = widget.itemCount;

    // pageController needs to be re-initialized to respond to state changes
    _pageController = PageController(
      viewportFraction: options.viewportFraction,
      initialPage: _carouselState!.realPage,
    );
    _carouselState!.pageController = _pageController;

    // handle autoplay when state changes
    handleAutoPlay();

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _carouselState = CarouselState(
      options: options,
      onResetTimer: clearTimer,
      onResumeTimer: resumeTimer,
      changeMode: changeMode,
    );

    _carouselState!.itemCount = widget.itemCount;
    carouselController.state = _carouselState;
    _carouselState!.initialPage = widget.options.initialPage;
    _carouselState!.realPage = options.enableInfiniteScroll
        ? _carouselState!.realPage + _carouselState!.initialPage
        : _carouselState!.initialPage;
    handleAutoPlay();

    _pageController = PageController(
      viewportFraction: options.viewportFraction,
      initialPage: _carouselState!.realPage,
    );

    _carouselState!.pageController = _pageController;
  }

  Timer? getTimer() {
    return widget.options.autoPlay
        ? Timer.periodic(widget.options.autoPlayInterval, (_) {
            if (!mounted) {
              clearTimer();
              return;
            }

            final route = ModalRoute.of(context);
            if (route?.isCurrent == false) {
              return;
            }

            final previousReason = _mode;
            changeMode(CarouselPageChangedReason.timed);
            var nextPage = _carouselState!.pageController!.page!.round() + 1;
            final itemCount = widget.itemCount ?? widget.items!.length;

            if (nextPage >= itemCount &&
                widget.options.enableInfiniteScroll == false) {
              if (widget.options.pauseAutoPlayInFiniteScroll) {
                clearTimer();
                return;
              }
              nextPage = 0;
            }

            _carouselState!.pageController!
                .animateToPage(
                  nextPage,
                  duration: widget.options.autoPlayAnimationDuration,
                  curve: widget.options.autoPlayCurve,
                )
                .then((_) => changeMode(previousReason));
          })
        : null;
  }

  void clearTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void resumeTimer() {
    _timer ??= getTimer();
  }

  void handleAutoPlay() {
    final autoPlayEnabled = widget.options.autoPlay;

    if (autoPlayEnabled && _timer != null) return;

    clearTimer();
    if (autoPlayEnabled) {
      resumeTimer();
    }
  }

  Widget getGestureWrapper(Widget child) {
    Widget wrapper;
    if (widget.options.height != null) {
      wrapper = SizedBox(
        height: widget.options.height,
        child: child,
      );
    } else {
      wrapper = AspectRatio(
        aspectRatio: widget.options.aspectRatio,
        child: child,
      );
    }

    if (true == widget.disableGesture) {
      return NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          widget.onScrolled?.call(_carouselState!.pageController!.page);
          return false;
        },
        child: wrapper,
      );
    }

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (instance) {
            instance.onStart = (_) => onStart();
            instance.onDown = (_) => onPanDown();
            instance.onEnd = (_) => onPanUp();
            instance.onCancel = () => onPanUp();
          },
        ),
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          widget.onScrolled?.call(_carouselState!.pageController!.page);
          return false;
        },
        child: wrapper,
      ),
    );
  }

  Widget getCenterWrapper(Widget child) {
    if (widget.options.disableCenter) {
      return Container(
        child: child,
      );
    }
    return Center(
      child: child,
    );
  }

  Widget getEnlargeWrapper(
    Widget? child, {
    double? width,
    double? height,
    double? scale,
    required double itemOffset,
  }) {
    if (widget.options.enlargeStrategy == CenterPageEnlargeStrategy.height) {
      return SizedBox(
        width: width,
        height: height,
        child: child,
      );
    }
    if (widget.options.enlargeStrategy == CenterPageEnlargeStrategy.zoom) {
      final Alignment alignment;
      final horizontal = options.scrollDirection == Axis.horizontal;
      if (itemOffset > 0) {
        alignment = horizontal ? Alignment.centerRight : Alignment.bottomCenter;
      } else {
        alignment = horizontal ? Alignment.centerLeft : Alignment.topCenter;
      }
      return Transform.scale(
        scale: scale!,
        alignment: alignment,
        child: child,
      );
    }
    return Transform.scale(
      scale: scale!,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }

  void onStart() {
    changeMode(CarouselPageChangedReason.manual);
  }

  void onPanDown() {
    if (widget.options.pauseAutoPlayOnTouch) {
      clearTimer();
    }

    changeMode(CarouselPageChangedReason.manual);
  }

  void onPanUp() {
    if (widget.options.pauseAutoPlayOnTouch) {
      resumeTimer();
    }
  }

  @override
  void dispose() {
    clearTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return getGestureWrapper(
      PageView.builder(
        padEnds: widget.options.padEnds,
        scrollBehavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          overscroll: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        clipBehavior: widget.options.clipBehavior,
        physics: widget.options.scrollPhysics,
        scrollDirection: widget.options.scrollDirection,
        pageSnapping: widget.options.pageSnapping,
        controller: _carouselState!.pageController,
        reverse: widget.options.reverse,
        itemCount:
            widget.options.enableInfiniteScroll ? null : widget.itemCount,
        key: widget.options.pageViewKey,
        onPageChanged: (index) {
          final currentPage = getRealIndex(
            position: index + _carouselState!.initialPage,
            base: _carouselState!.realPage,
            length: widget.itemCount,
          );

          widget.onPageChanged?.call(currentPage, _mode);
        },
        itemBuilder: (context, idx) {
          final index = getRealIndex(
            position: idx + _carouselState!.initialPage,
            base: _carouselState!.realPage,
            length: widget.itemCount,
          );

          return AnimatedBuilder(
            animation: _carouselState!.pageController!,
            child: (widget.items != null)
                ? (widget.items!.isNotEmpty
                    ? widget.items![index]
                    : const SizedBox.shrink())
                : widget.itemBuilder!(context, index, idx),
            builder: (context, child) {
              var distortionValue = 1.0;
              // if `enlargeCenterPage` is true, we must calculate the carousel item's height
              // to display the visual effect
              var itemOffset = 0.0;
              if (widget.options.enlargeCenterPage != null &&
                  widget.options.enlargeCenterPage == true) {
                // pageController.page can only be accessed after the first build,
                // so in the first build we calculate the item offset manually
                var position = _carouselState?.pageController?.position;
                if (position != null &&
                    position.hasPixels &&
                    position.hasContentDimensions) {
                  final page = _carouselState?.pageController?.page;
                  if (page != null) {
                    itemOffset = page - idx;
                  }
                } else {
                  final storageContext = _carouselState!
                      .pageController!.position.context.storageContext;
                  final previousSavedPosition = PageStorage.of(storageContext)
                      .readState(storageContext) as double?;
                  if (previousSavedPosition != null) {
                    itemOffset = previousSavedPosition - idx.toDouble();
                  } else {
                    itemOffset =
                        _carouselState!.realPage.toDouble() - idx.toDouble();
                  }
                }

                final enlargeFactor = options.enlargeFactor.clamp(0.0, 1.0);
                final distortionRatio = (1 - (itemOffset.abs() * enlargeFactor))
                    .clamp(0.0, 1.0)
                    .toDouble();
                distortionValue = Curves.easeOut.transform(distortionRatio);
              }

              final height = widget.options.height ??
                  MediaQuery.sizeOf(context).width *
                      (1 / widget.options.aspectRatio);

              if (widget.options.scrollDirection == Axis.horizontal) {
                return getCenterWrapper(
                  getEnlargeWrapper(
                    child,
                    height: distortionValue * height,
                    scale: distortionValue,
                    itemOffset: itemOffset,
                  ),
                );
              } else {
                return getCenterWrapper(
                  getEnlargeWrapper(
                    child,
                    width: distortionValue * MediaQuery.of(context).size.width,
                    scale: distortionValue,
                    itemOffset: itemOffset,
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
