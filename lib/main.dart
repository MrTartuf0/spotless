import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:rick_spot/widgets/bottom_player.dart';
import 'package:rick_spot/widgets/searchbar.dart';
import 'package:rick_spot/widgets/sheet_player.dart';
import 'package:rick_spot/providers/audio_player_provider.dart'; // Import the provider

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
      home: HomePage(),
    );
  }
}

// Created a separate widget for the home page so we can use ConsumerWidget
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32),
                  ),
                  Gap(16),
                  Searchbar(),
                  Gap(16),
                  ElevatedButton(
                    onPressed: () {
                      // Get the audio player notifier and load the track
                      final audioNotifier = ref.read(
                        audioPlayerProvider.notifier,
                      );
                      audioNotifier.loadTrack('2aibwv5hGXSgw7Yru8IYTO');

                      // Show a snackbar to indicate the track is loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Loading track...',
                            style: TextStyle(color: Colors.black),
                          ),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xff1BD760),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff1BD760),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Play: 2aibwv5hGXSgw7Yru8IYTO'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Get the audio player notifier and load the track
                      final audioNotifier = ref.read(
                        audioPlayerProvider.notifier,
                      );
                      audioNotifier.loadTrack('1AsNfUfuGmQGXbrjoPQl8j');

                      // Show a snackbar to indicate the track is loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Loading track...',
                            style: TextStyle(color: Colors.black),
                          ),
                          duration: Duration(seconds: 1),
                          backgroundColor: Color(0xff1BD760),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff1BD760),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Play: 1AsNfUfuGmQGXbrjoPQl8j'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
