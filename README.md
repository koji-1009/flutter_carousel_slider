# carousel_slider_x

This package is a fork of the original [carousel_slider](https://pub.dev/packages/carousel_slider) package.

A carousel slider widget, support infinite scroll and auto play, enlarge mode.

## Features 

* Infinite scroll 
* Auto play
* Enlarge center page

## Live preview

https://koji-1009.github.io/flutter_carousel_slider/

## Installation

Add `carousel_slider_x: ^5.0.0` to your `pubspec.yaml` dependencies.
And import it:

```dart
import 'package:carousel_slider_x/carousel_slider_x.dart';
```

### Migration

If you are migrating from the original `carousel_slider` package, you should move the following property from `CarouselOptions` to `CarouselSlider`.

* `onPageChanged`
* `onScrolled`

And, you should move the following properties from `CarouselSlider` to `CarouselOptions`.

* `disableGesture`

## How to use

Simply create a `CarouselSlider` widget, and pass the required params:

```dart
CarouselSlider(
  options: const CarouselOptions(
    height: 400,
  ),
  items: [1,2,3,4,5].map((i) {
    Container(
      width: MediaQuery.sizeOf(context).width,
      margin: EdgeInsets.symmetric(
        horizontal: 8.
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
  }.toList(),
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
      onPageChanged: callbackFunction,
      scrollDirection: Axis.horizontal,
   )
 )
```

For each option's usage you can refer to [carousel_options.dart](lib/src/carousel_options.dart).

**If you pass the `height` parameter, the `aspectRatio` parameter will be ignored.**

## Build item widgets on demand

This method will save memory by building items once it becomes necessary.
This way they won't be built if they're not currently meant to be visible on screen.
It can be used to build different child item widgets related to content or by item index.

```dart
CarouselSlider.builder(
  itemCount: 15,
  itemBuilder: (BuildContext context, int itemIndex, int realIndex) =>
    Container(
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
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      CarouselSlider(
        items: child,
        carouselController: buttonCarouselController,
        options: const CarouselOptions(
          autoPlay: false,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          aspectRatio: 2.0,
          initialPage: 2,
        ),
      ),
      RaisedButton(
        onPressed: () => buttonCarouselController.nextPage(),
        child: Text('→'),
      )
    ]
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
