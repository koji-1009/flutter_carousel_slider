library carousel_slider;

import 'dart:async';

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

typedef CarouselPageChangedCallback = void Function(
  int index,
  CarouselPageChangedReason reason,
);

typedef CarouselOnScrolledCallback = void Function(
  double? position,
);

class CarouselSlider extends StatefulWidget {
  const CarouselSlider({
    super.key,
    required this.items,
    required this.options,
    this.carouselController,
    this.disableGesture = false,
    this.onPageChanged,
    this.onScrolled,
  })  : itemBuilder = null,
        itemCount = items != null ? items.length : 0;

  /// The on demand item builder constructor
  const CarouselSlider.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.options,
    this.carouselController,
    this.disableGesture = false,
    this.onPageChanged,
    this.onScrolled,
  }) : items = null;

  /// [CarouselOptions] to create a [CarouselState] with
  final CarouselOptions options;

  final bool disableGesture;

  /// The widgets to be shown in the carousel of default constructor
  final List<Widget>? items;

  /// The widget item builder that will be used to build item on demand
  /// The third argument is the PageView's real index, can be used to cooperate
  /// with Hero.
  final ExtendedIndexedWidgetBuilder? itemBuilder;

  /// A [CarouselController], used to control the carousel.
  final CarouselController? carouselController;

  /// The widgets count that should be shown at carousel.
  final int? itemCount;

  /// Called whenever the page in the center of the viewport changes.
  final CarouselPageChangedCallback? onPageChanged;

  /// Called whenever the carousel is scrolled
  final CarouselOnScrolledCallback? onScrolled;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider>
    with TickerProviderStateMixin {
  /// [Timer] to handle auto play
  Timer? _timer;

  /// [CarouselPageChangedReason] to determine the reason for page change
  CarouselPageChangedReason _mode = CarouselPageChangedReason.controller;

  /// [CarouselController] to control the carousel
  late CarouselController _carouselController;

  /// [PageController] to control the [PageView]
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _carouselController = widget.carouselController ?? CarouselController();
    _pageController = PageController(
      viewportFraction: widget.options.viewportFraction,
      initialPage: widget.options.initialPage +
          (widget.options.enableInfiniteScroll ? widget.options.realPage : 0),
    );

    final isNeedResetTimer = widget.options.pauseAutoPlayOnManualNavigate;
    _carouselController.setupCallbacks(
      onNextPage: (duration, curve) async {
        if (isNeedResetTimer) {
          _clearTimer();
        }

        _mode = CarouselPageChangedReason.controller;
        await _pageController.nextPage(
          duration: duration,
          curve: curve,
        );

        if (isNeedResetTimer) {
          _resumeTimer();
        }
      },
      onPreviousPage: (duration, curve) async {
        if (isNeedResetTimer) {
          _clearTimer();
        }

        _mode = CarouselPageChangedReason.controller;
        await _pageController.previousPage(
          duration: duration,
          curve: curve,
        );

        if (isNeedResetTimer) {
          _resumeTimer();
        }
      },
      onJumpToPage: (page) {
        final index = getRealIndex(
          position: _pageController.page!.toInt(),
          base: widget.options.realPage - widget.options.initialPage,
          length: widget.itemCount,
        );

        _mode = CarouselPageChangedReason.controller;
        final pageToJump = _pageController.page!.toInt() + page - index;
        _pageController.jumpToPage(pageToJump);
      },
      onAnimateToPage: (page, duration, curve) async {
        if (isNeedResetTimer) {
          _clearTimer();
        }
        final index = getRealIndex(
          position: _pageController.page!.toInt(),
          base: widget.options.realPage - widget.options.initialPage,
          length: widget.itemCount,
        );
        var smallestMovement = page - index;
        if (widget.options.enableInfiniteScroll &&
            widget.itemCount != null &&
            widget.options.animateToClosest) {
          final distance = (page - index).abs();
          final distanceWithNext = (page + widget.itemCount! - index).abs();
          if (distance > distanceWithNext) {
            smallestMovement = page + widget.itemCount! - index;
          } else if (distance > distanceWithNext) {
            smallestMovement = page - widget.itemCount! - index;
          }
        }

        _mode = CarouselPageChangedReason.controller;
        await _pageController.animateToPage(
          _pageController.page!.toInt() + smallestMovement,
          duration: duration,
          curve: curve,
        );

        if (isNeedResetTimer) {
          _resumeTimer();
        }
      },
      onStartAutoPlay: () {
        _resumeTimer();
      },
      onStopAutoPlay: () {
        _clearTimer();
      },
    );

    _handleAutoPlay();
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _pageController.dispose();

    _clearTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _getGestureWrapper(
      PageView.builder(
        key: widget.options.pageViewKey,
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
        controller: _pageController,
        reverse: widget.options.reverse,
        itemCount:
            widget.options.enableInfiniteScroll ? null : widget.itemCount,
        onPageChanged: (index) {
          final currentPage = getRealIndex(
            position: index + widget.options.initialPage,
            base: widget.options.realPage,
            length: widget.itemCount,
          );

          widget.onPageChanged?.call(currentPage, _mode);
        },
        itemBuilder: (context, idx) {
          final index = getRealIndex(
            position: idx + widget.options.initialPage,
            base: widget.options.realPage,
            length: widget.itemCount,
          );

          return AnimatedBuilder(
            animation: _pageController,
            child: widget.items != null
                ? widget.items!.isNotEmpty
                    ? widget.items![index]
                    : const SizedBox.shrink()
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
                var position = _pageController.position;
                if (position.hasPixels && position.hasContentDimensions) {
                  final page = _pageController.page;
                  if (page != null) {
                    itemOffset = page - idx;
                  }
                } else {
                  final storageContext =
                      _pageController.position.context.storageContext;
                  final previousSavedPosition = PageStorage.of(storageContext)
                      .readState(storageContext) as double?;
                  if (previousSavedPosition != null) {
                    itemOffset = previousSavedPosition - idx.toDouble();
                  } else {
                    itemOffset =
                        widget.options.realPage.toDouble() - idx.toDouble();
                  }
                }

                final enlargeFactor =
                    widget.options.enlargeFactor.clamp(0.0, 1.0);
                final distortionRatio = (1 - (itemOffset.abs() * enlargeFactor))
                    .clamp(0.0, 1.0)
                    .toDouble();
                distortionValue = Curves.easeOut.transform(distortionRatio);
              }

              final height = widget.options.height ??
                  MediaQuery.sizeOf(context).width *
                      (1 / widget.options.aspectRatio);

              if (widget.options.scrollDirection == Axis.horizontal) {
                return _getCenterWrapper(
                  _getEnlargeWrapper(
                    child,
                    height: distortionValue * height,
                    scale: distortionValue,
                    itemOffset: itemOffset,
                  ),
                );
              } else {
                return _getCenterWrapper(
                  _getEnlargeWrapper(
                    child,
                    width: distortionValue * MediaQuery.sizeOf(context).width,
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

  void _clearTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _resumeTimer() {
    if (!widget.options.autoPlay || _timer != null) {
      return;
    }

    _timer = Timer.periodic(widget.options.autoPlayInterval, (_) async {
      if (!mounted) {
        _clearTimer();
        return;
      }

      final route = ModalRoute.of(context);
      if (route?.isCurrent == false) {
        return;
      }

      final previousReason = _mode;
      _mode = CarouselPageChangedReason.timed;

      var nextPage = _pageController.page!.round() + 1;
      final itemCount = widget.itemCount ?? widget.items!.length;
      if (nextPage >= itemCount && !widget.options.enableInfiniteScroll) {
        if (widget.options.pauseAutoPlayInFiniteScroll) {
          _clearTimer();
          return;
        }
        nextPage = 0;
      }

      await _pageController.animateToPage(
        nextPage,
        duration: widget.options.autoPlayAnimationDuration,
        curve: widget.options.autoPlayCurve,
      );
      _mode = previousReason;
    });
  }

  void _handleAutoPlay() {
    final autoPlayEnabled = widget.options.autoPlay;
    if (autoPlayEnabled && _timer != null) {
      return;
    }

    _clearTimer();
    if (autoPlayEnabled) {
      _resumeTimer();
    }
  }

  Widget _getGestureWrapper(Widget child) {
    final Widget wrapper;
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

    if (widget.disableGesture) {
      return NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          widget.onScrolled?.call(_pageController.page);
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
          (instance) => instance
            ..onStart = (_) {
              _mode = CarouselPageChangedReason.manual;
            }
            ..onDown = (_) {
              if (widget.options.pauseAutoPlayOnTouch) {
                _clearTimer();
              }

              _mode = CarouselPageChangedReason.manual;
            }
            ..onEnd = (_) {
              if (widget.options.pauseAutoPlayOnTouch) {
                _resumeTimer();
              }
            }
            ..onCancel = () {
              if (widget.options.pauseAutoPlayOnTouch) {
                _resumeTimer();
              }
            },
        ),
      },
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          widget.onScrolled?.call(_pageController.page);
          return false;
        },
        child: wrapper,
      ),
    );
  }

  Widget _getCenterWrapper(Widget child) {
    if (widget.options.disableCenter) {
      return Container(
        child: child,
      );
    }
    return Center(
      child: child,
    );
  }

  Widget _getEnlargeWrapper(
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
      final horizontal = widget.options.scrollDirection == Axis.horizontal;
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
}
