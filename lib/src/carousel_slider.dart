import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'carousel_controller.dart';
import 'carousel_options.dart';
import 'utils.dart';

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

/// A carousel slider widget.
class CarouselSlider extends StatefulWidget {
  /// Create [CarouselSlider] widget.
  /// The [items] contains the list of widgets that will be shown in the carousel.
  const CarouselSlider({
    super.key,
    required this.items,
    required this.options,
    this.carouselController,
    this.onPageChanged,
    this.onScrolled,
  })  : itemBuilder = null,
        itemCount = items.length;

  /// Create [CarouselSlider] widget using builder.
  /// The [itemBuilder] will be used to build item on demand.
  /// The [itemCount] is the number of items in the carousel.
  const CarouselSlider.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.options,
    this.carouselController,
    this.onPageChanged,
    this.onScrolled,
  }) : items = const [];

  /// The widgets to be shown in the carousel of default constructor
  final List<Widget> items;

  /// The widgets count that should be shown at carousel.
  final int itemCount;

  /// The widget item builder that will be used to build item on demand
  /// The third argument is the [PageView]'s real index, can be used to cooperate
  /// with Hero.
  final ExtendedIndexedWidgetBuilder? itemBuilder;

  /// [CarouselOptions] to customize the carousel widget.
  final CarouselOptions options;

  /// A [CarouselController], used to control the carousel.
  final CarouselController? carouselController;

  /// Called whenever the page in the center of the viewport changes.
  final CarouselPageChangedCallback? onPageChanged;

  /// Called whenever the carousel is scrolled.
  final CarouselOnScrolledCallback? onScrolled;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  CarouselOptions get _options => widget.options;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // After the first build method, request a redraw
      setState(() {});
    });

    _carouselController = widget.carouselController ?? CarouselController();
    _pageController = PageController(
      viewportFraction: _options.viewportFraction,
      initialPage: _options.initialPage +
          (_options.enableInfiniteScroll ? _options.realPage : 0),
    );
    _pageController.addListener(() {
      widget.onScrolled?.call(_pageController.page);
    });

    final isNeedResetTimer = _options.pauseAutoPlayOnManualNavigate;
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
          base: _options.realPage - _options.initialPage,
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
          base: _options.realPage - _options.initialPage,
          length: widget.itemCount,
        );
        var smallestMovement = page - index;
        if (_options.enableInfiniteScroll && _options.animateToClosest) {
          final distance = (page - index).abs();
          final distanceWithNext = (page + widget.itemCount - index).abs();
          if (distance > distanceWithNext) {
            smallestMovement = page + widget.itemCount - index;
          } else if (distance > distanceWithNext) {
            smallestMovement = page - widget.itemCount - index;
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
    return LayoutBuilder(
      builder: (context, constraints) => _GestureHandler(
        changeManualMode: () {
          _mode = CarouselPageChangedReason.manual;
        },
        requestClearTimer: () {
          _clearTimer();
        },
        requestResumeTimer: () {
          _resumeTimer();
        },
        options: _options,
        child: PageView.builder(
          key: _options.pageViewKey,
          padEnds: _options.padEnds,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            overscroll: false,
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          clipBehavior: _options.clipBehavior,
          physics: _options.scrollPhysics,
          scrollDirection: _options.scrollDirection,
          pageSnapping: _options.pageSnapping,
          controller: _pageController,
          reverse: _options.reverse,
          itemCount: _options.enableInfiniteScroll ? null : widget.itemCount,
          onPageChanged: (index) {
            final currentPage = getRealIndex(
              position: index + _options.initialPage,
              base: _options.realPage,
              length: widget.itemCount,
            );

            widget.onPageChanged?.call(currentPage, _mode);
          },
          itemBuilder: (context, realIndex) {
            final index = getRealIndex(
              position: realIndex,
              base: _options.enableInfiniteScroll ? _options.realPage : 0,
              length: widget.itemCount,
            );

            final child = widget.itemBuilder != null
                ? widget.itemBuilder!(context, index, realIndex)
                : widget.items[index];
            return AnimatedBuilder(
              animation: _pageController,
              child: child,
              builder: (context, child) {
                var scale = 1.0;
                // if `enlargeCenterPage` is true, we must calculate the carousel item's height
                // to display the visual effect
                var itemOffset = 0.0;
                if (_options.enlargeCenterPage) {
                  // pageController.page can only be accessed after the first build,
                  // so in the first build we calculate the item offset manually
                  final position = _pageController.position;
                  if (position.hasPixels && position.hasContentDimensions) {
                    final page = _pageController.page;
                    if (page != null) {
                      itemOffset = page - realIndex;
                    }
                  } else {
                    final storageContext = position.context.storageContext;
                    final previousSavedPosition = PageStorage.of(storageContext)
                        .readState(storageContext) as double?;
                    if (previousSavedPosition != null) {
                      itemOffset = previousSavedPosition - realIndex;
                    } else {
                      itemOffset = (_options.realPage - realIndex) * 1.0;
                    }
                  }

                  final enlargeFactor = _options.enlargeFactor.clamp(0.0, 1.0);
                  final distortionRatio =
                      (1.0 - (itemOffset.abs() * enlargeFactor))
                          .clamp(0.0, 1.0)
                          .toDouble();
                  scale = Curves.easeOut.transform(distortionRatio);
                }

                final (enlargeHeight, enlargeWidth) =
                    switch (_options.scrollDirection) {
                  Axis.horizontal => (
                      (_options.height ??
                              constraints.maxWidth *
                                  (1 / _options.aspectRatio)) *
                          scale,
                      null,
                    ),
                  Axis.vertical => (
                      null,
                      constraints.maxWidth * scale,
                    ),
                };

                return _EnlargeItem(
                  options: _options,
                  strategyOption: switch (_options.enlargeStrategy) {
                    CenterPageEnlargeStrategy.height => _Height(
                        height: enlargeHeight,
                      ),
                    CenterPageEnlargeStrategy.zoom => _Zoom(
                        scale: scale,
                        itemOffset: itemOffset,
                      ),
                    CenterPageEnlargeStrategy.scale => _Scale(
                        scale: scale,
                        width: enlargeWidth,
                        height: enlargeHeight,
                      ),
                  },
                  child: child,
                );
              },
            );
          },
        ),
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
    if (!_options.autoPlay || _timer != null) {
      return;
    }

    _timer = Timer.periodic(_options.autoPlayInterval, (_) async {
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
      final itemCount = widget.itemCount;
      if (nextPage >= itemCount && !_options.enableInfiniteScroll) {
        if (_options.pauseAutoPlayInFiniteScroll) {
          _clearTimer();
          return;
        }
        nextPage = 0;
      }

      await _pageController.animateToPage(
        nextPage,
        duration: _options.autoPlayAnimationDuration,
        curve: _options.autoPlayCurve,
      );
      _mode = previousReason;
    });
  }

  void _handleAutoPlay() {
    if (!_options.autoPlay) {
      _clearTimer();
      return;
    }

    if (_timer != null) {
      // already running
      return;
    }

    _clearTimer();
    _resumeTimer();
  }
}

class _GestureHandler extends StatelessWidget {
  const _GestureHandler({
    required this.changeManualMode,
    required this.requestClearTimer,
    required this.requestResumeTimer,
    required this.options,
    required this.child,
  });

  final VoidCallback changeManualMode;
  final VoidCallback requestClearTimer;
  final VoidCallback requestResumeTimer;
  final CarouselOptions options;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (options.height != null) {
      body = SizedBox(
        height: options.height,
        child: child,
      );
    } else {
      body = AspectRatio(
        aspectRatio: options.aspectRatio,
        child: child,
      );
    }

    if (options.disableGesture) {
      return body;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        changeManualMode();
      },
      onPanDown: (_) {
        if (options.pauseAutoPlayOnTouch) {
          requestClearTimer();
        }

        changeManualMode();
      },
      onPanEnd: (_) {
        if (options.pauseAutoPlayOnTouch) {
          requestResumeTimer();
        }
      },
      onPanCancel: () {
        if (options.pauseAutoPlayOnTouch) {
          requestResumeTimer();
        }
      },
      child: body,
    );
  }
}

