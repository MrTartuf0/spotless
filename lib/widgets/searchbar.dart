import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:rick_spot/providers/search_result_provider.dart';
import 'package:rick_spot/providers/searchbar_provider.dart';
import 'dart:async';

// Debug logging
void _debug(String message) {
  print("SEARCH_DEBUG: $message");
}

class Searchbar extends ConsumerStatefulWidget {
  const Searchbar({Key? key}) : super(key: key);

  @override
  SearchbarState createState() => SearchbarState();
}

class SearchbarState extends ConsumerState<Searchbar> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _debug("SearchBar initState called");

    // Listen to text changes
    _textController.addListener(() {
      final hasText = _textController.text.isNotEmpty;
      _debug("Text changed: '${_textController.text}', hasText=$hasText");
      ref.read(searchStateProvider.notifier).setHasText(hasText);

      // Debounce search queries
      if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 300), () {
        // Execute search
        ref.read(searchResultsProvider.notifier).search(_textController.text);
      });
    });

    // Listen to focus changes
    _focusNode.addListener(() {
      _debug("Focus changed: hasFocus=${_focusNode.hasFocus}");
      ref.read(searchStateProvider.notifier).setActive(_focusNode.hasFocus);

      // Update keyboard visibility when focus changes
      if (_focusNode.hasFocus) {
        ref.read(searchStateProvider.notifier).setKeyboardVisible(true);
      }
    });
  }

  @override
  void dispose() {
    _debug("SearchBar dispose called");
    _textController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Focus and show keyboard
  void activateSearch() {
    _debug("activateSearch called");

    // Set active state first
    ref.read(searchStateProvider.notifier).setActive(true);

    // Set keyboard visible
    ref.read(searchStateProvider.notifier).setKeyboardVisible(true);

    // Request focus
    _debug("Requesting focus");
    FocusScope.of(context).requestFocus(_focusNode);

    // Force keyboard to show
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _debug("Forcing keyboard to show");
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  // Unfocus without changing state
  void unfocusWithoutStateChange() {
    _debug("unfocusWithoutStateChange called");
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _focusNode.unfocus();

    // Set keyboard not visible
    ref.read(searchStateProvider.notifier).setKeyboardVisible(false);
  }

  // Clear text and reset everything
  void reset() {
    _debug("reset called");
    _textController.clear();
    unfocusWithoutStateChange();
    ref.read(searchStateProvider.notifier).reset();
    ref.read(searchResultsProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);

    _debug(
      "Building searchbar - isActive=${searchState.isActive}, hasText=${searchState.hasText}",
    );

    return Container(
      color:
          searchState.isActive || searchState.hasText
              ? Color(0xff181818)
              : Colors.transparent,
      padding:
          searchState.isActive || searchState.hasText
              ? EdgeInsets.all(16)
              : EdgeInsets.zero,
      child: Row(
        children: [
          // Back arrow
          if (searchState.isActive || searchState.hasText) ...[
            GestureDetector(
              onTap: reset,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SvgPicture.asset(
                  'assets/icons/back_arrow.svg',
                  color: Colors.white,
                ),
              ),
            ),
          ],

          // Search container
          Expanded(
            child: GestureDetector(
              onTap: activateSearch,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Search icon
                    SvgPicture.asset('assets/icons/search.svg'),
                    Gap(8),

                    // Text field - using a simpler, more direct approach
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          letterSpacing: -0.2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What do you want to listen to?',
                          hintStyle: TextStyle(
                            letterSpacing: -0.2,
                            color: Colors.black,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          _debug("TextField tapped directly");
                          activateSearch();
                        },
                      ),
                    ),

                    // Clear button
                    if (searchState.hasText)
                      GestureDetector(
                        onTap: () {
                          _debug("Clear button tapped");
                          _textController.clear();
                          activateSearch(); // Refocus after clearing
                          ref
                              .read(searchResultsProvider.notifier)
                              .clearSearch();
                        },
                        child: Icon(Icons.close, size: 24),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
