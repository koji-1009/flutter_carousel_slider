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
  double position,
);

/// A carousel slider widget.
class CarouselSlider extends StatefulWidget {
  /// Create [CarouselSlider] widget.
  /// The [items] contains the list of widgets that will be shown in the carousel.
  const CarouselSlider({
    super.key,
    required this.items,
    this.options = const CarouselOptions(),
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
    this.options = const CarouselOptions(),
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

  /// A [CarouselControllerX], used to control the carousel.
  final CarouselControllerX? carouselController;

  /// Called whenever the page in the center of the viewport changes.
  final CarouselPageChangedCallback? onPageChanged;

  /// Called whenever the carousel is scrolled.
  final CarouselOnScrolledCallback? onScrolled;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  /// Default initial offset for PageView in virtual infinite scroll.
  static const _virtualOffset = 10000;

  /// [CarouselOptions] to determine the behavior of the carousel.
  CarouselOptions get _options => widget.options;

  /// Initial offset for PageView.
  int get _initialOffset => _options.enableInfiniteScroll ? _virtualOffset : 0;

  /// Initial position for PageView.
  int get _initialPosition => _options.initialPage + _initialOffset;

  /// Current page of the carousel.
  late int _currentPageViewPage;

  /// [Timer] to handle auto play
  Timer? _timer;

  /// [CarouselPageChangedReason] to determine the reason for page change
  CarouselPageChangedReason _mode = CarouselPageChangedReason.controller;

  /// [CarouselControllerX] to control the carousel
  late CarouselControllerX _carouselController;

  /// [PageController] to control the [PageView]
  late PageController _pageController;

  @override
  void didUpdateWidget(covariant CarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carouselController != widget.carouselController) {
      _carouselController.dispose();
      _setupCarouselControllerX();
    }

    if (oldWidget.options != widget.options) {
      final isUpdateEnableInfiniteScroll =
          oldWidget.options.enableInfiniteScroll !=
              widget.options.enableInfiniteScroll;
      final isUpdateInitialPage =
          oldWidget.options.initialPage != widget.options.initialPage;
      final initialPage = (isUpdateEnableInfiniteScroll || isUpdateInitialPage)
          ? _initialPosition
          : _currentPageViewPage;
      _pageController.dispose();
      _setupPageController(initialPage);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // The position is determined at the time of drawing,
        // so consider the case where there is no position
        if (_pageController.hasClients) {
          // Jump to the initial page after the first build
          _pageController.jumpToPage(initialPage);
        }
      });
    }

    _handleAutoPlay();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // After the first build method, request a redraw
      if (!mounted) return;
      setState(() {});
    });

    _setupCarouselControllerX();
    _setupPageController(_initialPosition);
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
      builder: (context, constraints) {
        final itemHeight = _options.height ??
            constraints.maxWidth * (1.0 / _options.aspectRatio);
        final itemWidth = constraints.maxWidth;

        return _GestureHandler(
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
              _currentPageViewPage = index;

              final currentPage = getIndexInLength(
                position: index + _options.initialPage,
                base: _initialPosition,
                length: widget.itemCount,
              );

              widget.onPageChanged?.call(currentPage, _mode);
            },
            itemBuilder: (context, realIndex) {
              final index = getIndexInLength(
                position: realIndex,
                base: _initialOffset,
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
                    // `_pageController.page` can only be accessed after the first build,
                    // so in the first build we calculate the item offset manually
                    final position = _pageController.position;
                    if (position.hasPixels && position.hasContentDimensions) {
                      // This case is after the first build
                      // So, we can access the `_currentPageViewPage`
                      itemOffset =
                          (_currentPageViewPage - realIndex).toDouble();
                    } else {
                      // This case is before the first build
                      final storageContext = position.context.storageContext;
                      final previousSavedPosition =
                          PageStorage.of(storageContext)
                              .readState(storageContext) as double?;
                      if (previousSavedPosition != null) {
                        // Restore the previous position
                        _currentPageViewPage = previousSavedPosition.toInt();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Notify page is restored
                          widget.onPageChanged?.call(
                            getIndexInLength(
                              position: previousSavedPosition.toInt(),
                              base: _initialOffset,
                              length: widget.itemCount,
                            ),
                            CarouselPageChangedReason.restore,
                          );
                        });

                        itemOffset = previousSavedPosition - realIndex;
                      } else {
                        // `_currentPageViewPage` is not set yet
                        // So, we calculate the item offset manually
                        itemOffset = (realIndex - _initialOffset).toDouble();
                      }
                    }

                    final enlargeFactor =
                        _options.enlargeFactor.clamp(0.0, 1.0);
                    final distortionRatio =
                        (1.0 - (itemOffset.abs() * enlargeFactor))
                            .clamp(0.0, 1.0);
                    scale = Curves.easeOut.transform(distortionRatio);
                  }

                  final (enlargeHeight, enlargeWidth) =
                      switch (_options.scrollDirection) {
                    Axis.horizontal => (
                        itemHeight * scale,
                        double.infinity,
                      ),
                    Axis.vertical => (
                        double.infinity,
                        itemWidth * scale,
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
        );
      },
    );
  }

  void _setupCarouselControllerX() {
    _carouselController = widget.carouselController ?? CarouselControllerX();
  }

  void _setupPageController(int initialPage) {
    _currentPageViewPage = initialPage;
    _pageController = PageController(
      viewportFraction: _options.viewportFraction,
      initialPage: initialPage,
    );
    _pageController.addListener(() {
      final newPage = _pageController.page;
      if (newPage != null) {
        widget.onScrolled?.call(newPage);
      }
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
        final index = getIndexInLength(
          position: _currentPageViewPage,
          base: _initialOffset,
          length: widget.itemCount,
        );

        _mode = CarouselPageChangedReason.controller;
        final pageToJump = _currentPageViewPage + page - index;
        _pageController.jumpToPage(pageToJump);
      },
      onAnimateToPage: (page, duration, curve) async {
        if (isNeedResetTimer) {
          _clearTimer();
        }
        final index = getIndexInLength(
          position: _currentPageViewPage,
          base: _initialOffset,
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
          _currentPageViewPage + smallestMovement,
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

      var nextPage = _currentPageViewPage + 1;
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

  final double height;
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
  final double width;
  final double height;
}
