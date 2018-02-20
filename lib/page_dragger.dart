import 'dart:async';

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

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