# carousel_slider_x

[![pub package](https://img.shields.io/pub/v/carousel_slider_x.svg)](https://pub.dev/packages/carousel_slider_x)
[![GitHub license](https://img.shields.io/github/license/koji-1009/flutter_carousel_slider)](https://github.com/koji-1009/flutter_carousel_slider/blob/main/LICENSE)
[![CI](https://github.com/koji-1009/flutter_carousel_slider/actions/workflows/analyze.yml/badge.svg)](https://github.com/koji-1009/flutter_carousel_slider/actions/workflows/analyze.yml)
[![codecov](https://codecov.io/gh/koji-1009/flutter_carousel_slider/branch/main/graph/badge.svg)](https://codecov.io/gh/koji-1009/flutter_carousel_slider)

This package is a fork of the original [carousel_slider](https://pub.dev/packages/carousel_slider) package.

A carousel slider widget, support infinite scroll and auto play, enlarge mode.

## Features 

* Infinite scroll 
* Auto play
* Enlarge center page

## Live preview

https://koji-1009.github.io/flutter_carousel_slider/

## Installation

Add `carousel_slider_x: ^7.0.0` to your `pubspec.yaml` dependencies.
And import it:

```dart
import 'package:carousel_slider_x/carousel_slider_x.dart';
```

### Migration from `carousel_slider`

If you are migrating from the original `carousel_slider` package, you should move the following property from `CarouselOptions` to `CarouselSlider`.

* `onPageChanged`
* `onScrolled`

### Migration to 7.0.0

Auto play now has one rule, so the options that used to arbitrate it are gone: **`autoPlayInterval` is the period between slides, and auto play never competes with a movement already under way.** A tick that lands while the carousel is touched or moving — a drag, a fling, a press, a trackpad pan, a wheel notch, a `CarouselControllerX` call — declines and waits again. Letting go of a press, any controller call, and a rebuild that changes `autoPlay` or `autoPlayInterval` restart the wait.

These are removed, with no replacement needed:

* `pauseAutoPlayOnTouch` — a drag always holds auto play now.
* `pauseAutoPlayOnManualNavigate` — a controller move always resets the interval now.
* `CarouselControllerX.startAutoPlay` / `stopAutoPlay` — set `autoPlay` on `CarouselOptions` and rebuild. That was already the declarative switch; having both meant two sources of truth for one question.

`pauseAutoPlayInFiniteScroll` is removed too. A finite carousel now always wraps to the first item. To stop at the last one, watch `onPageChanged` and rebuild with `autoPlay: false`.

`CarouselPageChangedReason` is removed and `onPageChanged` is now `void Function(int index)`. The reason could not be answered honestly: a page change can be an auto play animation that the user grabbed and flung, and no single value describes that. Your app already knows when it called the controller, which is the only case the enum reported reliably.

```dart
// before
onPageChanged: (index, reason) { ... }
// after
onPageChanged: (index) { ... }
```

`CarouselOptions.disableGesture` is removed. **It never did what its name said** — it left the `PageView` untouched, so swiping kept working; all it did was skip the auto play pause. To actually block dragging, use `scrollPhysics: const NeverScrollableScrollPhysics()`.

The carousel now accepts drag gestures from every `PointerDeviceKind`, where only touch and mouse were accepted before. A stylus and a trackpad can drag it as well. Use the new `dragDevices` option to narrow this down.

```dart
CarouselOptions(
  // Accept touch only.
  dragDevices: {PointerDeviceKind.touch},
)
```

`PointerDeviceKind` comes from `package:flutter/gestures.dart`.

A carousel with a single item no longer scrolls at all, and `scrollPhysics` is ignored at that size — there is nowhere to go, and a page view that lets the reader drag anyway reports a page change for every slot it passes over.

`CenterPageEnlargeStrategy.height` now shrinks the side items across the scroll axis on both axes — their height on a horizontal carousel and their width on a vertical one, where it previously changed nothing. It cannot shrink them along the scroll axis: the page view pins that extent to `viewport * viewportFraction` whatever the box asks for.

### Drag devices

A carousel is paged by a swipe, and no device kind should be left out of it: touch and both stylus kinds are direct manipulation, a trackpad swipes with two fingers, a mouse is the only pointer affordance left on the web and on desktop, and assistive tooling such as VoiceAccess reports `PointerDeviceKind.unknown`. So `CarouselOptions.defaultDragDevices` holds every kind.

This is wider than `ScrollBehavior.dragDevices`, which leaves out `PointerDeviceKind.mouse` to keep text selection usable inside a scrollable. That is not a concern for a carousel, and its scrollbar is hidden anyway.

Setting `dragDevices` replaces the whole set, so it takes precedence over an enclosing `ScrollConfiguration`.

`dragDevices` governs **dragging only**. A mouse wheel is routed past it by `Scrollable`, so a carousel still answers the wheel even with an empty set, and `CarouselControllerX` and auto play are unaffected. So an empty set means "nothing can drag this", not "nothing can move this". The only setting that refuses every kind of user input is `scrollPhysics: NeverScrollableScrollPhysics()`.

### Auto play

`autoPlayInterval` is the period between slides, measured from one slide to the next. Auto play never competes with a movement already under way: a tick that lands while the carousel is moving or held declines and waits another interval. So an interval shorter than `autoPlayAnimationDuration` is well defined rather than a race — the period simply grows to the next whole multiple that clears the animation.

A finger resting on the carousel holds it too, whether or not it ever becomes a drag, so a card is never pulled out from under a press. Three things restart the wait rather than merely postponing a tick: letting go of a press, any `CarouselControllerX` call, and a rebuild that changes `autoPlay` or `autoPlayInterval`. A mouse wheel notch does not — it only holds off the ticks that land while it is still settling, so the slide it would have displaced is skipped rather than delayed.

There is nothing to configure about this and nothing to turn on. `autoPlay` is the only switch.

## How to use

Simply create a `CarouselSlider` widget, and pass the required params:

```dart
CarouselSlider(
  options: const CarouselOptions(
    height: 400,
  ),
  items: [1,2,3,4,5].map((i) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: EdgeInsets.symmetric(
        horizontal: 8.0
      ),
      decoration: BoxDecoration(
        color: Colors.amber
      ),
      child: Text(
        'text $i', 
        style: TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }).toList(),
)
```

## Params

```dart
CarouselSlider(
   items: items,
   options: const CarouselOptions(
      height: 400,
      aspectRatio: 16/9,
      viewportFraction: 0.8,
      initialPage: 0,
      enableInfiniteScroll: true,
      reverse: false,
      autoPlay: true,
      autoPlayInterval: Duration(seconds: 3),
      autoPlayAnimationDuration: Duration(milliseconds: 800),
      autoPlayCurve: Curves.fastOutSlowIn,
      enlargeCenterPage: true,
      enlargeFactor: 0.3,
      scrollDirection: Axis.horizontal,
      dragDevices: {PointerDeviceKind.touch},
   )
 )
```

For each option's usage you can refer to [carousel_options.dart](lib/src/carousel_options.dart). `PointerDeviceKind` needs `import 'package:flutter/gestures.dart';`.

**If you pass the `height` parameter, the `aspectRatio` parameter will be ignored.**

## Build item widgets on demand

This method will save memory by building items once it becomes necessary.
This way they won't be built if they're not currently meant to be visible on screen.
It can be used to build different child item widgets related to content or by item index.

```dart
CarouselSlider.builder(
  itemCount: 15,
  itemBuilder: (BuildContext context, int itemIndex, int realIndex) =>
    Center(
      child: Text(itemIndex.toString()),
    ),
)
```

## Carousel controller

In order to manually control the PageView's position, you can create your own `CarouselControllerX`, and pass it to `CarouselSlider`.
Then you can use the `CarouselControllerX` instance to manipulate the position.

```dart
class _CarouselDemoState extends State<CarouselDemo> {
  final buttonCarouselController = CarouselControllerX();

  @override
  void dispose() {
    buttonCarouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      CarouselSlider(
        items: const [Text('1'), Text('2'), Text('3')],
        carouselController: buttonCarouselController,
        options: const CarouselOptions(
          autoPlay: false,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          aspectRatio: 2.0,
          initialPage: 2,
        ),
      ),
      ElevatedButton(
        onPressed: () => buttonCarouselController.nextPage(),
        child: const Text('→'),
      ),
    ],
  );
}
```

### `CarouselControllerX` methods

#### `.nextPage({Duration duration, Curve curve})`

Animate to the next page

#### `.previousPage({Duration duration, Curve curve})`

Animate to the previous page

#### `.jumpToPage(int page)`

Jump to the given page.

#### `.animateToPage(int page, {Duration duration, Curve curve})`

Animate to the given page.

## Screenshot

Basic text carousel demo:

![simple](screenshot/basic.gif)

Basic image carousel demo:

![image](screenshot/image.gif)

A more complicated image carousel slider demo:

![complicated image](screenshot/complicated-image.gif)

Fullscreen image carousel slider demo:

![fullscreen](screenshot/fullscreen.gif)

Image carousel slider with custom indicator demo:

![indicator](screenshot/indicator.gif)

Custom `CarouselControllerX` and manually control the PageView position demo:

![manual](screenshot/manually.gif)

Vertical carousel slider demo:

![vertical](screenshot/vertical.gif)

Simple on-demand image carousel slider, with image auto prefetch demo:

![prefetch](screenshot/preload.gif)

No infinite scroll demo:

![no loop](screenshot/noloop.gif)

All screenshots above can be found at the example project.
