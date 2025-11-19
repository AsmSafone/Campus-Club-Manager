import 'package:flutter/material.dart';
import 'package:frontend/screens/executive/executive_dashboard_screen.dart';
import 'package:frontend/screens/member/member_dashboard_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleAuth() async {
    if (_isSignUp) {
      _signUp();
    } else {
      _signIn();
    }
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        // Uri.parse('http://localhost:3000/api/auth/signup'),
        Uri.parse('http://10.0.2.2:3000/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up successful! Please sign in.')),
        );
        setState(() {
          _isSignUp = false;
          _nameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Sign up failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userRole = data['user']['role'];
        final token = data['token'];
        final userData = data['user'];

        // Navigate to the appropriate dashboard based on role
        if (userRole == 'Admin') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/admin-dashboard',
            (route) => false,
            arguments: {'token': token, 'user': userData},
          );
        } else if (userRole == 'Executive') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  ClubExecutiveDashboardScreen(token: token, user: userData),
            ),
            (route) => false,
          );
        } else {
          // Member or Guest
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/member-dashboard',
            (route) => false,
            arguments: {'token': token, 'user': userData},
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome, ${data['user']['name']}!')),
        );

        _emailController.clear();
        _passwordController.clear();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Sign in failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isSignUp ? 'Create Account' : 'Sign In',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32),
              // Logo/Title
              Center(
                child: Text(
                  'Campus Club Manager',
                  style: TextStyle(
                    color: Color(0xFF137FEC),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  _isSignUp ? 'Join our community' : 'Welcome back',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                ),
              ),
              SizedBox(height: 48),

              // Name Field (only for sign up)
              if (_isSignUp) ...[
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),
              ],

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Password Field
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
              ),
              SizedBox(height: 16),

              // Confirm Password Field (only for sign up)
              if (_isSignUp) ...[
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                ),
                SizedBox(height: 24),
              ] else ...[
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // Add forgot password logic here
                    },
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(color: Color(0xFF137FEC), fontSize: 12),
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],

              // Sign In/Up Button
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Color(0xFF137FEC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF137FEC),
                    disabledBackgroundColor: Color(0xFF137FEC).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Create Account' : 'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),

              // Toggle Sign In/Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : 'Don\'t have an account? ',
                    style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _nameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF999999)),
        prefixIcon: Icon(icon, color: Color(0xFF137FEC)),
        filled: true,
        fillColor: Color(0xFF1C2936),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2C3E50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2C3E50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF137FEC)),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF999999)),
        prefixIcon: Icon(Icons.lock, color: Color(0xFF137FEC)),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFF137FEC),
          ),
        ),
        filled: true,
        fillColor: Color(0xFF1C2936),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2C3E50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF2C3E50)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF137FEC)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
