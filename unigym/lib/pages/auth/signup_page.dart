import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Text Controllers
  final _nameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // <--- NEW

  // Service
  final _authService = AuthService();
  bool _isLoading = false;

  // Variables
  String? _selectedGender; 

  void _register() async {
    // 1. Check Empty Fields
    if (_nameController.text.isEmpty || 
        _regNumController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedGender == null) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    // 2. Check Password Match
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Register
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        regNum: _regNumController.text.trim(),
        gender: _selectedGender!,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Account created! Verify your email to login."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); 
                  Navigator.pop(context); // Go back to Login
                },
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")))
        );
      }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
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
                
                // --- 1. NAME ---
                const Text("Full Name", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(Icons.person),
                ),
                const SizedBox(height: 15),

                // --- 2. REGISTRATION NUMBER ---
                const Text("Registration Number", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _regNumController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.badge),
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

                // --- 4. EMAIL (Needed for Auth) ---
                const Text("Email Address", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.email),
                ),
                const SizedBox(height: 15),

                // --- 5. PASSWORD ---
                const Text("Password", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.lock),
                ),
                const SizedBox(height: 15),

                // --- 6. CONFIRM PASSWORD ---
                const Text("Confirm Password", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(Icons.lock_clock), // Different icon
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

  // Simple Helper for styles
  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.2),
      prefixIcon: Icon(icon, color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}