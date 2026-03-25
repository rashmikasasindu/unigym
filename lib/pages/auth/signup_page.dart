import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'email_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Text Controllers
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Service
  final _authService = AuthService();
  bool _isLoading = false;

  // Variables
  String? _selectedGender; 

  void _register() async {
    final name = _nameController.text.trim();
    final regNum = _regNumController.text.trim();
    final contact = _contactController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Check Empty Fields
    if (name.isEmpty || regNum.isEmpty || contact.isEmpty || 
        email.isEmpty || password.isEmpty || confirmPassword.isEmpty || 
        _selectedGender == null) {
      _showError("Please fill all fields and select gender");
      return;
    }

    // 2. Validate Registration Number (Must be EN followed by 6 digits)
    if (!RegExp(r'^EN\d{6}$').hasMatch(regNum)) {
      _showError("Registration number must be in format EN123456");
      return;
    }

    // 3. Validate Contact Number (Must be exactly 10 digits)
    if (!RegExp(r'^\d{10}$').hasMatch(contact)) {
      _showError("Contact number must be exactly 10 digits");
      return;
    }

    // 4. Validate Email Domain
    if (!email.endsWith('@foe.sjp.ac.lk')) {
      _showError("Email must belong to @foe.sjp.ac.lk domain");
      return;
    }

    // 5. Check Password Match
    if (password != confirmPassword) {
      _showError("Passwords do not match!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Register
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        regNum: regNum,
        gender: _selectedGender!,
        contact: contact, // Pass contact to your service
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmailVerificationPage(email: email),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll("Exception: ", ""));
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // Helper function to show snackbars easily
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          title: const Text("Create Profile", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- 1. FULL NAME WITH INITIALS ---
                const Text("Full Name with Initials", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(Icons.person, hint: "e.g., A.B.C. Perera"),
                ),
                const SizedBox(height: 15),

                // --- 2. REGISTRATION NUMBER ---
                const Text("Registration Number", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _regNumController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters, // Forces uppercase
                  decoration: _inputDecoration(Icons.badge, hint: "e.g., EN123456"),
                ),
                const SizedBox(height: 15),

                // --- 3. GENDER ---
                const Text("Gender", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Theme(
                  data: ThemeData.dark(),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Male", style: TextStyle(color: Colors.white)),
                          value: "Male",
                          groupValue: _selectedGender,
                          onChanged: (val) => setState(() => _selectedGender = val),
                          activeColor: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Female", style: TextStyle(color: Colors.white)),
                          value: "Female",
                          groupValue: _selectedGender,
                          onChanged: (val) => setState(() => _selectedGender = val),
                          activeColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // --- 4. CONTACT NUMBER ---
                const Text("Contact Number", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _contactController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(Icons.phone, hint: "e.g., 0712345678"),
                ),
                const SizedBox(height: 15),

                // --- 5. EMAIL ---
                const Text("University Email", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(Icons.email, hint: "e.g., yourname@foe.sjp.ac.lk"),
                ),
                const SizedBox(height: 15),

                // --- 6. PASSWORD ---
                const Text("Password", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.lock),
                ),
                const SizedBox(height: 15),

                // --- 7. CONFIRM PASSWORD ---
                const Text("Confirm Password", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.lock_clock), 
                ),
                const SizedBox(height: 30),

                // --- REGISTER BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator() 
                      : const Text("REGISTER ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for styles
  InputDecoration _inputDecoration(IconData icon, {String? hint}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      prefixIcon: Icon(icon, color: Colors.white70),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}