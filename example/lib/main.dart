import 'package:carousel_slider_x/carousel_slider_x.dart';
import 'package:flutter/material.dart';

const imgList = [
  'https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80',
  'https://images.unsplash.com/photo-1522205408450-add114ad53fe?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=368f45b0888aeb0b7b08e3a1084d3ede&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=94a1e718d89ca60a6337a6008341ca50&auto=format&fit=crop&w=1950&q=80',
  'https://images.unsplash.com/photo-1523205771623-e0faa4d2813d?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=89719a0d55dd05e2deae4120227e6efc&auto=format&fit=crop&w=1953&q=80',
  'https://images.unsplash.com/photo-1508704019882-f9cf40e475b4?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=8c6e5e3aba713b17aa1fe71ab4f0ae5b&auto=format&fit=crop&w=1352&q=80',
  'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=a0c8d632e977f94e5d312d9893258f59&auto=format&fit=crop&w=1355&q=80',
];

void main() => runApp(const CarouselDemo());

class CarouselDemo extends StatelessWidget {
  const CarouselDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      routes: {
        '/': (ctx) => const CarouselDemoHome(),
        '/basic': (ctx) => const BasicDemo(),
        '/nocenter': (ctx) => const NoCenterDemo(),
        '/image': (ctx) => const ImageSliderDemo(),
        '/complicated': (ctx) => const ComplicatedImageDemo(),
        '/enlarge': (ctx) => const EnlargeStrategyDemo(),
        '/manual': (ctx) => const ManuallyControlledSlider(),
        '/noloop': (ctx) => const NoonLoopingDemo(),
        '/vertical': (ctx) => const VerticalSliderDemo(),
        '/fullscreen': (ctx) => const FullscreenSliderDemo(),
        '/ondemand': (ctx) => const OnDemandCarouselDemo(),
        '/indicator': (ctx) => const CarouselWithIndicatorDemo(),
        '/prefetch': (ctx) => const PrefetchImageDemo(),
        '/position': (ctx) => const KeepPageViewPositionDemo(),
        '/multiple': (ctx) => const MultipleItemDemo(),
        '/zoom': (ctx) => const EnlargeStrategyZoomDemo(),
        '/autoplay': (ctx) => const AutoPlayDemo(),
      },
    );
  }
}

class DemoItem extends StatelessWidget {
  const DemoItem(this.title, this.route, {super.key});

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pushNamed(context, route);
      },
    );
  }
}

class CarouselDemoHome extends StatelessWidget {
  const CarouselDemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carousel demo')),
      body: ListView(
        children: const <Widget>[
          DemoItem('Basic demo', '/basic'),
          DemoItem('No center mode demo', '/nocenter'),
          DemoItem('Image carousel slider', '/image'),
          DemoItem('More complicated image slider', '/complicated'),
          DemoItem('Enlarge strategy demo slider', '/enlarge'),
          DemoItem('Manually controlled slider', '/manual'),
          DemoItem('Noon-looping carousel slider', '/noloop'),
          DemoItem('Vertical carousel slider', '/vertical'),
          DemoItem('Fullscreen carousel slider', '/fullscreen'),
          DemoItem('Carousel with indicator controller demo', '/indicator'),
          DemoItem('On-demand carousel slider', '/ondemand'),
          DemoItem('Image carousel slider with prefetch demo', '/prefetch'),
          DemoItem('Keep PageView position demo', '/position'),
          DemoItem('Multiple item in one screen demo', '/multiple'),
          DemoItem('Enlarge strategy: zoom demo', '/zoom'),
          DemoItem('Auto play demo', '/autoplay'),
        ],
      ),
    );
  }
}

class BasicDemo extends StatelessWidget {
  const BasicDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const list = [1, 2, 3, 4, 5];
    return Scaffold(
      appBar: AppBar(title: const Text('Basic demo')),
      body: CarouselSlider(
        items: list
            .map(
              (item) => Container(
                color: Colors.green,
                child: Center(child: Text(item.toString())),
              ),
            )
            .toList(),
      ),
    );
  }
}

