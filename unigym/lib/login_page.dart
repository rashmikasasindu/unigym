import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  // Toggle between login and sign up mode
  bool isLoginMode = true; 
  String? errorMessage;

  void _submit() async {
    setState(() { errorMessage = null; });
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() { errorMessage = "Please enter both email and password"; });
      return;
    }

    try {
      if (isLoginMode) {
        // Login Logic
        await _authService.signIn(email, password);
        if (mounted) {
        }
      } else {
        // Register Logic
        await _authService.signUp(email, password);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account Created!"))
            );
        }
      }
    } catch (e) {
      setState(() {
        // Strip "Exception:" from the message for a cleaner UI
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLoginMode ? "Login" : "Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            
            // Password Input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Error Message Display
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            
            const SizedBox(height: 10),

            // Submit Button
            ElevatedButton(
              onPressed: _submit,
              child: Text(isLoginMode ? "Login" : "Sign Up"),
            ),
            
            // Toggle Button
            TextButton(
              onPressed: () {
                setState(() {
                  isLoginMode = !isLoginMode;
                  errorMessage = null;
                });
              },
              child: Text(isLoginMode 
                ? "Don't have an account? Sign Up" 
                : "Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}