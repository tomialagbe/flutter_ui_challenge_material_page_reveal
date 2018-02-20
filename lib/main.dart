import 'package:flutter/material.dart';
import 'package:material_page_reveal_published/onboarding_flow.dart';

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
      home: new OnboardingFlow(),
    );
  }
}