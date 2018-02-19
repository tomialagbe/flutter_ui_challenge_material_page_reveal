import 'package:flutter/material.dart';
import 'package:material_page_reveal_published/pages.dart';

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
