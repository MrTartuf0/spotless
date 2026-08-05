import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/screens/app_shell.dart';
import 'package:spotACrack/screens/artist_page.dart';
import 'package:spotACrack/screens/album_page.dart';
import 'package:spotACrack/utils/responsive.dart';

/// Every route renders inside [AppShell]. Artist and album pages are pushed
/// onto the shell's own navigator, so the sidebar, the tabs underneath and the
/// player all survive the navigation.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const TabHost(),
          ),
          GoRoute(
            path: '/artist/:artistId',
            name: 'artist',
            builder: (context, state) {
              final artistId = state.pathParameters['artistId'] ?? '';
              final artistName = state.uri.queryParameters['name'] ?? 'Artist';
              final artistImage = state.uri.queryParameters['image'] ?? '';

              return ArtistPage(
                // Keyed by id so pushing a different artist rebuilds the page
                // instead of reusing the previous one's state.
                key: ValueKey(artistId),
                artistId: artistId,
                artistName: artistName,
                artistImage: artistImage,
              );
            },
          ),
          GoRoute(
            path: '/album/:albumId',
            name: 'album',
            builder: (context, state) {
              final albumId = state.pathParameters['albumId'] ?? '';
              final albumName = state.uri.queryParameters['name'] ?? 'Album';
              final albumImage = state.uri.queryParameters['image'] ?? '';

              return AlbumPage(
                key: ValueKey(albumId),
                albumId: albumId,
                fallbackName: albumName,
                fallbackImage: albumImage,
              );
            },
          ),
        ],
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
      title: 'spotACrack',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xff1BD760),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textSelectionTheme: const TextSelectionThemeData(
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
      // Desktop pointers can drag the horizontal rows, which they can't by
      // default and which makes those rows feel broken with a mouse.
      scrollBehavior: const DragScrollBehavior(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
