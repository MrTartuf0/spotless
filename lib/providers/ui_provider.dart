import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which of the three tabs is showing.
///
/// This lives outside the widget tree because the navigation control (the
/// sidebar on desktop, the bottom bar on mobile) sits in the app frame while
/// the tabs themselves are rendered by the router's child.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Whether the docked queue panel is open. Only consulted on wide windows —
/// narrow ones open the queue as a sheet instead.
final queuePanelOpenProvider = StateProvider<bool>((ref) => false);
