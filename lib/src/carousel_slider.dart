import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'carousel_controller.dart';
import 'carousel_options.dart';
import 'utils.dart';

/// Builds one slide of a [CarouselSlider.builder].
///
/// [index] is the item, always in `[0, itemCount)`. [realIndex] is the page
/// view's own page number, which on a carousel with
/// [CarouselOptions.enableInfiniteScroll] counts from the virtual offset the
/// carousel scrolls around — useful as a [Hero] tag, where the same item
/// appearing twice on screen would otherwise collide.
typedef ExtendedIndexedWidgetBuilder =
    Widget Function(BuildContext context, int index, int realIndex);

/// Reports the item now in the centre of the viewport, by index.
typedef CarouselPageChangedCallback = void Function(int index);

/// Reports the page view's own scroll position. See
/// [CarouselSlider.onScrolled] for what the number means.
typedef CarouselOnScrolledCallback = void Function(double position);

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
  }) : itemBuilder = null,
       _itemCount = null;

  /// Create [CarouselSlider] widget using builder.
  /// The [itemBuilder] will be used to build item on demand.
  /// The [itemCount] is the number of items in the carousel.
  const CarouselSlider.builder({
    super.key,
    required int itemCount,
    required this.itemBuilder,
    this.options = const CarouselOptions(),
    this.carouselController,
    this.onPageChanged,
    this.onScrolled,
  }) : assert(
         itemCount >= 0,
         'CarouselSlider.builder itemCount must not be negative.',
       ),
       items = const [],
       _itemCount = itemCount;

  /// The widgets to be shown in the carousel of default constructor
  final List<Widget> items;

  /// How many items [CarouselSlider.builder] was given, or `null` when the
  /// items were passed directly.
  final int? _itemCount;

  /// The number of items in the carousel.
  ///
  /// A getter rather than a field initialised from `items.length`, because
  /// Dart does not allow reading a list's length in a constant expression, and
  /// that would make the default constructor impossible to invoke as `const`.
  int get itemCount => _itemCount ?? items.length;

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

  /// Called whenever the carousel is scrolled, with the page view's own
  /// position.
  ///
  /// This is not the item index [onPageChanged] reports: it is fractional while
  /// a slide is moving, and on a carousel with
  /// [CarouselOptions.enableInfiniteScroll] it counts from a virtual offset
  /// rather than from the first item, so no arithmetic on it alone yields an
  /// item index. Use [onPageChanged] for that, and this for how far between two
  /// slides the carousel is.
  final CarouselOnScrolledCallback? onScrolled;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

/// The rules this state keeps.
///
/// **The scroll position is the only record of where the reader is.** Which
/// item that means is [_indexAt], and it is the only place the mapping is made.
/// It holds only while [_offset] and [CarouselSlider.itemCount] describe the
/// position the carousel actually has, which is why a change that renumbers the
/// slides — [CarouselOptions.initialPage], [CarouselOptions.enableInfiniteScroll],
/// or the list emptying or filling — retires the page view's element and builds
/// a position from the new values rather than adjusting the one it has.
///
/// **One reporter.** [CarouselSlider.onPageChanged] is called from [_reportPage]
/// and nowhere else, and never twice for the same item.
///
/// **Auto play never competes.** One pending [Timer], measured tick to tick. A
/// tick that lands on a carousel that is held or already moving declines and
/// waits again.
///
/// **A borrowed [CarouselControllerX] outlives this carousel.** It is never
/// disposed with it. The callbacks it is left holding decline once this state
/// is gone, and the carousel replacing this one installs its own over them.
class _CarouselSliderState extends State<CarouselSlider> {
  /// Default initial offset for PageView in virtual infinite scroll.
  static const _virtualOffset = 10000;

  /// A [Listenable] that never notifies.
  static final Listenable _never = Listenable.merge(const []);

  /// [CarouselOptions] to determine the behavior of the carousel.
  CarouselOptions get _options => widget.options;

  /// The offset the scroll position counts from.
  int get _offset => _isVirtual(widget) ? _virtualOffset : 0;

  /// Which item a page of the page view shows.
  ///
  /// The only place this mapping is made. It holds for exactly as long as
  /// [_offset] and [CarouselSlider.itemCount] describe the scroll position the
  /// carousel actually has, which is why every change that invalidates it
  /// retires the position rather than adjusting it — see [didUpdateWidget].
  int _indexAt(int page) =>
      getIndexInLength(position: page, base: _offset, length: widget.itemCount);

