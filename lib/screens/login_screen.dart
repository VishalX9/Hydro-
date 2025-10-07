import 'package:flutter/material.dart';
import 'package:hydrogauge/services/api_client.dart';
// Navigate via named route to the HomeShell after login

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  String role = 'Field Personnel';
  final ApiClient _api = ApiClient();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Background image (make sure this matches your asset name)
          Image.asset(
            'assets/login_bg.jpg', // or 'assets/login_bg.webp'
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.4)), // dark overlay

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 8,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Login',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email / Employee ID',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _pass,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: role,
                        items: const [
                          DropdownMenuItem(value: 'Field Personnel', child: Text('Field Personnel')),
                          DropdownMenuItem(value: 'Supervisor', child: Text('Supervisor')),
                          DropdownMenuItem(value: 'Analyst', child: Text('Analyst')),
                        ],
                        onChanged: (v) => setState(() => role = v ?? role),
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      FilledButton(
                        onPressed: _loading
                            ? null
                            : () async {
                          final email = _email.text.trim();
                          if (email.isEmpty || _pass.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Enter email & password')),
                            );
                            return;
                          }
                              setState(() => _loading = true);
                              try {
                                final resp = await _api.login(username: email, password: _pass.text);
                                if (resp['ok'] == true) {
                                  if (role == 'Supervisor') {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                      arguments: {'role': 'supervisor', 'index': 1},
                                    );
                                  } else if (role == 'Analyst') {
                                    Navigator.pushReplacementNamed(context, '/analyst');
                                  } else {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                      arguments: {'role': 'field', 'index': 0},
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Login failed: ${resp['error'] ?? 'Unknown'}')),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Login error: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _loading = false);
                              }
                            },
                        child: Text(_loading ? 'Please wait…' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}