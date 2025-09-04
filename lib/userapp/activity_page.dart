import 'package:flutter/material.dart';
import 'package:serviceprovider/userapp/joblist.dart';


class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Coming soon", "Passed"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Activity',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Switch
          Row(
            children: List.generate(_tabs.length, (index) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTabIndex == index
                              ? Colors.blue
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      _tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: _selectedTabIndex == index
                            ? Colors.blue
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Content
          Expanded(
            child: Center(
              child: _selectedTabIndex == 0
                  ? _buildComingSoon()
                  : _buildPassed(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_today, size: 100, color: Colors.blue),
        const SizedBox(height: 20),
        const Text(
          "No job planned for the near future",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          "Check back later or browse available jobs.",
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            // Navigate to JobList page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Joblist()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(160, 48),
          ),
          child: const Text("Find jobs"),
        ),
      ],
    );
  }

  Widget _buildPassed() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.history, size: 100, color: Colors.grey),
        SizedBox(height: 20),
        Text(
          "No past jobs found",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "Your past jobs will appear here once completed.",
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}
