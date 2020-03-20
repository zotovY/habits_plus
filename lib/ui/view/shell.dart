import 'package:flutter/material.dart';
import 'package:habits_plus/core/models/userData.dart';
import 'package:habits_plus/core/viewmodels/home_model.dart';
import 'package:habits_plus/ui/view/home.dart';
import 'package:habits_plus/ui/widgets/shell_widget.dart';
import 'package:provider/provider.dart';

import '../../locator.dart';

class MainShell extends StatefulWidget {
  @override
  _MainShellState createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Page controll
  int _currentPage = 1;
  List<Widget> _pages = [
    Container(),
    HomePage(),
  ];
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    String userId = Provider.of<UserData>(context, listen: false).currentUserId;
    locator<HomeViewModel>().fetch(userId);
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ShellBottomBar(
        currentPage: _currentPage,
        onHomePressed: () => setState(() {
          _currentPage = 1;
          _pageController.jumpToPage(_currentPage);
        }),
        onStatisticPressed: () => setState(() {
          _currentPage = 0;
          _pageController.jumpToPage(_currentPage);
        }),
      ),
      body: SafeArea(
        child: PageView(
          children: _pages,
          controller: _pageController,
          onPageChanged: (int i) => setState(() => _currentPage = i),
        ),
      ),
    );
  }
}
