import 'dart:developer';

import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:securecom/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:securecom/features/user_auth/presentation/pages/login_pg.dart';
import 'package:securecom/features/user_auth/presentation/pages/widgets/form_container_widget.dart';
import 'package:securecom/home.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage ({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final formKey= GlobalKey<FormState>();
  final _auth = FirebaseAuthServices();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override

  void dispose(){
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!EmailValidator.validate(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Sign Up"),
      ),
      body:  Center(
        child:Form(
          key: formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sign Up",
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)
                  ,),
                const SizedBox(
                  height: 30,
                ),
                const SizedBox(height: 10,),
                FormContainerWidget(
                  controller: _emailController,
                  hintText: "Email",
                  isPasswordField: false,
                  validator: (value) => value!.isEmpty? "Email cannot be empty.":null,
                ),
                const SizedBox(height: 10,),
                FormContainerWidget(
                  controller: _passwordController,
                  hintText: "Password",
                  isPasswordField: true,
                  validator: (value) => value!.length <8? "Password should have at least 8 characters.":null,
                ),
                const SizedBox(
                  height: 30.0,
                ),
                GestureDetector(
                  onTap: (){
                    if (formKey.currentState!.validate()){
                      _signUp();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.green[600], content: Text("Account created successfully")));
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ChurchHomePage()), (route) => false );
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red[400],content: Text("Account creation was unsuccessful")));
                    }
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
                        "Sign Up",
                        style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    const SizedBox(width: 5,),
                    GestureDetector(
                      onTap: (){
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ChurchHomePage()),(route) => false);
                      },
                      child: const Text(
                        'Login',
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
      ),
    );
  }

  void _signUp() async{
    final user = await _auth.createUserWithEmailAndPassword(_emailController.text, _passwordController.text);

    String username = _usernameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => ChurchHomePage()), (route) => false );


  }

}
