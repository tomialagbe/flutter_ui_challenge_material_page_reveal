import 'dart:async';
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

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  // Render state at a given moment
  int _activeIndex = 0;
  DragDirection _dragDirection;
  double _transitionPercent = 0.0;

  // Dragging and Animating
  StreamController<PageTransitionUpdate> _pageTransitionUpdateStreamController;
  AnimatedPageDragger _animatedPageDragger;
  int _nextIndexAfterAnimation = 0;

  @override
  void initState() {
    super.initState();
    _initPageTransitionStream();
  }

  _initPageTransitionStream() {
    _pageTransitionUpdateStreamController = new StreamController<PageTransitionUpdate>();
    _pageTransitionUpdateStreamController.stream.listen((PageTransitionUpdate update) {
      if (update.updateType == PageTransitionUpdateType.dragging) {
        _onDragging(update);
      } else if (update.updateType == PageTransitionUpdateType.dragEnded) {
        _onDragEnded(update);
      } else if (update.updateType == PageTransitionUpdateType.animating) {
        _onAnimating(update);
      } else if (update.updateType == PageTransitionUpdateType.animationEnded) {
        _onAnimationEnded();
      }
    });
  }

  _onDragging(PageTransitionUpdate update) {
    setState(() {
      _dragDirection = update.direction;
      _transitionPercent = update.transitionPercent;
    });
  }

  _onDragEnded(PageTransitionUpdate update) {
    setState(() {
      // The user is done dragging. Animate the rest of the way.
      var transitionGoal;
      if (_transitionPercent > 0.5) {
        // User dragged far enough to continue to next screen.
        transitionGoal = TransitionGoal.openPage;
        print('Drag end direction: ${update.direction}');
        _nextIndexAfterAnimation = update.direction == DragDirection.rightToLeft ? _activeIndex + 1 : _activeIndex - 1;
      } else {
        // User did not drag far enough to go to next screen. Return to previous screen.
        transitionGoal = TransitionGoal.closePage;
        _nextIndexAfterAnimation = _activeIndex;
      }

      _animatedPageDragger = new AnimatedPageDragger(
        direction: update.direction,
        transitionGoal: transitionGoal,
        transitionAmount: update.transitionPercent,
        pageAnimateStream: _pageTransitionUpdateStreamController,
        vsync: this,
      )..run();
    });
  }

  _onAnimating(PageTransitionUpdate update) {
    setState(() => _transitionPercent = update.transitionPercent);
  }

  _onAnimationEnded() {
    setState(() {
      _dragDirection = null;
      _transitionPercent = 0.0;
      _activeIndex = _nextIndexAfterAnimation;

      _animatedPageDragger.dispose();
    });
  }

  @override
  void dispose() {
    _pageTransitionUpdateStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var signedTransitionAmount;
    if (_dragDirection != null) {
      signedTransitionAmount = _dragDirection == DragDirection.rightToLeft
          ? _transitionPercent
          : -_transitionPercent;
    } else {
      signedTransitionAmount = 0.0;
    }

    final nextPageIndex = (_activeIndex + (_dragDirection == DragDirection.rightToLeft ? 1 : -1))
        .clamp(0.0, pages.length - 1)
        .round();
    print('Active index: $_activeIndex. Next index: $nextPageIndex. Transition percent: $_transitionPercent');

    return new Scaffold(
      body: new Stack(
        children: [
          new PageUi(
            page: pages[_activeIndex],
          ),

          new PageReveal(
            revealPercent: _transitionPercent,
            child: _dragDirection != null
              ? new PageUi(
                  page: pages[nextPageIndex],
                  percentVisible: _transitionPercent,
                )
              : null,
          ),

          new PagerIndicatorUi(
            viewModel: new PagerIndicatorViewModel(
              pages,
              _activeIndex,
                signedTransitionAmount
            ),
          ),

          new PageDragger(
            canDragLeftToRight: _activeIndex > 0,
            canDragRightToLeft: _activeIndex < pages.length - 1,
            pageDragStream: _pageTransitionUpdateStreamController
          ),
        ],
      ),
    );
  }
}