  /// Whether [build] hands the page view an unbounded item count.
  static bool _isVirtual(CarouselSlider widget) =>
      widget.options.enableInfiniteScroll && widget.itemCount > 0;

  /// How the carousel answers a drag.
  ///
  /// Below two items it answers nothing. Scrolling a virtualised page view of
  /// one slide reports a page change for every slot it passes over, all of them
  /// naming the slide already on screen; leaving it un-virtualised instead
  /// would move the position off the virtual offset, and the index every slide
  /// is drawn from would shift the moment the list grew.
  ScrollPhysics? get _physics => widget.itemCount <= 1
      ? const NeverScrollableScrollPhysics()
      : _options.scrollPhysics;

  /// Initial position for PageView.
  ///
  /// [CarouselOptions.initialPage] is brought into range the same way a
  /// [CarouselControllerX] call is: opening past the last item left the
  /// carousel showing nothing while the scroll position sprang back.
  int get _initialPosition => _resolvePage(_options.initialPage) + _offset;

  /// The page the carousel currently rests on, or `null` when it cannot be
  /// read yet.
  ///
  /// [PageController.page] requires exactly one attached [PageView] and throws
  /// otherwise — including in release, where the assertions are gone and
  /// `positions.single` throws instead. Two are attached for any frame in which
  /// one page view is replaced by another on the same controller. Every rebuild
  /// that replaces the page view replaces the controller with it, so this is
  /// not currently reachable; reading the page is guarded rather than resting
  /// on that.
  double? get _currentPage =>
      _pageController.positions.length == 1 ? _pageController.page : null;

  /// The pointers currently down on the carousel.
  ///
  /// A set rather than a count, so a second finger landing and lifting does not
  /// report a release while the first one is still down. Note that no test can
  /// prove the difference: whichever finger leaves last reschedules the wait
  /// and overwrites whatever an earlier one did, so an early restart is never
  /// observable. It is kept because the alternative is only correct by
  /// accident.
  final _pointers = <int>{};

  /// The pending auto play movement.
  ///
  /// Kept scheduled whenever [CarouselOptions.autoPlay] is on, rather than
  /// being cancelled while the carousel moves — a tick that lands on a moving
  /// carousel declines and schedules the next one, so nothing has to balance a
  /// cancel against a later restore.
  Timer? _timer;

  /// [CarouselControllerX] to control the carousel
  late CarouselControllerX _carouselController;

  /// [PageController] to control the [PageView]
  late PageController _pageController;

  /// How many times the page view's element has been retired.
  int _generation = 0;

  /// The last item index handed to [CarouselSlider.onPageChanged].
  ///
  /// Kept so that the reader's slide changing without the page view noticing —
  /// the list reloading shorter under them — is still reported, and so that
  /// reporting it again for a page that has not moved is not.
  late int _lastReportedPage;

  @override
  void didUpdateWidget(covariant CarouselSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carouselController != widget.carouselController) {
      // The old controller has to stop driving this carousel, or a call on it
      // would still move the carousel it was taken off.
      _carouselController.dispose();
      _setupCarouselControllerX();
    }

    if (oldWidget.options.autoPlay != widget.options.autoPlay ||
        oldWidget.options.autoPlayInterval != widget.options.autoPlayInterval) {
      // A pending timer holds the old interval, so it has to be replaced
      // rather than left to run out.
      _cancelTimer();
      _scheduleTick();
    }

    // Anything that renumbers the slides invalidates the mapping between a page
    // and the item it shows, so the position is built anew from the new values
    // rather than adjusted. An infinite carousel built before its items arrived
    // is the ordinary case: with nothing to show the page view is finite and
    // zero pages long, so the virtual offset it scrolls around is clamped away,
    // and the items arriving later do not move it back.
    final isResetPosition =
        oldWidget.options.enableInfiniteScroll !=
            widget.options.enableInfiniteScroll ||
        oldWidget.options.initialPage != widget.options.initialPage ||
        _isVirtual(oldWidget) != _isVirtual(widget) ||
        (oldWidget.itemCount == 0) != (widget.itemCount == 0);

    // [PageController.viewportFraction] is final, so a new value needs a new
    // controller — but not a new position: the reader has not moved.
    final isReplaceController =
        oldWidget.options.viewportFraction != widget.options.viewportFraction;

