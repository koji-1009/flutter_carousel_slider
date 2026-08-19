## 7.0.0

### Breaking

* Auto play has one rule: `autoPlayInterval` is the period between slides, and a tick that lands while the carousel is held or already moving waits for the next one. `pauseAutoPlayOnTouch`, `pauseAutoPlayOnManualNavigate`, `pauseAutoPlayInFiniteScroll`, `CarouselControllerX.startAutoPlay` and `stopAutoPlay` are removed. A finite carousel always wraps; to stop at the last item, watch `onPageChanged` and rebuild with `autoPlay: false`.
* `CarouselPageChangedReason` is removed; `onPageChanged` is now `void Function(int index)`.
* `CarouselOptions.disableGesture` is removed. Use `scrollPhysics: const NeverScrollableScrollPhysics()`.
* Drags are accepted from every `PointerDeviceKind`, not just touch and mouse. Narrow the set with the new `CarouselOptions.dragDevices`.
* A drag moves the carousel from its first pixel; the removed `GestureDetector` used to discard the first ~20px.
* `jumpToPage`, `animateToPage` and `initialPage` bring an out-of-range page into range — wrapping when `enableInfiniteScroll` is on, clamping otherwise.
* A carousel with one item no longer scrolls, and `scrollPhysics` is ignored at that size.
* `CarouselControllerX.setupCallbacks` loses its `onStartAutoPlay` and `onStopAutoPlay` parameters.

### Fixed

* `CenterPageEnlargeStrategy.height` did nothing at all. It now shrinks the side items across the scroll axis.
* `CenterPageEnlargeStrategy.zoom` anchored side items away from the centre under `reverse` and under a right-to-left `Directionality`.
* An infinite carousel built before its items arrived could not scroll backwards afterwards; a finite one ignored `initialPage`.
* A `viewportFraction` change emitted `onScrolled` from inside the build phase, so a `setState` made from it threw.
* Auto play fought its own slide when `autoPlayInterval` was shorter than `autoPlayAnimationDuration`, and did not wait for a swipe. With `padEnds: false` and a `viewportFraction` below 1 it also stopped at the last item: the position cannot reach a whole `itemCount - 1` there, so the wrap never fired.
* `onPageChanged` went silent when the list changed length under the reader, leaving the last index it reported naming an item that was no longer there.
* `CarouselControllerX.nextPage` and `previousPage` moved a carousel with one item, which has nowhere to go.
* A `CarouselControllerX` you own was cleared when its carousel was disposed, leaving a replacement carousel undrivable.
* The carousel could be left with its position past the end it can reach, drawing nothing there.
* `const CarouselSlider(items: [...])` did not compile.
* `CarouselSlider` threw when built without a `PageStorage` ancestor.
* Every visible slide was built twice at mount.
* The README's carousel controller sample used the removed `RaisedButton` and an undefined variable.

### Other

* Imports `package:flutter/widgets.dart` rather than `package:flutter/material.dart`.
* `onScrolled` reports the page view's own position — fractional, and counting from a virtual offset on an infinite carousel. `onPageChanged` reports an item index.
* `dragDevices` governs dragging only: a mouse wheel is routed past it by `Scrollable`, and controller calls and auto play do not consult it.
* `pageViewKey` and the `height`/`aspectRatio` pair are meant to be set once. Changing either while the carousel is on screen rebuilds the page view and loses the reader's place.
* Asserts on `aspectRatio`, `viewportFraction`, `height`, `CarouselSlider.builder`'s `itemCount`, and both auto play durations.
* Stops following the scroll position when `enlargeCenterPage` is off.
* The semantics tree no longer advertises `scrollUp`/`scrollDown` on a horizontal carousel.

## 6.3.0

* Fix `carouselController` not working when it is replaced without changing `options`.
* Keep the `PageController` and its scroll position when the changed options do not affect it.
* Fix a new `autoPlayInterval` not being applied while auto play is running.
* Fix `CenterPageEnlargeStrategy.zoom` anchoring an item on the wrong edge while scrolling, which made it jump once the scroll settled.
* Remove the `equatable` dependency. `CarouselOptions` no longer exposes `props`.
* Use `ListenableBuilder` instead of `AnimatedBuilder`.
* Remove unreachable dead code in `getIndexInLength`.

## 6.2.0

* Flutter 3.32/Dart 3.8
* equatable ^2.1.0
* flutter_lints ^6.0.0

## 6.1.2

* Remove unreachable dead code in gesture handling and auto play timer.
* Deprecate `CarouselPageChangedReason.restore` (no longer used).
* Improve test coverage to 100%.

## 6.1.1

* Fix `animateToClosest` backward wrap bug.

## 6.1.0

* Fix initial page position issue.
* Add unit tests.

## 6.0.7

* Fix animation when `enlargeCenterPage` is `true` 

## 6.0.6

* Fix initial position when `enlargeCenterPage` is `false`

## 6.0.5

* Notify position regardless of enlargeCenterPage value

## 6.0.4

* Fixed restore process with PageStorageKey

## 6.0.3

* Fix current page issue when the device is rotated

## 6.0.2

* Fix `_currentPage` nullable issue

## 6.0.1

* Add a `mounted` check before the `setState` call

## 6.0.0

* Rename `CarouselController` to `CarouselControllerX`

## 5.0.5

* Fix assertion error when `PageController.jumpToPage` is called

## 5.0.4

* Fix layout error when the widget is hide`didUpdateWidget`

## 5.0.3

* Fix position in callback when infinite scroll is disabled

## 5.0.2

* Fix `CarouselOptions.initialPage` update issue

## 5.0.1

