import 'dart:math';
import 'dart:ui';

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
  double _transitionAmount = 0.0; // [-1.0, 1.0], negative means dragging left to right, and positive means dragging right to left.

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
            ? new ClipOval(
                clipper: new CircleRevealClipper(_transitionAmount),
                child: new PageUi(
                  new VisiblePage(
                    pages[_activeIndex + (_transitionAmount / _transitionAmount.abs()).round()],
                    _transitionAmount.abs(),
                  ),
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

class CircleRevealClipper extends CustomClipper<Rect> {

  double revealPercent;

  CircleRevealClipper(
    this.revealPercent,
  );

  @override
  Rect getClip(Size size) {
    final epicenter = new Offset(size.width * 0.5, size.height * 0.9);

    // Calculate distance from epicenter to top left corner to make sure we fill the screen.
    double theta = atan(epicenter.dy / epicenter.dx);
    final distanceToCorner = epicenter.dy / sin(theta);

    final radius = distanceToCorner * revealPercent;
    final diameter = 2 * radius;

    return new Rect.fromLTWH(epicenter.dx - radius, epicenter.dy - radius, diameter, diameter);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
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
const MAX_INDICATOR_SIZE = 40.0;
const MIN_INDICATOR_SIZE = 15.0;
const INDICATOR_X_PADDING = 5.0;
const BUBBLE_COLOR = const Color(0x88FFFFFF);

class PagerIndicatorUi extends StatelessWidget {

  final PagerIndicator viewModel;

  PagerIndicatorUi({
    @required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> bubblesUi = viewModel.pages.map((Page page) {
      final pageIndex = viewModel.pages.indexOf(page);
      final isActive = pageIndex == viewModel.activeIndex;
      final isHollow = !isActive && pageIndex > viewModel.activeIndex;

      var transitionAmount = 0.0;
      final transitionPosition = viewModel.activeIndex + viewModel.transitionAmount;
      if (isActive) {
        transitionAmount = 1.0 - viewModel.transitionAmount.abs();
      } else if ((pageIndex - transitionPosition).abs() < 1.0){
        print('Position: $transitionPosition');
        transitionAmount = (transitionPosition - viewModel.activeIndex).abs();
        print('Transition amount: $transitionAmount');
      }

      return new Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: INDICATOR_X_PADDING, right: INDICATOR_X_PADDING),
        child: new PagerBubbleUi(
          bubble: new PagerBubble(
              page.iconAssetPath,
              page.color,
              isHollow,
              isActive,
              transitionAmount,
          ),
        ),
      );
    }).toList();

    // Calculate the horizontal translation of the pager indicator
    final halfIndicatorWidth = ((pages.length * MAX_INDICATOR_SIZE) + (pages.length * INDICATOR_X_PADDING * 2)) / 2;
    final startingPosition = halfIndicatorWidth - INDICATOR_X_PADDING - (MAX_INDICATOR_SIZE / 2.0);
    final indicatorXPosition = startingPosition
        - ((viewModel.activeIndex + viewModel.transitionAmount) * (MAX_INDICATOR_SIZE + (2 * INDICATOR_X_PADDING)));

    return new Column(
      children: [
        new Expanded(
          child: new Container(),
        ),
        new Transform(
          transform: new Matrix4.translationValues(indicatorXPosition, 0.0, 0.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: bubblesUi,
          ),
        )
      ]
    );
  }
}

/// PagerBubbleUi renders a single bubble in the Pager Indicator.
class PagerBubbleUi extends StatelessWidget {

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
          width: lerpDouble(
              MIN_INDICATOR_SIZE,
              MAX_INDICATOR_SIZE,
              bubble.transitionAmount,
          ),
          height: lerpDouble(
              MIN_INDICATOR_SIZE,
              MAX_INDICATOR_SIZE,
              bubble.transitionAmount,
          ),
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
            color: bubble.isHollow
                ? BUBBLE_COLOR.withAlpha((0x88 * (bubble.transitionAmount).abs()).round())
                : BUBBLE_COLOR,
            border: bubble.isHollow
              ? new Border.all(
                  color: bubble.isHollow
                    ? BUBBLE_COLOR
                    : BUBBLE_COLOR.withAlpha((0x88 * (1.0 - bubble.transitionAmount).abs()).round()),
                  width: 3.0,
                )
              : null,
          ),
          child: new Opacity(
                opacity: bubble.transitionAmount.abs(),
                child: new Image.asset(
                  bubble.iconAssetPath,
                  color: bubble.color,
                ),
              )
        ),
      ),
    );
  }
}
