import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'constant.dart';
import 'dashboard.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _driverUserNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String _errorMessage = '';
  bool _showPassword = false;

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    String driverUserName = _driverUserNameController.text;
    String enteredPassword = _passwordController.text;

    try {
      final response = await http.get(
        Uri.parse('${Constants.apiUrl}/api/get-driver-by-username/$driverUserName'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> driverList = json.decode(response.body);

        if (driverList.isNotEmpty) {
          final driverInfo = driverList.first;

          print('Driver Info from Server: $driverInfo');

          if (driverInfo != null && _isPasswordValid(driverInfo['password'], enteredPassword)) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(driverUserName: driverUserName),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'Invalid Username/Password. Please try again!';
            });
            print('Driver not found or authentication failed.');
          }
        } else {
          setState(() {
            _errorMessage = 'Driver not found.';
          });
          print('Driver list is empty.');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch driver information. Status code: ${response.statusCode}';
        });
        print('Failed to fetch driver information. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred during the login process. Please try again later.';
      });
      print('Error during login: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  bool _isPasswordValid(String serverPasswordHash, String enteredPassword) {
    try {
      return BCrypt.checkpw(enteredPassword, serverPasswordHash);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating password. Please try again later.';
      });
      print('Error validating password: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.lightGreen, Colors.green],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Your logo widget (replace with your logo widget)
                Image.asset(
                  'assets/lts-logo.png', // Replace with the path to your logo image
                  height: 100, // Adjust the height as needed
                ),
                SizedBox(height: 16.0),
                // Text widget for the name
                Text(
                  'Lolong Trucking Services',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20.0),
                // Text field for driver name
                TextFormField(
                  controller: _driverUserNameController,
                  decoration: InputDecoration(
                    labelText: 'Driver Username',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                // Text field for password
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword, // Hide or show the entered text
                  decoration: InputDecoration(
                    labelText: 'Password',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                // Show error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                // Button for login
                ElevatedButton(
                  onPressed: _loading ? null : _attemptLogin,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    'Login',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
