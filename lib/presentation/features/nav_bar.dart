import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'scribble/scribble_page.dart';
import 'gallery/gallery_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _selectedIndex = 0;

  final _pages = [const ScribblePage(), const GalleryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ), //to keep state of each page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.scribble),
            label: 'Scribble',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'History',
          ),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
