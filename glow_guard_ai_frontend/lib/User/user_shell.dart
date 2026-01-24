import 'package:flutter/material.dart';

import 'user_home_tab.dart';
import 'find_expert_tab.dart';
import 'research_tab.dart';
import 'chatbot_tab.dart';
import 'profile_tab.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  final _tabs = const [
    UserHomeTab(),
    FindExpertTab(),
    ResearchTab(),
    ChatbotTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: "Home"),
          NavigationDestination(icon: Icon(Icons.search_outlined), label: "Experts"),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: "Research"),
          NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: "Chatbot"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
