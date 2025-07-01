import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rick_spot/screens/homepage.dart';
import 'package:rick_spot/screens/artist_page.dart';

// Define a provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/artist/:artistId',
        name: 'artist',
        builder: (context, state) {
          final artistId = state.pathParameters['artistId'] ?? '';
          final artistName = state.uri.queryParameters['name'] ?? 'Artist';
          return ArtistPage(artistId: artistId, artistName: artistName);
        },
      ),
    ],
  );
});

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the router from the provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
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
      routerConfig: router,
    );
  }
}
