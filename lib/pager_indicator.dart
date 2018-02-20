import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:material_page_reveal_published/pages.dart';
import 'package:meta/meta.dart';

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
        transitionAmount = (transitionPosition - viewModel.activeIndex).abs();
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

class PagerIndicatorViewModel {
  final List<PageViewModel> pages;
  final int activeIndex;
  final double transitionAmount; // [-1.0, 1.0] where negative means moving to previous and positive means moving to next.

  PagerIndicatorViewModel(
    this.pages,
    this.activeIndex,
    this.transitionAmount,
  );
}

class PagerBubbleViewModel {
  final String iconAssetPath;
  final Color color;
  final bool isHollow;
  final bool isActive;
  final double transitionAmount;

  PagerBubbleViewModel(
    this.iconAssetPath,
    this.color,
    this.isHollow,
    this.isActive,
    this.transitionAmount,
  );
}