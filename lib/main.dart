import 'package:flutter/material.dart';
import 'package:material_page_reveal_published/pages.dart';
import 'package:meta/meta.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Material Page Reveal',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  static const FULL_TRANSITION_PX = 300.0;

  int _activeIndex = 0;
  Offset _dragStart;
  double _transitionAmount; // [-1.0, 1.0], negative means dragging left to right, and positive means dragging right to left.

  _onDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  _onDrag(DragUpdateDetails details) {
    setState(() {
      final newPosition = details.globalPosition;
      final dx = _dragStart.dx - newPosition.dx;

      final minTransitionAmount = _activeIndex > 0 ? -1.0 : 0.0;
      final maxTransitionAmount = _activeIndex < pages.length - 1 ? 1.0 : 0.0;

      _transitionAmount = (dx / FULL_TRANSITION_PX).clamp(minTransitionAmount, maxTransitionAmount);
//      print('Transition amount: $_transitionAmount');
    });
  }

  _onDragEnd(DragEndDetails details) {
    setState(() {
      if (null != _transitionAmount) {
        if (_transitionAmount.abs() > 0.5) {
          _activeIndex += (_transitionAmount / _transitionAmount.abs()).round();
        }
      }

      // Cleanup
      _dragStart = null;
      _transitionAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(
        children: [
          new PageUi(
            new VisiblePage(
              pages[_activeIndex],
              1.0,
            ),
          ),
          _transitionAmount != 0.0 && _transitionAmount != null
            ? new PageUi(
                new VisiblePage(
                  pages[_activeIndex + (_transitionAmount / _transitionAmount.abs()).round()],
                  _transitionAmount.abs(),
                ),
              )
            : new Container(),
          new PagerIndicatorUi(
            viewModel: new PagerIndicator(
              pages,
              _activeIndex,
              _transitionAmount
            ),
          ),
          new GestureDetector(
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDrag,
            onHorizontalDragEnd: _onDragEnd,
          )
        ],
      ),
    );
  }
}

/// PageUi
///
/// Render a fullscreen page that includes a hero, title, and description.
class PageUi extends StatelessWidget {

  final VisiblePage visiblePage;

  PageUi(this.visiblePage);

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: double.INFINITY,
      color: visiblePage.page.color,
      child: new Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Transform(
              transform: new Matrix4.translationValues(0.0, 50.0 * (1.0 - visiblePage.visibleAmount), 0.0),
              child: new Opacity(
                opacity: visiblePage.visibleAmount,
                child: new Image.asset(
                  visiblePage.page.heroAssetPath,
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ),
            new Transform(
              transform: new Matrix4.translationValues(0.0, 30.0 * (1.0 - visiblePage.visibleAmount), 0.0),
              child: new Opacity(
                opacity: visiblePage.visibleAmount,
                child: new Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: new Text(
                    visiblePage.page.title,
                    style: new TextStyle(
                      fontSize: 34.0,
                      fontFamily: 'FlamanteRoma',
                    ),
                  ),
                ),
              ),
            ),
            new Transform(
              transform: new Matrix4.translationValues(0.0, 30.0 * (1.0 - visiblePage.visibleAmount), 0.0),
              child: new Opacity(
                opacity: visiblePage.visibleAmount,
                child: new Padding(
                  padding: const EdgeInsets.only(bottom: 75.0),
                  child: new Text(
                    visiblePage.page.body,
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                      fontSize: 18.0,
                    ),
                  ),
                ),
              ),
            ),
          ]
        ),
      ),
    );
  }
}

/// PagerIndiciator renders the entire set of bubbles at the bottom of the
/// screen that show what page you're currently on and how close you are to
/// the next page.
class PagerIndicatorUi extends StatelessWidget {

  final PagerIndicator viewModel;

  PagerIndicatorUi({
    @required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> bubblesUi = viewModel.pages.map((Page page) {
      final isActive = viewModel.pages.indexOf(page) == viewModel.activeIndex;

      return new Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: 5.0, right: 5.0),
        child: new PagerBubbleUi(
          bubble: new PagerBubble(
              page.iconAssetPath,
              page.color,
              false,
              isActive,
              0.0
          ),
        ),
      );
    }).toList();

    return new Column(
      children: [
        new Expanded(
          child: new Container(),
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bubblesUi,
        )
      ]
    );
  }
}

/// PagerBubbleUi renders a single bubble in the Pager Indicator.
class PagerBubbleUi extends StatelessWidget {

  static const MAX_INDICATOR_SIZE = 50.0;
  static const MIN_INDICATOR_SIZE = 20.0;

  final PagerBubble bubble;

  PagerBubbleUi({
    @required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: MAX_INDICATOR_SIZE,
      height: MAX_INDICATOR_SIZE,
      child: new Center(
        child: new Container(
          width: bubble.isActive ? MAX_INDICATOR_SIZE : MIN_INDICATOR_SIZE,
          height: bubble.isActive ? MAX_INDICATOR_SIZE : MIN_INDICATOR_SIZE,
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: bubble.isActive
            ? new Image.asset(
                bubble.iconAssetPath,
                color: bubble.color,
              )
            : new Container(),
        ),
      ),
    );
  }
}
