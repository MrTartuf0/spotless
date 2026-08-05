import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spotACrack/providers/audio_player/audio_player_provider.dart';
import 'package:spotACrack/providers/history_provider.dart';
import 'package:spotACrack/providers/ui_provider.dart';
import 'package:spotACrack/screens/app_shell.dart';
import 'package:spotACrack/services/history_service.dart';

/// Desktop navigation: destinations up top, recently played underneath.
///
/// [collapsed] drops the labels and the recents list, leaving an icon rail —
/// used on medium windows where a full sidebar would crowd the content.
class SideNav extends ConsumerWidget {
  final bool collapsed;

  const SideNav({super.key, this.collapsed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final atRoot = GoRouterState.of(context).uri.path == '/';

    return Container(
      width: collapsed ? 76 : 232,
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(collapsed: collapsed),
          const SizedBox(height: 12),
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            // A pushed album still belongs to the tab you opened it from, but
            // nothing should look "current" while it is covering the tab.
            selected: atRoot && selected == 0,
            collapsed: collapsed,
            onTap: () => AppShell.selectTab(context, ref, 0),
          ),
          _NavItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: 'Search',
            selected: atRoot && selected == 1,
            collapsed: collapsed,
            onTap: () => AppShell.selectTab(context, ref, 1),
          ),
          _NavItem(
            icon: Icons.library_music_outlined,
            activeIcon: Icons.library_music,
            label: 'Your library',
            selected: atRoot && selected == 2,
            collapsed: collapsed,
            onTap: () => AppShell.selectTab(context, ref, 2),
          ),
          if (!collapsed) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Recently played',
                style: TextStyle(
                  color: Color(0x8AFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Expanded(child: _Recents()),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool collapsed;

  const _Header({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // Back is the only history control the shell navigator supports;
          // there is no forward stack to walk once a page has been popped.
          IconButton(
            onPressed: canPop ? () => context.pop() : null,
            icon: const Icon(Icons.arrow_back, size: 20),
            color: Colors.white,
            disabledColor: Colors.white24,
            tooltip: 'Back',
            splashRadius: 18,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 4),
            const Flexible(
              child: Text(
                'spotACrack',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Recents extends ConsumerWidget {
  const _Recents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks =
        ref.watch(recentTracksProvider).valueOrNull ?? const <RecentTrack>[];

    if (tracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'Nothing played yet',
          style: TextStyle(color: Color(0x55FFFFFF), fontSize: 12.5),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: tracks.length,
      itemBuilder: (context, i) {
        final track = tracks[i];
        return InkWell(
          onTap: () =>
              ref.read(audioPlayerProvider.notifier).loadTrack(track.id),
          borderRadius: BorderRadius.circular(6),
          hoverColor: Colors.white.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: track.imageUrl.startsWith('http')
                      ? Image.network(
                          track.imageUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0x8AFFFFFF),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 36,
    height: 36,
    color: const Color(0xFF262626),
    child: const Icon(Icons.music_note, color: Colors.white38, size: 16),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xB3FFFFFF);

    final content = Row(
      mainAxisAlignment:
          collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Icon(selected ? activeIcon : icon, color: color, size: 23),
        if (!collapsed) ...[
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 14.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 8 : 12,
            vertical: 11,
          ),
          child: collapsed ? Tooltip(message: label, child: content) : content,
        ),
      ),
    );
  }
}