/// PageReveal
///
/// Widget that reveals its child starting with a circle at the bottom center of
/// the child Widget.
class PageReveal extends StatelessWidget {

  final double revealPercent;
  final Widget child;

  PageReveal({
    this.revealPercent,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return new ClipOval(
      clipper: new CircleRevealClipper(revealPercent),
      child: child,
    );
  }
}


/// CircleRevealClipper
///
/// CustomClipper that exposes a circular region of a Widget starting near the
/// bottom center of the Widget.
///
/// When the [revealPercent] is 0.0, nothing is shown. When the [revealPercent]
/// is 1.0, everything is shown.
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

  final PageViewModel page;
  final double percentVisible;

  PageUi({
    this.page,
    this.percentVisible = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return new Container(
      width: double.INFINITY,
      color: page.color,
      child: new Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            new Transform(
              transform: new Matrix4.translationValues(0.0, 50.0 * (1.0 - percentVisible), 0.0),
              child: new Opacity(
                opacity: percentVisible,
                child: new Padding(
                  padding: const EdgeInsets.only(bottom: 25.0),
                  child: new Image.asset(
                    page.heroAssetPath,
                    width: 200.0,
                    height: 200.0,
                  ),
                ),
              ),
            ),
            new Transform(
              transform: new Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
              child: new Opacity(
                opacity: percentVisible,
                child: new Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                  child: new Text(
                    page.title,
                    style: new TextStyle(
                      fontSize: 34.0,
                      fontFamily: 'FlamanteRoma',
                    ),
                  ),
                ),
              ),
            ),
            new Transform(
              transform: new Matrix4.translationValues(0.0, 30.0 * (1.0 - percentVisible), 0.0),
              child: new Opacity(
                opacity: percentVisible,
                child: new Padding(
                  padding: const EdgeInsets.only(bottom: 75.0),
                  child: new Text(
                    page.body,
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
const INDICATOR_X_PADDING = 3.0;
const BUBBLE_COLOR = const Color(0x88FFFFFF);

class PagerIndicatorUi extends StatelessWidget {

  final PagerIndicatorViewModel viewModel;

  PagerIndicatorUi({
    @required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> bubblesUi = viewModel.pages.map((PageViewModel page) {
      final pageIndex = viewModel.pages.indexOf(page);
      final isActive = pageIndex == viewModel.activeIndex;
      final isHollow = !isActive && pageIndex > viewModel.activeIndex;

      var transitionAmount = 0.0;
      final transitionPosition = viewModel.activeIndex + viewModel.transitionAmount;
      if (isActive) {
        transitionAmount = 1.0 - viewModel.transitionAmount.abs();
      } else if ((pageIndex - transitionPosition).abs() < 1.0){
//        print('Position: $transitionPosition');
        transitionAmount = (transitionPosition - viewModel.activeIndex).abs();
//        print('Transition amount: $transitionAmount');
      }

      return new Padding(
        padding: const EdgeInsets.only(top: 15.0, bottom: 15.0, left: INDICATOR_X_PADDING, right: INDICATOR_X_PADDING),
        child: new PagerBubbleUi(
          bubble: new PagerBubbleViewModel(
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

  final PagerBubbleViewModel bubble;

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

/// PageDragger
///
/// Detects drag gestures from left to right and right to left and notifies a
/// stream as the dragging occurs, and when the user lets go.
class PageDragger extends StatefulWidget {

  final bool canDragRightToLeft;
  final bool canDragLeftToRight;
  final StreamController<PageTransitionUpdate> pageDragStream;

  PageDragger({
    @required this.pageDragStream,
    this.canDragRightToLeft = true,
    this.canDragLeftToRight = true,
  });

  @override
  _PageDraggerState createState() => new _PageDraggerState();
}

class _PageDraggerState extends State<PageDragger> {

  static const FULL_TRANSITION_PX = 300.0; // How far the user drags until a page transition is complete

  Offset _dragStart;
  DragDirection _dragDirection;
  double _transitionAmount = 0.0;

  _onDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition;
  }

  _onDrag(DragUpdateDetails details) {
    setState(() {
      final newPosition = details.globalPosition;
      final dx = _dragStart.dx - newPosition.dx;
      _dragDirection = dx > 0.0 ? DragDirection.rightToLeft : DragDirection.leftToRight;

      final minTransitionAmount = widget.canDragLeftToRight ? -1.0 : 0.0;
      final maxTransitionAmount = widget.canDragRightToLeft ? 1.0 : 0.0;

      _transitionAmount = (dx / FULL_TRANSITION_PX).clamp(minTransitionAmount, maxTransitionAmount).abs();

      widget.pageDragStream.add(
        new PageTransitionUpdate(
          PageTransitionUpdateType.dragging,
          _dragDirection,
          _transitionAmount,
        )
      );
    });
  }

  _onDragEnd(DragEndDetails details) {
    setState(() {
      // The user is done dragging. Animate the rest of the way.
      if (null != _transitionAmount) {
        widget.pageDragStream.add(
          new PageTransitionUpdate(
            PageTransitionUpdateType.dragEnded,
            _dragDirection,
            _transitionAmount
          )
        );
      }

      // Cleanup
      _dragStart = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDrag,
      onHorizontalDragEnd: _onDragEnd,
    );
  }
}

/// AnimatedPageDragger
///
/// Given an initial page transition amount, a direction, and a goal (open or
/// closed), AnimatedPageDragger animates the transition the rest of the way by
/// emitting [PageAnimateUpdate]s until the transition is complete.
class AnimatedPageDragger {

  static const PERCENT_PER_MILLISECOND = 0.005; // How quickly a transition animation should move

  final direction;
  final transitionGoal;

  AnimationController completionAnimationController;

  AnimatedPageDragger({
    @required this.direction,
    @required this.transitionGoal,
    @required transitionAmount,
    @required StreamController<PageTransitionUpdate> pageAnimateStream,
    @required TickerProvider vsync,
  }) {
    final startTransitionAmount = transitionAmount;
    var endTransitionAmount;
    var duration;

    if (transitionGoal == TransitionGoal.openPage) {
      // Animate the transition the rest of the way.
      endTransitionAmount = 1.0;
      final transitionRemaining = 1.0 - transitionAmount;
      duration = new Duration(milliseconds: (transitionRemaining / PERCENT_PER_MILLISECOND).round());
    } else {
      // Animate the transition back to zero.
      endTransitionAmount = 0.0;
      duration = new Duration(milliseconds: (transitionAmount / PERCENT_PER_MILLISECOND).round());
    }

    completionAnimationController = new AnimationController(duration: duration, vsync: vsync)
      ..addListener(() {
        final animatedTransition = lerpDouble(startTransitionAmount, endTransitionAmount, completionAnimationController.value);

        pageAnimateStream.add(
          new PageTransitionUpdate(
            PageTransitionUpdateType.animating,
            this.direction,
            animatedTransition,
          )
        );
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          pageAnimateStream.add(
            new PageTransitionUpdate(
              PageTransitionUpdateType.animationEnded,
              this.direction,
              endTransitionAmount,
            )
          );
        }
      });
  }

  run() {
    completionAnimationController.forward(from: 0.0);
  }

  dispose() {
    completionAnimationController.dispose();
  }

}

enum TransitionGoal {
  openPage,
  closePage,
}

enum DragDirection {
  rightToLeft,
  leftToRight,
}

enum PageTransitionUpdateType {
  dragging,
  dragEnded,
  animating,
  animationEnded,
}

class PageTransitionUpdate {
  final updateType;
  final direction;
  final transitionPercent;

  PageTransitionUpdate(
    this.updateType,
    this.direction,
    this.transitionPercent,
  );
}