* Support equatability for `CarouselOptions`
* Fix `didUpdateWidget` for `CarouselSlider`

## 5.0.0

Forked and renamed the library.

* Migrate to dart 3.0
* Move following properties from `CarouselOptions` to `CarouselSlider`
    * `onPageChanged`
    * `onScrolled`
* Move the following properties from `CarouselSlider` to `CarouselOptions`
    * `disableGesture`
* Change `CarouselOptions` to immutable class
* Nullability cleanup
* Cleanup state management
* Recreate example project by Flutter 3.22

## 4.2.1

- [FIX] temporary remove `PointerDeviceKind.trackpad`
- [FIX] fix `'double?'` type

## 4.2.0

- [Add] `enlargeFactor` option
- [Add] `CenterPageEnlargeStrategy.zoom` option
- [Add] `animateToClosest` option

- [FIX] clear timer if widget was unmounted
- [FIX] scroll carousel using touchpad

## 4.1.1

- Fix code formatting

## 4.1.0

### Add

- Exposed `clipBehavior` in `CarouselOptions`
- Exposed `padEnds` in `CarouselOptions`
- Add `copyWith` method to `CarouselOptions`

### Fix

- [FIX] Can't swipe on web with Flutter 2.5

## 4.0.0

- Support null safety (Null safety isn't a breaking change and is Backward compatible meaning you can use it with
  non-null safe code too)
- Update example code to null safety and add Dark theme support and controller support to indicators in on of the
  examples and also fix overflow errors.

## 3.0.0

### Add

- Add third argument in `itemBuilder`, allow Hero and infinite scroll to coexist

### Breaking change

- `itemBuilder` needs to accept three arguments, instead of two.

## 2.3.4

### Fix

- Rollback PR ##222, due to it will break the existing project.

## 2.3.3

- Fix code formatting

## 2.3.2

### Fix

- Double pointer down and up will cause a exception
- Fix `CarouselPageChangedReason`

### Add

- Allow Hero and infinite scroll to coexist

## 2.3.1

- Fix code formatting

## 2.3.0

### Fix

- Fixed unresponsiveness to state changes

### Add

- Added start/stop autoplay functionality
- Pause auto play if not current route
- Add `pageSnapping` option for disable page snapping for the carousel

## 2.2.1

### Fix

- Fixed `carousel_options.dart` and `carousel_controller` not being exported by default.

## 2.2.0

### Add

- `disableCenter` option

This option controls whether the carousel slider item should be wrapped in a `Center` widget or not.

- `enlargeStrategy` option

This option allow user to set which enlarge strategy to enlarge the center slide. Use `CenterPageEnlargeStrategy.height`
if you want to improve the performance.

### Fix

- Fixed `CarousePageChangedReason.manual` never being emitted

## 2.1.0

### Add

- `pauseAutoPlayOnTouch` option

This option controls whether the carousel slider should pause the auto play function when user is touching the slider

- `pauseAutoPlayOnManualNavigate` option

This option controls whether the carousel slider should pause the auto play function when user is calling controller's
method.

- `pauseAutoPlayInFiniteScroll` option

This option decide the carousel should go to the first item when it reach the last item or not.

- `pageViewKey` option

This option is useful when you want to keep the pageview's position when it was recreated.

### Fix

- Fix `CarouselPageChangedReason` bug

### Other updates

- Use `Transform.scale` instead of `SizedBox` to wrap the slider item

## 2.0.0

### Breaking change

Instead of passing all the options to the `CarouselSlider`, now you'll need to pass these option to `CarouselOptions`:

```dart
CarouselSlider(
  CarouselOptions(height: 400.0),
  items: [1,2,3,4,5].map((i) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          decoration: BoxDecoration(
            color: Colors.amber
          ),
          child: Text('text $i', style: TextStyle(fontSize: 16.0),)
        );
      },
    );
  }).toList(),
)
```

### Add

- `CarouselController`

Since `v2.0.0`, `carousel_slider` plugin provides a way to pass your own `CaourselController`, and you can
use `CaouselController` instance to manually control the carousel's position. For a more detailed example please refer
to [example project](example/lib/main.dart).

- `CarouselPageChangedReason`

Now you can receive a `CarouselPageChangedReason` in `onPageChanged` callback.

### Remove

- `pauseAutoPlayOnTouch`

`pauseAutoPlayOnTouch` option is removed, because it doesn't fix the problem we have. Currently, when we enable the `autoPlay` feature, we can not stop sliding when the user interact with the carousel. This is [a flutter's issue](https://github.com/flutter/flutter/issues/54875).

## 1.4.1

### Fix

- Fix `animateTo()/jumpTo()` with non-zero initialPage

## 1.4.0

### Add

- Add on-demand item feature

### Fix

- Fix `setState() called after dispose()` bug

## 1.3.1

### Add

- Scroll physics option

### Fix

- onPage indexing bug

## 1.3.0

### Deprecation

- Remove the deprecated param: `interval`, `autoPlayDuration`, `distortion`, `updateCallback`. Please use the new param.

### Fix

- Fix `enlargeCenterPage` option is not working in `vertical` carousel slider.

## 1.2.0

### Add

- Vertical scroll support
- Enable/disable infinite scroll

## 1.1.0

### Add

- Added `pauseAutoPlayOnTouch` option
- Add documentation

## 1.0.1

### Add

- Update doc

## 1.0.0

### Add

- Added `distortion` option

## 0.0.6

### Fix

- Fix hard coded number

## 0.0.5

### Fix

- Fix `initialPage` bug, fix crash when widget is disposed.

## v0.0.2

Remove useless dependencies, add changelog.

## v0.0.1

Initial version.