    // Every other option is read while building, so the current controller
    // and its scroll position can be kept as is.
    if (isResetPosition || isReplaceController) {
      // [round], not [floor]: a movement may be in flight, and truncating
      // would drag the carousel back to the page it was leaving.
      final initialPage = isResetPosition
          ? _initialPosition
          : _currentPage?.round() ?? _pageController.initialPage;

      // Retire the page view's element along with the position when the slides
      // are being renumbered. [Scrollable] re-attaches its existing position to
      // a replacement controller rather than building one from
      // [PageController.initialPage], so the old pixels would otherwise
      // survive: the carousel would draw a frame of slides indexed from an
      // offset the position has not reached. A fresh element has none of that
      // state — but it has none of the reader's either, so a change that only
      // needs a new controller keeps it.
      if (isResetPosition) {
        _generation++;
      }
      _pageController.dispose();
      _setupPageController(initialPage);

      // The position has to be set once it exists, because it may have been
      // carried over from the old controller.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }

        if (_currentPage?.round() != initialPage) {
          _pageController.jumpToPage(initialPage);
        }
        // The page it was aimed at may not be one the page view will go to —
        // laid out with the new options, it now knows how far that is.
        _clampNow();
      });
      _reportPageAfterLayout();
    }

    if (oldWidget.itemCount != widget.itemCount) {
      // A movement already running does not survive the list getting shorter:
      // the physics refuse the first step past the new end, the activity goes
      // idle where it stands, and nothing brings it back — the page view has
      // no children to draw there, so the carousel stays blank. At rest the
      // layout clamps it on the same frame and none of this arises.
      _clampAfterLayout();
      _reportPageAfterLayout();
    }
  }

  /// Reports which item the reader is on once the frame has been laid out.
  ///
  /// A list that changes length moves the reader between items without moving
  /// the page view: the index is taken modulo the item count, and a shorter
  /// finite list has its position clamped during layout. Neither reports
  /// itself, so the last index [CarouselSlider.onPageChanged] was given can end
  /// up naming an item that is no longer there.
  void _reportPageAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncReportedPage();
      }
    });
  }

  /// Brings the record of where the reader is up to date with where the
  /// carousel actually is.
  ///
  /// Says nothing when it is already up to date, which is what makes it safe
  /// to call on the first layout: the record holds the page the carousel was
  /// told to open on, so only a carousel that opened somewhere else — restored
  /// from [PageStorage], or clamped out of reach — reports anything.
  void _syncReportedPage() {
    if (widget.itemCount == 0) {
      return;
    }

    _reportPage(_indexAt(_currentPage?.round() ?? _pageController.initialPage));
  }

  /// Brings the scroll position back inside the extent it may occupy, once the
  /// frame has been laid out and its extent is known.
  void _clampAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _clampNow();
      }
    });
  }

  /// Brings the scroll position back inside the extent it may occupy.
  ///
  /// Measured in pixels, not pages. Which page the carousel can reach is not a
  /// whole number — with [CarouselOptions.padEnds] off and a viewport fraction
  /// below one the last items share a screen, so the furthest it goes is part
  /// of the way onto the last one — and deriving it by dividing extents leaves
  /// the reader a page short whenever the division lands a hair under a whole
  /// number, which it does on a good fraction of real screen widths.
  ///
  /// Nothing about it is visible in [_currentPage], which reports the page of
  /// the *clamped* pixels: a position 800 pixels past the end still answers
  /// with the last page. Only the pixels say so, and until they are brought
  /// back the page view draws nothing there.
  void _clampNow() {
    if (_pageController.positions.length != 1) {
      return;
    }

    final position = _pageController.position;
    if (!position.hasContentDimensions || !position.hasPixels) {
      return;
    }

    final within = position.pixels.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (within != position.pixels) {
      position.jumpTo(within);
    }
  }

  @override
  void initState() {
    super.initState();
    _lastReportedPage = _resolvePage(_options.initialPage);
    _setupCarouselControllerX();
    _setupPageController(_initialPosition);
    _scheduleTick();

    // The page the carousel was told to open on is not always one the page view
    // can bring to the front, and a position restored from [PageStorage] is not
    // that page at all. Neither is known until it has been laid out.
    _clampAfterLayout();
    _reportPageAfterLayout();
  }

  @override
  void dispose() {
    if (_ownsCarouselController) {
      _carouselController.dispose();
    }
    _pageController.dispose();

    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _assertOptions();

    // Inside the widget that sizes the carousel, not outside it: that widget is
    // clamped by the constraints it is given, so [CarouselOptions.height] and
    // [CarouselOptions.aspectRatio] describe what was asked for rather than
    // what the page view got. The enlarge strategies have to shrink the box
    // that exists.
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final itemHeight = constraints.maxHeight;
        final itemWidth = constraints.maxWidth;

        final pageView = PageView.builder(
          key: _options.pageViewKey,
          padEnds: _options.padEnds,
          scrollBehavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            overscroll: false,
            dragDevices: _options.dragDevices,
          ),
          clipBehavior: _options.clipBehavior,
          physics: _physics,
          scrollDirection: _options.scrollDirection,
          pageSnapping: _options.pageSnapping,
          controller: _pageController,
          reverse: _options.reverse,
          itemCount: _isVirtual(widget) ? null : widget.itemCount,
          onPageChanged: (page) => _reportPage(_indexAt(page)),
          itemBuilder: (context, realIndex) {
            final index = _indexAt(realIndex);

            final itemBuilder = widget.itemBuilder;
            final child = itemBuilder != null
                ? itemBuilder(context, index, realIndex)
                : widget.items[index];
            return ListenableBuilder(
              // Nothing to follow when the effect is off: every strategy scales
              // by one, and listening anyway rebuilds each visible slide's
              // wrapper on every frame of every drag. The wrapper itself stays,
              // so that turning the effect on does not throw away what is
              // inside the slide.
              listenable: _options.enlargeCenterPage ? _pageController : _never,
              child: child,
              builder: (context, child) {
                // Before the first layout there is no page to read. Fall
                // back on a position restored from [PageStorage] — via
                // [PageStorage.maybeOf], because a carousel does not require a
                // [Navigator] above it — and then on where it was told to
                // start.
                final double currentPageValue;
                final page = _currentPage;
                if (page != null) {
                  currentPageValue = page;
                } else {
                  final restored = PageStorage.maybeOf(
                    context,
                  )?.readState(context);
                  currentPageValue = restored is double
                      ? restored
                      : _pageController.initialPage.toDouble();
                }

                var scale = 1.0;
                // if `enlargeCenterPage` is true, we must calculate the carousel item's height
                // to display the visual effect
                final itemOffset = currentPageValue - realIndex;
                if (_options.enlargeCenterPage) {
                  final enlargeFactor = _options.enlargeFactor.clamp(0.0, 1.0);
                  final distortionRatio =
                      (1.0 - (itemOffset.abs() * enlargeFactor)).clamp(
                        0.0,
                        1.0,
                      );
                  scale = Curves.easeOut.transform(distortionRatio);
                }

                return _EnlargeItem(
                  options: _options,
                  strategyOption: switch (_options.enlargeStrategy) {
                    // Shrinks the extent across the scroll axis, and leaves the
                    // one along it to the page view. Shrinking along the scroll
                    // axis instead would do nothing: the page view gives each
                    // slide a slot of `extent * viewportFraction` there, and a
                    // box asking for more than the slot is simply pushed back
                    // to it.
                    CenterPageEnlargeStrategy.height =>
                      switch (_options.scrollDirection) {
                        Axis.horizontal => _Shrink(
                          width: double.infinity,
                          height: itemHeight * scale,
                        ),
                        Axis.vertical => _Shrink(
                          width: itemWidth * scale,
                          height: double.infinity,
                        ),
                      },
                    CenterPageEnlargeStrategy.zoom => _Zoom(
                      scale: scale,
                      itemOffset: itemOffset,
                    ),
                    CenterPageEnlargeStrategy.scale => _Scale(scale: scale),
                  },
                  child: child,
                );
              },
            );
          },
        );

        // See [didUpdateWidget]: a new key retires the page view's element
        // along with the scroll position inside it.
        return KeyedSubtree(key: ValueKey(_generation), child: pageView);
      },
    );

    // Auto play measures its own cadence from tick to tick, so nothing here
    // listens for a movement ending. What it does need is the press: a slide
    // with its own [GestureDetector] keeps the gesture arena open, so the
    // position sits held rather than scrolling and reports no movement at all.
    // A [Listener] never competes for a pointer, so it sees the press either
    // way.
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _pointers.add(event.pointer),
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerUp,
      // A trackpad reports a pan as its own event family, and that pan may be
      // driving something else — a scrollable inside a slide — so the
      // carousel's own position never moves to signal it.
      onPointerPanZoomStart: (event) => _pointers.add(event.pointer),
      onPointerPanZoomEnd: _handlePointerUp,
      child: _options.height != null
          ? SizedBox(height: _options.height, child: content)
          : AspectRatio(aspectRatio: _options.aspectRatio, child: content),
    );
  }

  /// Whether [_carouselController] was made here rather than handed in.
  ///
  /// A caller's controller outlives this carousel, so it is left as it is.
  bool _ownsCarouselController = false;

  /// Whether a [CarouselControllerX] call can be carried out.
  ///
  /// Before the first layout there is no scroll position to move, and
  /// [PageController] throws rather than waiting for one — in release as well,
  /// where `positions.single` throws in the assertion's place.
  bool get _canDrive {
    if (!mounted) {
      return false;
    }

    assert(
      _pageController.hasClients,
      'A CarouselControllerX method was called while the CarouselSlider had no '
      'scroll position to move: either before its first layout, or from within '
      'the build of a frame that replaced its PageController. Use '
      'CarouselOptions.initialPage to choose the page it opens on, and move '
      'controller calls out of build.',
    );

    // Not asserted, unlike the case above: both of these describe a page view
    // that the carousel is in the middle of inflating afresh, which is its own
    // doing rather than the caller's, so the call is declined instead.
    //
    // Two positions are attached for that whole frame, and [PageController]
    // throws instead of choosing between them. The one that is left has no
    // dimensions until the frame is laid out; [PageController] holds a move
    // made then and applies it once the position has them, which would land the
    // reader somewhere they were never told about, so it is declined here.
    return _pageController.positions.length == 1 &&
        _pageController.position.haveDimensions;
  }

  /// Tells [CarouselSlider.onPageChanged] which item the reader is on, unless
  /// it already knows.
  void _reportPage(int index) {
    // [getIndexInLength] answers 0 for an empty collection, and a caller
    // indexing its own list with that throws.
    if (widget.itemCount == 0 || _lastReportedPage == index) {
      return;
    }

    _lastReportedPage = index;
    widget.onPageChanged?.call(index);
  }

  void _setupCarouselControllerX() {
    _ownsCarouselController = widget.carouselController == null;
    _carouselController = widget.carouselController ?? CarouselControllerX();
    // The callbacks read [_pageController] and [_options] when they are
    // invoked, so they stay valid even if either of them is replaced later.
    _carouselController.setupCallbacks(
      // Each of these restarts the wait: the caller just moved the carousel,
      // so the reader gets a full interval with the page they asked for.
      // Below two items these two have nowhere to step to. They move the
      // position regardless of [_physics], which governs dragging only.
      // These step from the page the reader is looking at, which is the one
      // nearest the viewport centre — [PageController] rounds to it. Auto play
      // instead steps to the next whole slot, because it is keeping a cadence
      // rather than answering "the one after this".
      onNextPage: (duration, curve) {
        if (!_canDrive || widget.itemCount <= 1) return Future<void>.value();
        _scheduleTick();
        return _pageController.nextPage(duration: duration, curve: curve);
      },
      onPreviousPage: (duration, curve) {
        if (!_canDrive || widget.itemCount <= 1) return Future<void>.value();
        _scheduleTick();
        return _pageController.previousPage(duration: duration, curve: curve);
      },
      onJumpToPage: (page) {
        if (!_canDrive) return;
        _scheduleTick();
        final target = _resolvePage(page);
        final currentPage =
            _currentPage?.floor() ?? _pageController.initialPage;

        _pageController.jumpToPage(
          currentPage + target - _indexAt(currentPage),
        );
        // [PageController.jumpToPage] does not check that the page exists, and
        // an item the page view cannot bring to the front — the last one, with
        // [CarouselOptions.padEnds] off — leaves the position past the end.
        //
        // After the frame, not now: `maxScrollExtent` is whatever the last
        // layout produced, so a caller that grows the list and jumps to one of
        // the new items in the same breath would be pulled back to where the
        // list used to end.
        _clampAfterLayout();
      },
      onAnimateToPage: (page, duration, curve) async {
        if (!_canDrive) return;
        _scheduleTick();
        final target = _resolvePage(page);
        final currentPage =
            _currentPage?.floor() ?? _pageController.initialPage;
        final index = _indexAt(currentPage);
        var smallestMovement = target - index;
        if (_options.enableInfiniteScroll && _options.animateToClosest) {
          final distance = (target - index).abs();
          final distanceWithNext = (target + widget.itemCount - index).abs();
          final distanceWithPrev = (target - widget.itemCount - index).abs();
          if (distance > distanceWithNext) {
            smallestMovement = target + widget.itemCount - index;
          } else if (distance > distanceWithPrev) {
            smallestMovement = target - widget.itemCount - index;
          }
        }

        await _pageController.animateToPage(
          currentPage + smallestMovement,
          duration: duration,
          curve: curve,
        );
      },
    );
  }

  /// The item that a [CarouselControllerX] call naming [page] should land on.
  ///
  /// A number outside `[0, itemCount)` names no slide. On a virtualised
  /// carousel it wraps, which is the only reading that means anything there —
  /// otherwise `animateToPage` sweeps the whole way round to reach a slide that
  /// was next door. Anywhere else it is clamped: jumping past the end left the
  /// carousel showing nothing at all while the scroll position sprang back.
  int _resolvePage(int page) {
    // `<=`, not `==`: [CarouselSlider.builder]'s assert is gone in release, and
    // `clamp(0, -2)` throws an [ArgumentError] naming neither the option nor
    // this package.
    if (widget.itemCount <= 0) {
      return 0;
    }

    return _isVirtual(widget)
        ? getIndexInLength(position: page, base: 0, length: widget.itemCount)
        : page.clamp(0, widget.itemCount - 1);
  }

  void _setupPageController(int initialPage) {
    _pageController = PageController(
      viewportFraction: _options.viewportFraction,
      initialPage: initialPage,
    );
    _pageController.addListener(() {
      final newPage = _currentPage;
      if (newPage == null) {
        return;
      }

      // Replacing the controller makes [PageController.attach] apply the new
      // viewport fraction, which notifies from inside the build phase. Calling
      // out to the reader there fails any `setState` they make — an indicator
      // repainting itself is the ordinary case — so the report waits for the
      // frame to finish.
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onScrolled?.call(newPage);
          }
        });
        return;
      }

      widget.onScrolled?.call(newPage);
    });
  }

  /// Gives the reader a full [CarouselOptions.autoPlayInterval] from the
  /// moment they let go, rather than whatever was left of the wait.
  void _handlePointerUp(PointerEvent event) {
    if (_pointers.remove(event.pointer) && _pointers.isEmpty) {
      _scheduleTick();
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Schedules the next auto play movement, [CarouselOptions.autoPlayInterval]
  /// from now.
  ///
  /// One-shot rather than periodic: a period would keep its own schedule and
  /// drift out of step with the movements it has to stay clear of.
  void _scheduleTick() {
    // A pointer lifting after the carousel is gone still reaches the
    // [Listener]'s render object, and a timer armed then would never be
    // cancelled — [dispose] has already run.
    //
    // A non-positive interval would schedule the next tick for right now, and
    // that tick would schedule another, with no time passing in between. It is
    // reported from [_assertOptions]; here it simply stops auto play, so a
    // release build renders a still carousel rather than locking up.
    if (!mounted ||
        !_options.autoPlay ||
        _options.autoPlayInterval <= Duration.zero) {
      return;
    }

    _timer?.cancel();
    _timer = Timer(_options.autoPlayInterval, _handleTick);
  }

  /// Reports the option values that [CarouselOptions] cannot check itself: its
  /// constructor is `const`, and comparing [Duration]s is not a constant
  /// expression.
  ///
  /// Only while auto play is on, because nothing else reads either value: a
  /// carousel that never auto-plays has no fault to report. Turning
  /// [CarouselOptions.autoPlay] on rebuilds the carousel, so the report is not
  /// lost — it arrives when the value starts being used.
  ///
  /// Called from [build] rather than from the timer path. Asserting on the way
  /// to arming the timer would leave auto play holding a timer that has already
  /// fired, which no later change of these two values would replace.
  void _assertOptions() {
    if (!_options.autoPlay) {
      return;
    }

    assert(
      _options.autoPlayInterval > Duration.zero,
      'CarouselOptions.autoPlayInterval must be greater than zero.',
    );
    assert(
      _options.autoPlayAnimationDuration > Duration.zero,
      'CarouselOptions.autoPlayAnimationDuration must be greater than zero.',
    );
  }

  void _handleTick() {
    // Scheduled before anything else can decline or throw, so auto play always
    // has exactly one tick pending and its period stays exact.
    _scheduleTick();

    // A null page is a carousel that has not been laid out yet. One item or
    // none has nowhere to go, and moving it anyway drives a scroll activity
    // that nothing can see the result of.
    final page = _currentPage;
    if (page == null ||
        ModalRoute.of(context)?.isCurrent == false ||
        widget.itemCount <= 1) {
      return;
    }

    // Someone has a finger on the carousel, or it is already moving. Auto play
    // declines either way rather than pulling the content out from under them.
    if (_pointers.isNotEmpty ||
        _pageController.position.isScrollingNotifier.value) {
      return;
    }

    // [floor], not [round]: with [CarouselOptions.pageSnapping] off the
    // carousel can rest between pages, and rounding up would then skip one.
    final next = page.floor() + 1;
    // Wrap when the carousel cannot go any further, rather than when the next
    // index would pass the item count. With [CarouselOptions.padEnds] off and
    // a viewport fraction below 1 the last items share a screen, so the
    // furthest the page view goes is a fraction of a page short of the last
    // index — and coming to rest there is how that last item gets shown.
    final position = _pageController.position;
    // [_currentPage] is only non-null once the position has its content
    // dimensions, so the pixels can be compared directly.
    final atEnd = position.pixels >= position.maxScrollExtent;
    // Deliberately not awaited: the tick scheduled above already sets the
    // next slide, and it declines if this movement is still running.
    _pageController.animateToPage(
      atEnd && !_options.enableInfiniteScroll ? 0 : next,
      duration: _options.autoPlayAnimationDuration,
      curve: _options.autoPlayCurve,
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
    final body = options.disableCenter ? child : Center(child: child);

    return switch (strategyOption) {
      // Wrapped in an [Align]: the page view constrains every slide tightly on
      // both axes, and a bare [SizedBox] is pushed straight back out to the
      // full slot. [Align] passes loose constraints down, so the box keeps the
      // extent it was given. The other extent is asked for as infinity, which
      // those loose constraints then pin to the full slot — so the slide still
      // fills its box across the scroll axis, and [CarouselOptions.disableCenter]
      // stays the only thing that decides how the slide sits inside it.
      _Shrink(:final width, :final height) => Align(
        child: SizedBox(width: width, height: height, child: body),
      ),
      _Zoom(:final scale, :final itemOffset) => Transform.scale(
        scale: scale,
        // Shrink each side item towards the centre one, which means anchoring
        // it on the edge facing the centre. [itemOffset] is in page-index
        // space, and [CarouselOptions.reverse] flips that onto the screen, so
        // the anchor has to flip with it.
        // [AlignmentDirectional] on the horizontal axis: a right-to-left
        // [Directionality] lays the pages out the other way round, and a plain
        // [Alignment] would leave every side item anchored on the edge facing
        // away from the centre.
        alignment: switch ((
          options.scrollDirection,
          (itemOffset > 0) != options.reverse,
        )) {
          (Axis.horizontal, true) => AlignmentDirectional.centerEnd,
          (Axis.horizontal, false) => AlignmentDirectional.centerStart,
          (Axis.vertical, true) => Alignment.bottomCenter,
          (Axis.vertical, false) => Alignment.topCenter,
        },
        child: body,
      ),
      _Scale(:final scale) => Transform.scale(scale: scale, child: body),
    };
  }
}

sealed class _StrategyOption {
  const _StrategyOption();
}

class _Shrink extends _StrategyOption {
  const _Shrink({required this.width, required this.height});

  /// Infinity on the extent the page view already pins.
  final double width;
  final double height;
}

class _Zoom extends _StrategyOption {
  const _Zoom({required this.scale, required this.itemOffset});

  final double scale;

  /// Distance from the centre of the viewport, in pages. Positive when the item
  /// is before the centre. Kept fractional so that the alignment stays stable
  /// while scrolling.
  final double itemOffset;
}

class _Scale extends _StrategyOption {
  const _Scale({required this.scale});

  final double scale;
}
