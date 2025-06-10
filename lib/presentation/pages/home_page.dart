import 'package:flutter/material.dart';
import 'scribble/scribble_page.dart';
import 'gallery/gallery_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final _pages = [const ScribblePage(), const GalleryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Scribble'),
          BottomNavigationBarItem(icon: Icon(Icons.image), label: 'History'),
        ],
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
