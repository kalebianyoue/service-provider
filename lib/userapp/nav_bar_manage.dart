import 'package:flutter/material.dart';
import 'package:serviceprovider/userapp/activity_page.dart';
import 'package:serviceprovider/userapp/accountpage.dart';
import 'package:serviceprovider/userapp/agendapage.dart';
import 'package:serviceprovider/userapp/chat_screen.dart';
import 'package:serviceprovider/userapp/joblist.dart';



class NavBarManage extends StatefulWidget {
  const NavBarManage({super.key});

  @override
  State<NavBarManage> createState() => _NavBarManageState();
}

class _NavBarManageState extends State<NavBarManage> {


  List pages  = [
    ActivityPage(),
    Joblist(),
    AgendaPage(),
    ChatScreen(),
    AccountPage(),
  ];

  int currentIndex = 0;
  void changepage(int index){
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: changepage,
        items:  [
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "Activity",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: "Job List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Account",
          ),
        ],
      ),
    );
  }
}
