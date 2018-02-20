import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_page_reveal_published/page_dragger.dart';
import 'package:material_page_reveal_published/page_reveal.dart';
import 'package:material_page_reveal_published/pager_indicator.dart';
import 'package:material_page_reveal_published/pages.dart';

class OnboardingFlow extends StatefulWidget {

  @override
  _OnboardingFlowState createState() => new _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> with TickerProviderStateMixin {

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