import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Text Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();
  final _regNumController = TextEditingController();

  // Service
  final _authService = AuthService();
  bool _isLoading = false;

  // Variables for Radio Buttons
  String? _selectedGender; 
  String? _selectedRole;   

  // Register Function
  void _register() async {
    // Check if fields are empty
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _regNumController.text.isEmpty ||
        _selectedGender == null ||
        _selectedRole == null) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields and select options")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        contact: _contactController.text.trim(),
        regNum: _regNumController.text.trim(),
        gender: _selectedGender!,
        role: _selectedRole!,
      );

      if (mounted) {
        // Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Account created! Verify your email to login."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
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
      // Gradient Background
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD932C6), Color(0xFF4A3ED6)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        appBar: AppBar(
          title: const Text("Create Profile", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // SAFE AREA ensures content isn't hidden behind phone notches
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- 1. EMAIL ---
                const Text("Email Address", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                // --- 2. PASSWORD ---
                const Text("Password", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                // --- 3. CONTACT NUMBER ---
                const Text("Contact Number", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _contactController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),

                // --- 4. REGISTRATION NUMBER ---
                const Text("Registration Number", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                TextField(
                  controller: _regNumController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    prefixIcon: const Icon(Icons.badge, color: Colors.white70),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 25),

                // --- 5. GENDER (Radio Buttons) ---
                const Text("Gender", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Theme(
                  data: ThemeData.dark(), // Forces white radio circles
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

                // --- 6. ROLE (Radio Buttons) ---
                const Text("Select Role", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Theme(
                  data: ThemeData.dark(),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text("Admin", style: TextStyle(color: Colors.white)),
                        value: "Admin",
                        groupValue: _selectedRole,
                        onChanged: (val) => setState(() => _selectedRole = val),
                        activeColor: Colors.white,
                      ),
                      RadioListTile<String>(
                        title: const Text("Instructor", style: TextStyle(color: Colors.white)),
                        value: "Instructor",
                        groupValue: _selectedRole,
                        onChanged: (val) => setState(() => _selectedRole = val),
                        activeColor: Colors.white,
                      ),
                      RadioListTile<String>(
                        title: const Text("User", style: TextStyle(color: Colors.white)),
                        value: "User",
                        groupValue: _selectedRole,
                        onChanged: (val) => setState(() => _selectedRole = val),
                        activeColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- 7. REGISTER BUTTON ---
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
                // Extra space at bottom for scrolling
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}