class NoCenterDemo extends StatelessWidget {
  const NoCenterDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const list = [1, 2, 3, 4, 5];
    return Scaffold(
      appBar: AppBar(title: const Text('No center demo')),
      body: CarouselSlider(
        options: const CarouselOptions(disableCenter: true),
        items: list
            .map(
              (item) =>
                  Container(color: Colors.green, child: Text(item.toString())),
            )
            .toList(),
      ),
    );
  }
}

class ImageSliderDemo extends StatelessWidget {
  const ImageSliderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image slider demo')),
      body: CarouselSlider(
        items: imgList
            .map((item) => Image.network(item, fit: BoxFit.cover))
            .toList(),
      ),
    );
  }
}

final imageSliders = imgList
    .map(
      (item) => Container(
        margin: const EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Stack(
            children: <Widget>[
              Image.network(item, fit: BoxFit.cover),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(200, 0, 0, 0),
                        Color.fromARGB(0, 0, 0, 0),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                  child: Text(
                    'No. ${imgList.indexOf(item)} image',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
    .toList();

class ComplicatedImageDemo extends StatelessWidget {
  const ComplicatedImageDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complicated image slider demo')),
      body: CarouselSlider(
        options: const CarouselOptions(
          autoPlay: true,
          aspectRatio: 2.0,
          enlargeCenterPage: true,
        ),
        items: imageSliders,
      ),
    );
  }
}

class EnlargeStrategyDemo extends StatefulWidget {
  const EnlargeStrategyDemo({super.key});

  @override
  State<EnlargeStrategyDemo> createState() => _EnlargeStrategyDemoState();
}

class _EnlargeStrategyDemoState extends State<EnlargeStrategyDemo> {
  var _strategy = CenterPageEnlargeStrategy.height;

  static String _describe(CenterPageEnlargeStrategy strategy) =>
      switch (strategy) {
        CenterPageEnlargeStrategy.height =>
          'Shrinks the side items across the scroll axis — their height on a '
              'horizontal carousel. The extent along the axis belongs to the '
              'page view and cannot be shrunk.',
        CenterPageEnlargeStrategy.zoom =>
          'Scales the side items on both axes, anchored on the edge facing '
              'the centre so that the slides stay touching.',
        CenterPageEnlargeStrategy.scale =>
          'Scales the side items on both axes, anchored on their middle.',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enlarge strategy demo')),
      body: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: 260,
              viewportFraction: 0.7,
              enlargeCenterPage: true,
              enlargeFactor: 0.4,
              enlargeStrategy: _strategy,
            ),
            items: imageSliders,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<CenterPageEnlargeStrategy>(
                  segments: const [
                    ButtonSegment(
                      value: CenterPageEnlargeStrategy.height,
                      label: Text('height'),
                    ),
                    ButtonSegment(
                      value: CenterPageEnlargeStrategy.zoom,
                      label: Text('zoom'),
                    ),
                    ButtonSegment(
                      value: CenterPageEnlargeStrategy.scale,
                      label: Text('scale'),
                    ),
                  ],
                  selected: {_strategy},
                  onSelectionChanged: (selected) =>
                      setState(() => _strategy = selected.first),
                ),
                const SizedBox(height: 12),
                Text(_describe(_strategy), textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ManuallyControlledSlider extends StatefulWidget {
  const ManuallyControlledSlider({super.key});

  @override
  State<ManuallyControlledSlider> createState() =>
      _ManuallyControlledSliderState();
}

class _ManuallyControlledSliderState extends State<ManuallyControlledSlider> {
  final _controller = CarouselControllerX();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manually controlled slider')),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            CarouselSlider(
              items: imageSliders,
              options: const CarouselOptions(
                enlargeCenterPage: true,
                height: 200,
              ),
              carouselController: _controller,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: ElevatedButton(
                    onPressed: () => _controller.previousPage(),
                    child: const Text('←'),
                  ),
                ),
                Flexible(
                  child: ElevatedButton(
                    onPressed: () => _controller.nextPage(),
                    child: const Text('→'),
                  ),
                ),
                ...Iterable<int>.generate(imgList.length).map(
                  (pageIndex) => Flexible(
                    child: ElevatedButton(
                      onPressed: () => _controller.animateToPage(pageIndex),
                      child: Text("$pageIndex"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NoonLoopingDemo extends StatelessWidget {
  const NoonLoopingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Noon-looping carousel demo')),
      body: CarouselSlider(
        options: const CarouselOptions(
          aspectRatio: 2.0,
          enlargeCenterPage: true,
          enableInfiniteScroll: false,
          initialPage: 2,
          autoPlay: true,
        ),
        items: imageSliders,
      ),
    );
  }
}

class VerticalSliderDemo extends StatelessWidget {
  const VerticalSliderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vertical sliding carousel demo')),
      body: CarouselSlider(
        options: const CarouselOptions(
          aspectRatio: 2.0,
          enlargeCenterPage: true,
          scrollDirection: Axis.vertical,
          autoPlay: true,
        ),
        items: imageSliders,
      ),
    );
  }
}

class FullscreenSliderDemo extends StatelessWidget {
  const FullscreenSliderDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Scaffold(
      appBar: AppBar(title: const Text('Fullscreen sliding carousel demo')),
      body: CarouselSlider(
        options: CarouselOptions(
          height: height,
          viewportFraction: 1.0,
          enlargeCenterPage: false,
          autoPlay: true,
        ),
        items: imgList
            .map(
              (item) => Image.network(item, fit: BoxFit.cover, height: height),
            )
            .toList(),
      ),
    );
  }
}

class OnDemandCarouselDemo extends StatelessWidget {
  const OnDemandCarouselDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('On-demand carousel demo')),
      body: CarouselSlider.builder(
        itemCount: 100,
        options: const CarouselOptions(
          aspectRatio: 2.0,
          enlargeCenterPage: true,
          autoPlay: true,
        ),
        itemBuilder: (context, index, realIdx) {
          return Text(index.toString());
        },
      ),
    );
  }
}

class CarouselWithIndicatorDemo extends StatefulWidget {
  const CarouselWithIndicatorDemo({super.key});

  @override
  State<CarouselWithIndicatorDemo> createState() =>
      _CarouselWithIndicatorState();
}

class _CarouselWithIndicatorState extends State<CarouselWithIndicatorDemo> {
  int _current = 0;
  final _controller = CarouselControllerX();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel with indicator controller demo'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CarouselSlider(
                items: imageSliders,
                carouselController: _controller,
                options: const CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: true,
                  aspectRatio: 2.0,
                ),
                onPageChanged: (index) {
                  setState(() {
                    _current = index;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: imgList
                  .asMap()
                  .entries
                  .map(
                    (entry) => GestureDetector(
                      onTap: () => _controller.animateToPage(entry.key),
                      child: Container(
                        width: 12.0,
                        height: 12.0,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.onSurface
                              .withAlpha(_current == entry.key ? 255 : 64),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class PrefetchImageDemo extends StatefulWidget {
  const PrefetchImageDemo({super.key});

  @override
  State<PrefetchImageDemo> createState() => _PrefetchImageDemoState();
}

class _PrefetchImageDemoState extends State<PrefetchImageDemo> {
  static const images = [
    'https://images.unsplash.com/photo-1586882829491-b81178aa622e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2850&q=80',
    'https://images.unsplash.com/photo-1586871608370-4adee64d1794?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2862&q=80',
    'https://images.unsplash.com/photo-1586901533048-0e856dff2c0d?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80',
    'https://images.unsplash.com/photo-1586902279476-3244d8d18285?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2850&q=80',
    'https://images.unsplash.com/photo-1586943101559-4cdcf86a6f87?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1556&q=80',
    'https://images.unsplash.com/photo-1586951144438-26d4e072b891?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80',
    'https://images.unsplash.com/photo-1586953983027-d7508a64f4bb?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1650&q=80',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var imageUrl in images) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prefetch image slider demo')),
      body: CarouselSlider.builder(
        itemCount: images.length,
        options: const CarouselOptions(
          autoPlay: true,
          aspectRatio: 2.0,
          enlargeCenterPage: true,
        ),
        itemBuilder: (context, index, realIdx) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(images[index], fit: BoxFit.cover, width: 1000),
        ),
      ),
    );
  }
}

class KeepPageViewPositionDemo extends StatelessWidget {
  const KeepPageViewPositionDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keep PageView position demo')),
      body: ListView.builder(
        itemBuilder: (ctx, index) {
          if (index == 3) {
            return CarouselSlider(
              options: const CarouselOptions(
                aspectRatio: 2.0,
                enlargeCenterPage: true,
                pageViewKey: PageStorageKey('carousel_slider'),
              ),
              items: imageSliders,
            );
          } else {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.blue,
              height: 200,
              child: const Center(child: Text('other content')),
            );
          }
        },
      ),
    );
  }
}

class MultipleItemDemo extends StatelessWidget {
  const MultipleItemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multiple item in one slide demo')),
      body: CarouselSlider.builder(
        options: const CarouselOptions(
          aspectRatio: 2.0,
          enlargeCenterPage: false,
          viewportFraction: 1,
        ),
        itemCount: (imgList.length / 2).round(),
        itemBuilder: (context, index, realIdx) {
          final first = index * 2;
          final second = first + 1;
          return Row(
            children: [first, second]
                .map(
                  (idx) => Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: Image.network(
                        imgList[idx],
                        fit: BoxFit.cover,
                        width: 1000,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class EnlargeStrategyZoomDemo extends StatelessWidget {
  const EnlargeStrategyZoomDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('enlarge strategy: zoom demo')),
      body: CarouselSlider(
        options: const CarouselOptions(
          aspectRatio: 2.0,
          enlargeCenterPage: true,
          enlargeStrategy: CenterPageEnlargeStrategy.zoom,
          enlargeFactor: 0.4,
        ),
        items: imageSliders,
      ),
    );
  }
}

class AutoPlayDemo extends StatefulWidget {
  const AutoPlayDemo({super.key});

  @override
  State<AutoPlayDemo> createState() => _AutoPlayDemoState();
}

class _AutoPlayDemoState extends State<AutoPlayDemo> {
  static const _slow = Duration(seconds: 2);
  static const _fast = Duration(milliseconds: 500);

  final _controller = CarouselControllerX();
  var _interval = _slow;
  var _index = 0;
  var _slides = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto play demo')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                height: 220,
                autoPlay: true,
                autoPlayInterval: _interval,
                enlargeCenterPage: true,
              ),
              onPageChanged: (index) => setState(() {
                _index = index;
                _slides++;
              }),
              items: imageSliders,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('item $_index, $_slides slides so far'),
                  const SizedBox(height: 12),
                  const Text(
                    'Rest a finger on the carousel and auto play waits, '
                    'whether or not the finger ever drags. Letting go gives it '
                    'a full interval again, and so does either arrow.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _controller.previousPage(),
                        child: const Text('←'),
                      ),
                      ElevatedButton(
                        onPressed: () => _controller.nextPage(),
                        child: const Text('→'),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(
                          () => _interval = _interval == _slow ? _fast : _slow,
                        ),
                        child: Text('interval: ${_interval.inMilliseconds}ms'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _interval == _fast
                        ? 'The interval is now shorter than the 800ms slide. '
                              'A tick that lands mid-slide declines and waits '
                              'again, so the carousel moves once per 1000ms '
                              'rather than fighting itself.'
                        : 'Two seconds between slides, measured from one slide '
                              'to the next.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
