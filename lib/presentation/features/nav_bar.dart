import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'scribble/scribble_page.dart';
import 'gallery/gallery_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;

  final _pages = [const ScribblePage(), const GalleryPage()];

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index != _selectedIndex) {
      _pageController.reset();
      setState(() => _selectedIndex = index);
      _pageController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _pageAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: _pageController, curve: Curves.easeOutCubic),
          ),
          child: IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),
        ),
      ), //to keep state of each page
      bottomNavigationBar: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _selectedIndex == 0 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(CupertinoIcons.scribble),
                ),
                label: 'Scribble',
              ),
              BottomNavigationBarItem(
                icon: AnimatedScale(
                  scale: _selectedIndex == 1 ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(CupertinoIcons.list_bullet),
                ),
                label: 'History',
              ),
            ],
            onTap: _onNavTap,
          );
        },
      ),
    );
  }
}
