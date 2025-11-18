import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/presentation/common/utils/responsive_layout_helper.dart';
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
    final responsive = ResponsiveLayoutHelper(context);
    final shouldUseVertical = responsive.shouldUseVerticalNavBar();
    final shouldScaleDown = responsive.shouldScaleDown();
    final scaleFactor = responsive.getScaleFactor();

    return Scaffold(
      body: Row(
        children: [
          if (shouldUseVertical)
            _buildVerticalNavBar(context, responsive, scaleFactor),
          Expanded(
            child: FadeTransition(
              opacity: _pageAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _pageController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: IndexedStack(index: _selectedIndex, children: _pages),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          shouldUseVertical
              ? null
              : AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    type: BottomNavigationBarType.fixed,
                    iconSize: responsive.getIconSize(baseSize: 24),
                    selectedFontSize: responsive.getFontSize(baseSize: 12),
                    unselectedFontSize: responsive.getFontSize(baseSize: 12),
                    showSelectedLabels: !shouldScaleDown,
                    showUnselectedLabels: !shouldScaleDown,
                    items: [
                      BottomNavigationBarItem(
                        icon: AnimatedScale(
                          scale: _selectedIndex == 0 ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CupertinoIcons.scribble,
                            size: responsive.getIconSize(baseSize: 24),
                          ),
                        ),
                        label: 'Scribble',
                      ),
                      BottomNavigationBarItem(
                        icon: AnimatedScale(
                          scale: _selectedIndex == 1 ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            CupertinoIcons.list_bullet,
                            size: responsive.getIconSize(baseSize: 24),
                          ),
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

  Widget _buildVerticalNavBar(
    BuildContext context,
    ResponsiveLayoutHelper responsive,
    double scaleFactor,
  ) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onNavTap,
      labelType:
          responsive.isSmallScreen
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.selected,
      minWidth: responsive.isSmallScreen ? 56 : 72,
      leading: const SizedBox.shrink(),
      trailing: const SizedBox.shrink(),
      destinations: [
        NavigationRailDestination(
          icon: AnimatedScale(
            scale: _selectedIndex == 0 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              CupertinoIcons.scribble,
              size: responsive.getIconSize(baseSize: 24),
            ),
          ),
          selectedIcon: Icon(
            CupertinoIcons.scribble,
            size: responsive.getIconSize(baseSize: 24),
          ),
          label: Text(
            'Scribble',
            style: TextStyle(fontSize: responsive.getFontSize(baseSize: 12)),
          ),
        ),
        NavigationRailDestination(
          icon: AnimatedScale(
            scale: _selectedIndex == 1 ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              CupertinoIcons.list_bullet,
              size: responsive.getIconSize(baseSize: 24),
            ),
          ),
          selectedIcon: Icon(
            CupertinoIcons.list_bullet,
            size: responsive.getIconSize(baseSize: 24),
          ),
          label: Text(
            'History',
            style: TextStyle(fontSize: responsive.getFontSize(baseSize: 12)),
          ),
        ),
      ],
    );
  }
}
