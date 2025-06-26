import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../auth/presentation/bloc/auth_bloc.dart';
import '../lfg/lfg_page.dart';
import '../friends/friends_page.dart';
import '../home/home_page.dart';
import '../fellowships/presentation/pages/fellowships_page.dart';
import '../profile/for_me_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Start with Camera (home) page

  @override
  Widget build(BuildContext context) {
    // Get the AuthBloc from the context to pass it down
    final authBloc = context.read<AuthBloc>();

    final List<Widget> pages = [
      BlocProvider.value(value: authBloc, child: const LfgPage()),
      BlocProvider.value(value: authBloc, child: const FriendsPage()),
      BlocProvider.value(value: authBloc, child: const HomePage()),
      BlocProvider.value(value: authBloc, child: const FellowshipsPage()),
      BlocProvider.value(value: authBloc, child: const ForMePage()),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          border: Border(
            top: BorderSide(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundColor,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          iconSize: 28,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.group_add_outlined),
              activeIcon: Icon(Icons.group_add),
              label: 'LFG',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Fellowships',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'For Me',
            ),
          ],
        ),
      ),
    );
  }
}