class _EnlargeItem extends StatelessWidget {
  const _EnlargeItem({
    required this.options,
    required this.strategyOption,
    required this.child,
  });

  final CarouselOptions options;
  final _StrategyOption strategyOption;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final body = options.disableCenter
        ? child
        : Center(
            child: child,
          );

    return switch (strategyOption) {
      _Height(:final height) => SizedBox(
          height: height,
          child: body,
        ),
      _Zoom(:final scale, :final itemOffset) => Transform.scale(
          scale: scale,
          alignment: switch (options.scrollDirection) {
            Axis.horizontal =>
              itemOffset > 0 ? Alignment.centerRight : Alignment.centerLeft,
            Axis.vertical =>
              itemOffset > 0 ? Alignment.bottomCenter : Alignment.topCenter,
          },
          child: body,
        ),
      _Scale(:final scale, :final width, :final height) => Transform.scale(
          scale: scale,
          child: SizedBox(
            width: width,
            height: height,
            child: body,
          ),
        ),
    };
  }
}

sealed class _StrategyOption {
  const _StrategyOption();
}

class _Height extends _StrategyOption {
  const _Height({
    required this.height,
  });

  final double? height;
}

class _Zoom extends _StrategyOption {
  const _Zoom({
    required this.scale,
    required this.itemOffset,
  });

  final double scale;
  final double itemOffset;
}

class _Scale extends _StrategyOption {
  const _Scale({
    required this.scale,
    required this.width,
    required this.height,
  });

  final double scale;
  final double? width;
  final double? height;
}
