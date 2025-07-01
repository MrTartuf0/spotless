import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global state for search functionality
final searchStateProvider =
    StateNotifierProvider<SearchStateNotifier, SearchState>((ref) {
      return SearchStateNotifier();
    });

class SearchState {
  final bool isActive;
  final bool hasText;
  final bool isKeyboardVisible;

  const SearchState({
    this.isActive = false,
    this.hasText = false,
    this.isKeyboardVisible = false,
  });

  SearchState copyWith({
    bool? isActive,
    bool? hasText,
    bool? isKeyboardVisible,
  }) {
    return SearchState(
      isActive: isActive ?? this.isActive,
      hasText: hasText ?? this.hasText,
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
    );
  }
}

class SearchStateNotifier extends StateNotifier<SearchState> {
  SearchStateNotifier() : super(const SearchState());

  void setActive(bool isActive) {
    state = state.copyWith(isActive: isActive);
  }

  void setHasText(bool hasText) {
    state = state.copyWith(hasText: hasText);
  }

  void setKeyboardVisible(bool isVisible) {
    state = state.copyWith(isKeyboardVisible: isVisible);
  }

  void reset() {
    state = const SearchState();
  }
}
