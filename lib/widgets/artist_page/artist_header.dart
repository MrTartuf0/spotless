import 'package:flutter/material.dart';
import 'package:spotACrack/models/artist_profile.dart';
import 'package:spotACrack/utils/responsive.dart';

/// Artist page banner.
///
/// Two arrangements: artwork above a centred name on phones, and artwork
/// beside a large name on wide windows, which is where the extra width is
/// actually worth something.
class ArtistHeader extends StatelessWidget {
  final String artistName;
  final String artistImage;
  final ArtistProfile? profile;
  final Color dominantColor;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;

  const ArtistHeader({
    super.key,
    required this.artistName,
    required this.artistImage,
    required this.dominantColor,
    this.profile,
    this.onPlay,
    this.onShuffle,
  });

  String get _name =>
      profile?.name.isNotEmpty == true ? profile!.name : artistName;

  String get _image =>
      profile?.imageUrl.isNotEmpty == true ? profile!.imageUrl : artistImage;

  /// Followers, then genres — the two facts the endpoint actually gives us.
  /// (The old header claimed a hardcoded monthly-listener count.)
  String get _subtitle {
    final parts = <String>[];
    final followers = profile?.followers ?? 0;
    if (followers > 0) {
      parts.add('${ArtistProfile.formatCount(followers)} followers');
    }
    final genres = profile?.genres ?? const <String>[];
    if (genres.isNotEmpty) parts.add(genres.take(3).join(' • '));
    return parts.join('   ·   ');
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dominantColor, const Color(0xFF121212)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        context.pagePadding,
        wide ? 40 : 64,
        context.pagePadding,
        24,
      ),
      child: wide ? _wide(context) : _compact(context),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Artwork(imageUrl: _image, size: 208),
        const SizedBox(width: 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (profile?.isVerified == true) ...[
                const _VerifiedLabel(),
                const SizedBox(height: 10),
              ],
              Text(
                _name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _nameSize(context),
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              if (_subtitle.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  _subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
                ),
              ],
              const SizedBox(height: 20),
              _Actions(onPlay: onPlay, onShuffle: onShuffle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compact(BuildContext context) {
    return Column(
      children: [
        _Artwork(imageUrl: _image, size: 168),
        const SizedBox(height: 20),
        Text(
          _name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.6,
          ),
        ),
        if (_subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
          ),
        ],
        const SizedBox(height: 20),
        _Actions(onPlay: onPlay, onShuffle: onShuffle, centered: true),
      ],
    );
  }

  /// Long names get smaller type so they keep fitting on two lines.
  double _nameSize(BuildContext context) {
    final base = context.isExpanded ? 64.0 : 44.0;
    if (_name.length > 26) return base * 0.62;
    if (_name.length > 16) return base * 0.8;
    return base;
  }
}

class _VerifiedLabel extends StatelessWidget {
  const _VerifiedLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.verified, size: 18, color: Color(0xff4CB3FF)),
        SizedBox(width: 6),
        Text(
          'Verified artist',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _Artwork({required this.imageUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: frame == null ? _placeholder() : child,
                  );
                },
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF2A2A2A),
    child: Icon(Icons.person, size: size * 0.45, color: Colors.white38),
  );
}

class _Actions extends StatelessWidget {
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final bool centered;

  const _Actions({this.onPlay, this.onShuffle, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        _PlayButton(onTap: onPlay),
        const SizedBox(width: 16),
        Tooltip(
          message: 'Shuffle popular tracks',
          child: IconButton(
            onPressed: onShuffle,
            icon: const Icon(Icons.shuffle),
            iconSize: 26,
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatefulWidget {
  final VoidCallback? onTap;

  const _PlayButton({this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          // Grows slightly under the pointer, the one bit of feedback a
          // desktop user gets before clicking.
          scale: _hovered && enabled ? 1.06 : 1,
          duration: const Duration(milliseconds: 140),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? const Color(0xff1BD760) : const Color(0x331BD760),
            ),
            child: const Icon(Icons.play_arrow, size: 32, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
