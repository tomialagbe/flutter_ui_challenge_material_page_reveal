import 'dart:ui';

import 'package:flutter/widgets.dart';

final pages = [
  new PageViewModel(
    const Color(0xFF678FB4),
    'assets/hotels.png',
    'Hotels',
    'All hotels and hostels are sorted by hospitality rating',
    'assets/key.png'
  ),
  new PageViewModel(
    const Color(0xFF65B0B4),
    'assets/banks.png',
    'Banks',
    'We carefully verify all banks before adding them into the app',
    'assets/wallet.png'
  ),
  new PageViewModel(
    const Color(0xFF9B90BC),
    'assets/stores.png',
    'Store',
    'All local stores are categorized for your convenience',
    'assets/shopping_cart.png',
  ),
];

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

class PageViewModel {
  final Color color;
  final String heroAssetPath;
  final String title;
  final String body;
  final String iconAssetPath;

  PageViewModel(
    this.color,
    this.heroAssetPath,
    this.title,
    this.body,
    this.iconAssetPath,
  );
}
