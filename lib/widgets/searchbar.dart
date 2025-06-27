import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

class Searchbar extends StatefulWidget {
  const Searchbar({super.key});

  @override
  State<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends State<Searchbar> {
  final TextEditingController _textController = TextEditingController();
  bool _showCloseButton = false;

  @override
  void initState() {
    super.initState();
    // Listen to text changes
    _textController.addListener(() {
      setState(() {
        _showCloseButton = _textController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _clearText() {
    _textController.clear();
    // The listener will automatically update _showCloseButton to false
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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

          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
              decoration: InputDecoration(
                hintText: 'What do you want to listen to?',
                hintStyle: TextStyle(letterSpacing: -0.2, color: Colors.black),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Clear/close button (conditionally shown)
          if (_showCloseButton)
            GestureDetector(
              onTap: _clearText,
              child: Icon(Icons.close, size: 24),
            ),
        ],
      ),
    );
  }
}
