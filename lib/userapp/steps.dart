import 'package:flutter/material.dart';
import 'package:serviceprovider/userapp/auth_page.dart';
import 'package:serviceprovider/userapp/sign_up_page.dart';


void main() {
  runApp(const Steps());
}

class Steps extends StatelessWidget {
  const Steps({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'On Work Quoi PRO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'San Francisco',
      ),
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status bar spacer
                const SizedBox(height: 20),

                // Yoojo logo
                const Text(
                  'On Work Quoi PRO',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 60),

                // Service categories grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3.5,
                    children: [
                      _ServiceCategory(
                        icon: Icons.build_outlined,
                        title: 'DIY',
                        color: const Color(0xFFF5F5F5),
                      ),
                      _ServiceCategory(
                        icon: Icons.pets_outlined,
                        title: 'Animals',
                        color: const Color(0xFFE8F5E8),
                      ),
                      _ServiceCategory(
                        icon: Icons.local_florist_outlined,
                        title: 'Gardening',
                        color: const Color(0xFFE8F5E8),
                      ),
                      _ServiceCategory(
                        icon: Icons.child_care_outlined,
                        title: 'Childcare',
                        color: const Color(0xFFFCE4EC),
                      ),
                      _ServiceCategory(
                        icon: Icons.cleaning_services_outlined,
                        title: 'Housekeeping',
                        color: const Color(0xFFE0F2F1),
                      ),
                      _ServiceCategory(
                        icon: Icons.computer_outlined,
                        title: 'IT',
                        color: const Color(0xFFE3F2FD),
                      ),
                      _ServiceCategory(
                        icon: Icons.local_shipping_outlined,
                        title: 'Moving',
                        color: const Color(0xFFFFEBEE),
                      ),
                      _ServiceCategory(
                        icon: Icons.school_outlined,
                        title: 'Tutoring',
                        color: const Color(0xFFF3E5F5),
                      ),
                      _ServiceCategory(
                        icon: Icons.home_outlined,
                        title: 'Homecare',
                        color: const Color(0xFFFFEBEE),
                        isWide: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome text
                const Text(
                  'Welcome to On Work Quoi PRO',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Join the #1 app for home service providers and\nstart increasing your income.',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 50),

                // Get Started button
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, 
                      MaterialPageRoute(builder: (context) => SignUpPage())
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCategory extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isWide;

  const _ServiceCategory({
    required this.icon,
    required this.title,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}