import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rick_spot/screens/homepage.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: Color(0xff1BD760),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xff1BD760),
          selectionColor: Color(0xff1BD760),
          selectionHandleColor: Color(0xff1BD760),
        ),
        fontFamily: 'SpotifyMixUI',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: 'SpotifyMixUI',
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
