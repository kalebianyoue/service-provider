import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  // Dropdown values
  String? _selectedCity;
  String? _selectedGender;
  String? _selectedServiceCategory;
  String? _selectedExperienceLevel;

  final List<String> _cities = [
    'Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua', 'Bafoussam',
    'Ngaoundéré', 'Bertoua', 'Kribi', 'Buea', 'Other'
  ];

  final List<String> _genders = ['Male', 'Female'];

  final List<String> _serviceCategories = [
    'Cleaning', 'Plumbing', 'Electricity', 'Gardening', 'Painting',
    'Carpentry', 'Mechanics', 'IT Services', 'Cooking', 'Repairs',
    'Construction', 'Moving', 'Home Care', 'Tutoring', 'Other'
  ];

  final List<String> _experienceLevels = [
    'Beginner (0-1 year)',
    'Intermediate (1-3 years)',
    'Experienced (3-5 years)',
    'Expert (5+ years)'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      _user = _auth.currentUser;
      if (_user != null) {
        await _fetchUserData();
      }
    } catch (e) {
      print('Error getting current user: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      // Try to fetch from provider collection first
      DocumentSnapshot providerDoc = await _firestore
          .collection('provider')
          .doc(_user!.uid)
          .get();

      if (providerDoc.exists) {
        setState(() {
          _userData = providerDoc.data() as Map<String, dynamic>;
          _populateControllers();
        });
      } else {
        // If not in provider, try users collection
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(_user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _populateControllers();
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _populateControllers() {
    _nameController.text = _userData['name'] ?? '';
    _phoneController.text = _userData['phone'] ?? '';
    _emailController.text = _userData['email'] ?? _user?.email ?? '';
    _experienceController.text = _userData['yearsOfExperience'] ?? '';

    _selectedCity = _userData['city'];
    _selectedGender = _userData['gender'];
    _selectedServiceCategory = _userData['serviceCategory'];
    _selectedExperienceLevel = _userData['experienceLevel'];
  }

  Future<void> _saveChanges() async {
    try {
      final updatedData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity,
        'gender': _selectedGender,
        'serviceCategory': _selectedServiceCategory,
        'experienceLevel': _selectedExperienceLevel,
        'yearsOfExperience': _experienceController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Determine which collection to update
      String collectionName = 'provider';
      DocumentReference userDoc = _firestore.collection(collectionName).doc(_user!.uid);

      // Check if document exists in provider collection
      DocumentSnapshot docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        collectionName = 'users';
        userDoc = _firestore.collection(collectionName).doc(_user!.uid);
      }

      await userDoc.update(updatedData);

      // Update Firebase Auth display name
      if (_nameController.text.isNotEmpty) {
        await _user!.updateDisplayName(_nameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _isEditing = false);
      await _fetchUserData(); // Refresh data

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleEditMode() {
    if (_isEditing) {
      _saveChanges();
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _cancelEdit() {
    _populateControllers(); // Reset to original values
    setState(() => _isEditing = false);
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required TextEditingController controller,
    required bool isEditing,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        isEditing
            ? TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        )
            : Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value.isNotEmpty ? value : 'Not set'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEditableDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required bool isEditing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        isEditing
            ? DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        )
            : Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value ?? 'Not set'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? "Edit Profile" : "Manage Account",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: _isEditing
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _cancelEdit,
        )
            : null,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.black87),
              onPressed: _toggleEditMode,
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userData['name'] ?? 'User',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userData['email'] ?? _user?.email ?? '',
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'User Type: ${_userData['userType'] ?? 'provider'}',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Personal Information Section
            const Text(
              "Personal Information",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildEditableField(
              label: "Full Name",
              value: _userData['name'] ?? '',
              controller: _nameController,
              isEditing: _isEditing,
            ),

            _buildEditableField(
              label: "Email",
              value: _userData['email'] ?? _user?.email ?? '',
              controller: _emailController,
              isEditing: _isEditing,
              keyboardType: TextInputType.emailAddress,
            ),

            _buildEditableField(
              label: "Phone Number",
              value: _userData['phone'] ?? '',
              controller: _phoneController,
              isEditing: _isEditing,
              keyboardType: TextInputType.phone,
            ),

            _buildEditableDropdown(
              label: "Gender",
              value: _selectedGender,
              items: _genders,
              onChanged: (value) => setState(() => _selectedGender = value),
              isEditing: _isEditing,
            ),

            _buildEditableDropdown(
              label: "City",
              value: _selectedCity,
              items: _cities,
              onChanged: (value) => setState(() => _selectedCity = value),
              isEditing: _isEditing,
            ),

            // Professional Information (for providers)
            if (_userData['serviceCategory'] != null || _isEditing) ...[
              const SizedBox(height: 24),
              const Text(
                "Professional Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildEditableDropdown(
                label: "Service Category",
                value: _selectedServiceCategory,
                items: _serviceCategories,
                onChanged: (value) => setState(() => _selectedServiceCategory = value),
                isEditing: _isEditing,
              ),

              _buildEditableDropdown(
                label: "Experience Level",
                value: _selectedExperienceLevel,
                items: _experienceLevels,
                onChanged: (value) => setState(() => _selectedExperienceLevel = value),
                isEditing: _isEditing,
              ),

              _buildEditableField(
                label: "Years of Experience",
                value: _userData['yearsOfExperience'] ?? '',
                controller: _experienceController,
                isEditing: _isEditing,
                keyboardType: TextInputType.number,
              ),
            ],

            // Account Statistics
            const SizedBox(height: 24),
            const Text(
              "Account Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatItem("Rating", "${_userData['rating'] ?? 0.0}"),
                    _buildStatItem("Completed Jobs", "${_userData['completedJobs'] ?? 0}"),
                    _buildStatItem("Pending Jobs", "${_userData['pendingJobs'] ?? 0}"),
                    _buildStatItem("Status", _userData['status'] ?? 'active'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (_isEditing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    super.dispose();
  }
}