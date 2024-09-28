import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:securecom/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:securecom/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:securecom/features/user_auth/presentation/pages/widgets/form_container_widget.dart';
import 'package:securecom/features/user_auth/presentation/pages/widgets/reset_password.dart';
import 'package:securecom/forms.dart';
import 'package:securecom/home.dart';

class LoginPg extends StatefulWidget {
  const LoginPg({super.key});

  @override
  State<LoginPg> createState() => _LoginPgState();
}

class _LoginPgState extends State<LoginPg> {
  final _auth = FirebaseAuthServices();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  _login() async {
    final user =
    await _auth.loginUserWithEmailAndPassword(_email.text, _password.text);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChurchHomePage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[400],
          content: const Text("User has logged in successfully"),
        ),
      );
    }else {
      final email = _email.text.trim();

      // Step 1: Check if the email exists in the 'members' collection
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isEmpty) {
        log("Email not found in members collection");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red[300],
            content: const Text("User not found")));
        return;
      }

      // Step 2: Check if the member has a password
      final memberData = memberSnapshot.docs.first.data();
      final passwordSet = memberData['passwordSet'] ?? false;

      if (!passwordSet) {
        // If the password is not set, navigate to a set password page
        log(
            "Password not set for this member, navigating to set password page.");
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => SetPasswordPage(email: email)));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Login"),
      ),
      resizeToAvoidBottomInset: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              FormContainerWidget(
                hintText: "Email",
                isPasswordField: false,
                controller: _email,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                hintText: "Password",
                isPasswordField: true,
                controller: _password,
              ),
              const SizedBox(height: 9.0),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPassword()),
                    );
                  },
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15.0),
              GestureDetector(
                onTap: () {
                  _login();
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Don\'t have an account?'),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpPage()),
                              (route) => false);
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SetPasswordPage extends StatefulWidget {
  final String email;

  const SetPasswordPage({super.key, required this.email});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _auth = FirebaseAuthServices();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  _setPassword() async {
    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red[300],
          content: const Text("Passwords do not match")));
      return;
    }

    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update the password for the authenticated user
        await user.updatePassword(_newPasswordController.text.trim());

        // Update the 'passwordSet' flag in Firestore
        final memberDoc = FirebaseFirestore.instance
            .collection('members')
            .doc(widget.email);

        await memberDoc.update({'passwordSet': true});

        log("Password set successfully for user");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ChurchHomePage()));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.green[400],
            content: const Text("Password set successfully")));
      } else {
        log("No authenticated user found");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red[300],
            content: const Text("No authenticated user found")));
      }
    } catch (e) {
      log("Error setting password: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red[300],
          content: const Text("Failed to set password")));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Password"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Set a New Password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              FormContainerWidget(
                hintText: "New Password",
                isPasswordField: true,
                controller: _newPasswordController,
              ),
              const SizedBox(height: 10),
              FormContainerWidget(
                hintText: "Confirm Password",
                isPasswordField: true,
                controller: _confirmPasswordController,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _setPassword();
                },
                child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Set Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
