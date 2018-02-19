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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Stack(
        children: [
          new PageUi(pages[0]),
          new PagerIndicator(pages: pages),
        ],
      ),
    );
  }
}

/// PageUi
///
/// Render a fullscreen page that includes a hero, title, and description.
class PageUi extends StatelessWidget {

  final Page page;

  PageUi(this.page);

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
            new Image.asset(
              page.heroAssetPath,
              width: 200.0,
              height: 200.0,
            ),
            new Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
              child: new Text(
                page.title,
                style: new TextStyle(
                  fontSize: 34.0,
                  fontFamily: 'FlamanteRoma',
                ),
              ),
            ),
            new Padding(
              padding: const EdgeInsets.only(bottom: 75.0),
              child: new Text(
                page.body,
                textAlign: TextAlign.center,
                style: new TextStyle(
                  fontSize: 18.0,
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
class PagerIndicator extends StatelessWidget {

  final List<Page> pages;

  PagerIndicator({
    @required this.pages,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> bubblesUi = pages.map((Page page) {
      return new Padding(
        padding: const EdgeInsets.all(15.0),
        child: new PagerBubbleUi(
          bubble: new PagerBubble(
              page.iconAssetPath,
              page.color,
              false,
              true,
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
      decoration: new BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: new Image.asset(
        bubble.iconAssetPath,
        color: bubble.color,
      ),
    );
  }
}
