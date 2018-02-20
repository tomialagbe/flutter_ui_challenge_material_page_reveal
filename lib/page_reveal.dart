import 'dart:math';

import 'package:flutter/widgets.dart';

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

  final double revealPercent;

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