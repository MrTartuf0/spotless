import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RecentTrack {
  final String id;
  final String title;
  final String artist;
  final String artistId;
  final String imageUrl;
  final DateTime playedAt;

  const RecentTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artistId,
    required this.imageUrl,
    required this.playedAt,
  });
}

class RecentAlbum {
  final String id;
  final String name;
  final String artist;
  final String artistId;
  final String imageUrl;
  final DateTime openedAt;

  const RecentAlbum({
    required this.id,
    required this.name,
    required this.artist,
    required this.artistId,
    required this.imageUrl,
    required this.openedAt,
  });
}

class RecentArtist {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime openedAt;

  const RecentArtist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.openedAt,
  });
}

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  Database? _db;
  Future<Database>? _opening;

  // Broadcast when history changes so FutureProviders can refresh.
  final _changes = StreamController<void>.broadcast();
  Stream<void> get onChange => _changes.stream;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    if (_opening != null) return _opening!;

    _opening = () async {
      // sqflite has no native Linux/Windows bindings — use the FFI backend.
      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'spotless_history.db');

      final db = await openDatabase(
        path,
        version: 2,
        onUpgrade: (db, from, to) async {
          // v2 added artists. Existing installs only need the new table.
          if (from < 2) await _createArtists(db);
        },
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE recent_tracks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              artist_id TEXT NOT NULL,
              image_url TEXT NOT NULL,
              played_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE recent_albums (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              artist TEXT NOT NULL,
              artist_id TEXT NOT NULL,
              image_url TEXT NOT NULL,
              opened_at INTEGER NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_tracks_played_at ON recent_tracks(played_at DESC)',
          );
          await db.execute(
            'CREATE INDEX idx_albums_opened_at ON recent_albums(opened_at DESC)',
          );
          await _createArtists(db);
        },
      );

      _db = db;
      return db;
    }();

    try {
      return await _opening!;
    } finally {
      _opening = null;
    }
  }

  static Future<void> _createArtists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recent_artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        image_url TEXT NOT NULL,
        opened_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_artists_opened_at '
      'ON recent_artists(opened_at DESC)',
    );
  }

  Future<void> recordTrack({
    required String id,
    required String title,
    required String artist,
    required String artistId,
    required String imageUrl,
  }) async {
    if (id.isEmpty) return;
    final db = await _open();
    await db.insert(
      'recent_tracks',
      {
        'id': id,
        'title': title,
        'artist': artist,
        'artist_id': artistId,
        'image_url': imageUrl,
        'played_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changes.add(null);
  }

  Future<void> recordAlbum({
    required String id,
    required String name,
    required String artist,
    required String artistId,
    required String imageUrl,
  }) async {
    if (id.isEmpty) return;
    final db = await _open();
    await db.insert(
      'recent_albums',
      {
        'id': id,
        'name': name,
        'artist': artist,
        'artist_id': artistId,
        'image_url': imageUrl,
        'opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changes.add(null);
  }

  /// Records an artist visit. An empty [imageUrl] never overwrites an artwork
  /// we already resolved — visits arrive from places that only know the id.
  Future<void> recordArtist({
    required String id,
    required String name,
    String imageUrl = '',
  }) async {
    if (id.isEmpty) return;
    final db = await _open();

    var image = imageUrl;
    if (image.isEmpty) {
      final existing = await db.query(
        'recent_artists',
        columns: ['image_url'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (existing.isNotEmpty) image = existing.first['image_url'] as String;
    }

    await db.insert(
      'recent_artists',
      {
        'id': id,
        'name': name,
        'image_url': image,
        'opened_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changes.add(null);
  }

  /// Fills in artwork for an artist we only knew by name, without touching
  /// [RecentArtist.openedAt] — merely looking at a shelf shouldn't reorder it.
  ///
  /// Only announces a change when a row actually changed, so the resolve →
  /// refresh → resolve cycle settles after one pass.
  Future<void> updateArtistImage(String id, String imageUrl) async {
    if (id.isEmpty || imageUrl.isEmpty) return;
    final db = await _open();
    final updated = await db.update(
      'recent_artists',
      {'image_url': imageUrl},
      where: 'id = ? AND image_url != ?',
      whereArgs: [id, imageUrl],
    );
    if (updated > 0) _changes.add(null);
  }

  Future<List<RecentArtist>> recentArtists({int limit = 20}) async {
    final db = await _open();
    final rows = await db.query(
      'recent_artists',
      orderBy: 'opened_at DESC',
      limit: limit,
    );
    return rows
        .map((r) => RecentArtist(
              id: r['id'] as String,
              name: r['name'] as String,
              imageUrl: r['image_url'] as String,
              openedAt:
                  DateTime.fromMillisecondsSinceEpoch(r['opened_at'] as int),
            ))
        .toList();
  }

  Future<List<RecentTrack>> recentTracks({int limit = 20}) async {
    final db = await _open();
    final rows = await db.query(
      'recent_tracks',
      orderBy: 'played_at DESC',
      limit: limit,
    );
    return rows.map((r) => RecentTrack(
      id: r['id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String,
      artistId: r['artist_id'] as String,
      imageUrl: r['image_url'] as String,
      playedAt: DateTime.fromMillisecondsSinceEpoch(r['played_at'] as int),
    )).toList();
  }

  Future<List<RecentAlbum>> recentAlbums({int limit = 20}) async {
    final db = await _open();
    final rows = await db.query(
      'recent_albums',
      orderBy: 'opened_at DESC',
      limit: limit,
    );
    return rows.map((r) => RecentAlbum(
      id: r['id'] as String,
      name: r['name'] as String,
      artist: r['artist'] as String,
      artistId: r['artist_id'] as String,
      imageUrl: r['image_url'] as String,
      openedAt: DateTime.fromMillisecondsSinceEpoch(r['opened_at'] as int),
    )).toList();
  }
}
