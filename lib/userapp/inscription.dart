import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceprovider/userapp/connexion.dart';

class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _acceptTerms = false;

  // List of major Cameroonian cities
  final List<String> _cities = [
    'Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua', 'Bafoussam',
    'Ngaoundéré', 'Bertoua', 'Kribi', 'Buea', 'Other'
  ];
  String? _selectedCity;

  // Gender options
  final List<String> _genders = ['Male', 'Female'];
  String? _selectedGender;

  // Service categories
  final List<String> _serviceCategories = [
    'Cleaning',
    'Plumbing',
    'Electricity',
    'Gardening',
    'Painting',
    'Carpentry',
    'Mechanics',
    'IT Services',
    'Cooking',
    'Repairs',
    'Construction',
    'Moving',
    'Home Care',
    'Tutoring',
    'Other'
  ];
  String? _selectedServiceCategory;

  // Experience levels
  final List<String> _experienceLevels = [
    'Beginner (0-1 year)',
    'Intermediate (1-3 years)',
    'Experienced (3-5 years)',
    'Expert (5+ years)'
  ];
  String? _selectedExperienceLevel;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedCity == null || _selectedGender == null ||
        _selectedServiceCategory == null || _selectedExperienceLevel == null) {
      setState(() => _errorMessage = "Please fill all required fields.");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    if (!_acceptTerms) {
      setState(() => _errorMessage = "Please accept the terms and conditions.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Create Firebase Authentication account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;

      // Prepare data for "provider" collection
      final providerData = {
        // Personal information
        "uid": user.uid,
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "gender": _selectedGender,
        "city": _selectedCity,
        "birthDate": _selectedDate?.toIso8601String(),

        // Professional information
        "serviceCategory": _selectedServiceCategory,
        "experienceLevel": _selectedExperienceLevel,
        "yearsOfExperience": "",

        // Metadata and statistics
        "rating": 0.0,
        "totalRatings": 0,
        "completedJobs": 0,
        "pendingJobs": 0,
        "isVerified": false,
        "isAvailable": true,
        "isOnline": false,

        // Documents and portfolio
        "profileImage": "",
        "portfolioImages": [],
        "certificates": [],
        "identificationDocuments": [],

        // Bank details
        "bankAccount": {
          "accountNumber": "",
          "accountName": "",
          "bankName": "",
          "isVerified": false
        },

        // Location
        "location": {
          "latitude": 0.0,
          "longitude": 0.0,
          "address": ""
        },

        // Working preferences
        "workingHours": {
          "start": "08:00",
          "end": "18:00",
          "days": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        },

        // Timestamps
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "lastLogin": FieldValue.serverTimestamp(),

        // Status
        "status": "active",
        "profileCompletion": 70,
        "subscriptionType": "free",

        // Social media
        "socialMedia": {
          "whatsapp": _phoneController.text.trim(),
          "facebook": "",
          "instagram": ""
        },

        // Notification settings
        "notifications": {
          "emailNotifications": true,
          "smsNotifications": true,
          "pushNotifications": true,
          "jobAlerts": true
        }
      };

      // Save to "provider" collection
      await FirebaseFirestore.instance
          .collection("provider")
          .doc(user.uid)
          .set(providerData);

      // ✅ Redirect to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Provider account created successfully 🎉"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case "email-already-in-use":
          msg = "This email is already used by a provider.";
          break;
        case "invalid-email":
          msg = "Invalid email address.";
          break;
        case "weak-password":
          msg = "Password is too weak (min. 6 characters).";
          break;
        case "operation-not-allowed":
          msg = "Registration is not allowed at this time.";
          break;
        default:
          msg = "Authentication error: ${e.message}";
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = "An error occurred: ${e.toString()}");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Provider Registration",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.work_outline, size: 60, color: Colors.blue),
                const SizedBox(height: 10),
                const Text("Become a Provider",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                const SizedBox(height: 5),
                const Text("Create your professional account",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                // Personal Information
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Personal Information",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(label: "Full Name*", icon: Icons.person),
                  validator: (v) => v!.isEmpty ? "Please enter your name" : null,
                ),
                const SizedBox(height: 15),

                // Gender
                _buildDropdownField(
                  label: "Gender*",
                  icon: Icons.person_outline,
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 15),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(label: "Phone Number*", icon: Icons.phone),
                  validator: (v) => v!.length < 9 ? "Invalid phone number" : null,
                ),
                const SizedBox(height: 15),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(label: "Email*", icon: Icons.email),
                  validator: (v) =>
                  v != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v) ? null : "Invalid email",
                ),
                const SizedBox(height: 15),

                // Date of Birth
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration(label: "Date of Birth*", icon: Icons.calendar_today),
                  validator: (v) => v!.isEmpty ? "Please select your date of birth" : null,
                ),
                const SizedBox(height: 15),

                // City
                _buildDropdownField(
                  label: "City*",
                  icon: Icons.location_city,
                  value: _selectedCity,
                  items: _cities,
                  onChanged: (val) => setState(() => _selectedCity = val),
                ),
                const SizedBox(height: 25),

                // Professional Information
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Professional Information",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),

                // Service Category
                _buildDropdownField(
                  label: "Service Category*",
                  icon: Icons.work,
                  value: _selectedServiceCategory,
                  items: _serviceCategories,
                  onChanged: (val) => setState(() => _selectedServiceCategory = val),
                ),
                const SizedBox(height: 15),

                // Experience Level
                _buildDropdownField(
                  label: "Experience Level*",
                  icon: Icons.timeline,
                  value: _selectedExperienceLevel,
                  items: _experienceLevels,
                  onChanged: (val) => setState(() => _selectedExperienceLevel = val),
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration(label: "Password*", icon: Icons.lock),
                  validator: (v) => v != null && v.length >= 6 ? null : "Minimum 6 characters",
                ),
                const SizedBox(height: 15),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration(label: "Confirm Password*", icon: Icons.lock_outline),
                  validator: (v) => v != _passwordController.text ? "Passwords do not match" : null,
                ),
                const SizedBox(height: 20),

                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      activeColor: Colors.blue,
                    ),
                    const Expanded(
                      child: Text(
                        "I accept the terms and conditions and privacy policy*",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Error display
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMessage!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Register button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, size: 20),
                        SizedBox(width: 10),
                        Text("Create Provider Account",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: _loading ? null : () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Connexion()),
                      ),
                      child: const Text("Login",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // === Helpers ===
  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return InputDecorator(
      decoration: _inputDecoration(label: label, icon: icon),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text("Select $label"),
          items: items.map((item) =>
              DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 16)),
              )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}