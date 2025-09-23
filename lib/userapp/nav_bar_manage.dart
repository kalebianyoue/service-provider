import 'package:flutter/material.dart';
import 'package:serviceprovider/userapp/activity_page.dart';
import 'package:serviceprovider/userapp/accountpage.dart';
import 'package:serviceprovider/userapp/agendapage.dart';
import 'package:serviceprovider/userapp/chat_list.dart';
import 'package:serviceprovider/userapp/joblist.dart';

class NavBarManage extends StatefulWidget {
  const NavBarManage({super.key});

  @override
  State<NavBarManage> createState() => _NavBarManageState();
}

class _NavBarManageState extends State<NavBarManage> {
  // Pages pour chaque onglet
  final List<Widget> _pages = [
    const BookingListPage(),
    const Joblist(),
    const AgendaPage(),
    ChatList(),
    const ManageAccountPage(),
  ];

  int _currentIndex = 0;

  void _changePage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Affiche la page correspondante à l'onglet sélectionné
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        onTap: _changePage,
        elevation: 8, // ajoute une ombre subtile
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: "Job List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Account",
          ),
        ],
      ),
    );
  }
}
