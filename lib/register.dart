import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Pastikan Anda mengimpor LoginScreen

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _kdPetugasController = TextEditingController();
  String? _errorMessage;
  String? _successMessage;

  Future<void> _register() async {
    print("Register button clicked");

    final String url = 'https://ujikom2024pplg.smkn4bogor.sch.id/0077534259/login.php?action=register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
          'kd_petugas': _kdPetugasController.text,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      final Map<String, dynamic> responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['message'] == 'Data user berhasil didaftarkan') {
          setState(() {
            _successMessage = 'Registration successful!';
            _errorMessage = null;

            // Clear the text fields
            _usernameController.clear();
            _passwordController.clear();
            _kdPetugasController.clear();
          });

          // Arahkan ke LoginScreen setelah registrasi berhasil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } else {
          setState(() {
            _errorMessage = responseData['message'];
            _successMessage = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Something went wrong. Status code: ${response.statusCode}';
          _successMessage = null;
        });
      }
    } catch (error) {
      print("Error occurred: $error");
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: _kdPetugasController,
                decoration: InputDecoration(labelText: 'Kode Petugas'),
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (_successMessage != null)
                Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green),
                ),
              ElevatedButton(
                onPressed: _register,
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
