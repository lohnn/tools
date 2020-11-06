import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';

import 'scenes/changelog.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Git changelog',
      theme: ThemeData(
        primaryColor: const Color(0xff6f42c1),
        cupertinoOverrideTheme: CupertinoThemeData(
          primaryColor: const Color(0xff6f42c1),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Changelog(),
    );
  }
}
