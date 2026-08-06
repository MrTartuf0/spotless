package com.example.spotACrack

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service requires this base class instead of FlutterActivity so the
// media session can bring the app back up from a notification, a media button
// or a car head unit.
class MainActivity : AudioServiceActivity()
