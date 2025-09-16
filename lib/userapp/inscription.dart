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
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  bool _isProvider = false;

  // List of major Cameroonian cities
  final List<String> _cities = [
    'Yaoundé', 'Douala', 'Garoua', 'Bamenda', 'Maroua', 'Bafoussam',
    'Ngaoundéré', 'Bertoua', 'Kribi', 'Buea', 'Autre'
  ];
  String? _selectedCity;

  // Gender options
  final List<String> _genders = ['Homme', 'Femme'];
  String? _selectedGender;

  // Service categories
  final List<String> _serviceCategories = [
    'Nettoyage',
    'Plomberie',
    'Électricité',
    'Jardinage',
    'Peinture',
    'Menuiserie',
    'Mécanique',
    'Informatique',
    'Cuisine',
    'Autre'
  ];
  String? _selectedServiceCategory;

  // Experience levels
  final List<String> _experienceLevels = [
    'Débutant (0-1 an)',
    'Intermédiaire (1-3 ans)',
    'Expérimenté (3-5 ans)',
    'Expert (5+ ans)'
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
    if (_selectedDate == null || _selectedCity == null || _selectedGender == null) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs obligatoires.");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Les mots de passe ne correspondent pas.");
      return;
    }
    if (_isProvider && (_selectedServiceCategory == null || _selectedExperienceLevel == null)) {
      setState(() => _errorMessage = "Veuillez remplir les informations de prestataire.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Créer compte Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;
      final userData = {
        "uid": user.uid,
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "gender": _selectedGender,
        "city": _selectedCity,
        "birthDate": _selectedDate?.toIso8601String(),
        "userType": _isProvider ? "provider" : "client",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
        "status": "active",
        "profileCompleted": true,
      };

      // Sauvegarder infos dans la collection appropriée
      if (_isProvider) {
        // Enregistrer dans la collection "providers"
        final providerData = {
          ...userData,
          "serviceCategory": _selectedServiceCategory,
          "experienceLevel": _selectedExperienceLevel,
          "skills": _skillsController.text.trim().isNotEmpty
              ? _skillsController.text.trim().split(',').map((e) => e.trim()).toList()
              : [],
          "yearsOfExperience": _experienceController.text.trim(),
          "rating": 0.0,
          "totalRatings": 0,
          "completedJobs": 0,
          "isVerified": false,
          "availability": true,
          "hourlyRate": 0.0,
          "description": "",
          "portfolioImages": [],
          "documents": [],
          "bankAccount": {
            "accountNumber": "",
            "accountName": "",
            "bankName": ""
          }
        };

        await FirebaseFirestore.instance
            .collection("providers")
            .doc(user.uid)
            .set(providerData);
      } else {
        // Enregistrer dans la collection "users"
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set(userData);
      }

      // ✅ Redirection vers Connexion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Connexion()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isProvider
              ? "Compte prestataire créé avec succès 🎉"
              : "Compte client créé avec succès 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case "email-already-in-use":
          msg = "Cet email est déjà utilisé.";
          break;
        case "invalid-email":
          msg = "Adresse email invalide.";
          break;
        case "weak-password":
          msg = "Le mot de passe est trop faible.";
          break;
        default:
          msg = "Erreur: ${e.message}";
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = "Une erreur s'est produite: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // --- TITRE ---
                const SizedBox(height: 20),
                const Text("Créer un compte",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),

                const SizedBox(height: 30),

                // Switch pour type de compte
                Row(
                  children: [
                    const Text("Je suis un prestataire de service",
                        style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Switch(
                      value: _isProvider,
                      onChanged: (value) => setState(() => _isProvider = value),
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nom
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(label: "Nom complet", icon: Icons.person),
                  validator: (v) => v!.isEmpty ? "Veuillez entrer votre nom" : null,
                ),
                const SizedBox(height: 20),

                // Genre
                _buildDropdownField(
                  label: "Genre",
                  icon: Icons.person_outline,
                  value: _selectedGender,
                  items: _genders,
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),
                const SizedBox(height: 20),

                // Téléphone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(label: "Numéro de téléphone", icon: Icons.phone),
                  validator: (v) => v!.length < 9 ? "Numéro invalide" : null,
                ),
                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(label: "Email", icon: Icons.email),
                  validator: (v) =>
                  v != null && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v) ? null : "Email invalide",
                ),
                const SizedBox(height: 20),

                // Date de naissance
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration(label: "Date de naissance", icon: Icons.calendar_today),
                  validator: (v) => v!.isEmpty ? "Veuillez choisir votre date de naissance" : null,
                ),
                const SizedBox(height: 20),

                // Ville
                _buildDropdownField(
                  label: "Ville",
                  icon: Icons.location_city,
                  value: _selectedCity,
                  items: _cities,
                  onChanged: (val) => setState(() => _selectedCity = val),
                ),
                const SizedBox(height: 20),

                // Champs spécifiques aux prestataires
                if (_isProvider) ...[
                  // Catégorie de service
                  _buildDropdownField(
                    label: "Catégorie de service",
                    icon: Icons.work,
                    value: _selectedServiceCategory,
                    items: _serviceCategories,
                    onChanged: (val) => setState(() => _selectedServiceCategory = val),
                  ),
                  const SizedBox(height: 20),

                  // Niveau d'expérience
                  _buildDropdownField(
                    label: "Niveau d'expérience",
                    icon: Icons.timeline,
                    value: _selectedExperienceLevel,
                    items: _experienceLevels,
                    onChanged: (val) => setState(() => _selectedExperienceLevel = val),
                  ),
                  const SizedBox(height: 20),

                  // Années d'expérience
                  TextFormField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                        label: "Années d'expérience",
                        icon: Icons.calendar_today
                    ),
                    validator: (v) => _isProvider && v!.isEmpty
                        ? "Veuillez entrer vos années d'expérience"
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Compétences
                  TextFormField(
                    controller: _skillsController,
                    decoration: _inputDecoration(
                        label: "Compétences (séparées par des virgules)",
                        icon: Icons.star
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                ],

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration(label: "Mot de passe", icon: Icons.lock),
                  validator: (v) => v != null && v.length >= 6 ? null : "Min 6 caractères",
                ),
                const SizedBox(height: 20),

                // Confirmer mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration(label: "Confirmer le mot de passe", icon: Icons.lock_outline),
                  validator: (v) => v != _passwordController.text ? "Les mots de passe ne correspondent pas" : null,
                ),
                const SizedBox(height: 20),

                // Affichage erreur
                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isProvider ? "Créer mon compte prestataire" : "Créer mon compte",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),

                // Déjà un compte ?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vous avez déjà un compte? "),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Connexion()),
                      ),
                      child: const Text("Se connecter", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
          hint: Text("Sélectionnez $label"),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
    _serviceTypeController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }
}