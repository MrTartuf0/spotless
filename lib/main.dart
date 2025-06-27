import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:rick_spot/widgets/bottom_player.dart';
import 'package:rick_spot/widgets/searchbar.dart';
import 'package:rick_spot/widgets/sheet_player.dart';

void main() {
  runApp(const MyApp());
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
      home: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Stack(
          children: [
            BottomPlayer(),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 48, 16, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    Gap(16),
                    Searchbar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
