import 'package:flutter/material.dart';

class ArtistPage extends StatelessWidget {
  final String artistId;
  final String artistName;

  const ArtistPage({
    super.key,
    required this.artistId,
    this.artistName = 'Artist',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),

      body: Center(
        child: Text(
          'Artist ID: $artistId',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
