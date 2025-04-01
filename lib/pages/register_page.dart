import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phi_app/components/login_button.dart';
import 'package:phi_app/components/login_text_field.dart';
import 'package:phi_app/components/my_colors.dart';
import '../models/userModel.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;

  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameControllerReg = TextEditingController();
  final emailControllerReg = TextEditingController();
  final passwordControllerReg = TextEditingController();
  final confirmPasswordControllerReg = TextEditingController();
  String signUpError = '';

  void showSignUpError(error) {
    setState(() {
      signUpError = error.toString();
    });
  }

  void signUserUp() async {
    // loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // create user
    if (passwordControllerReg.text == confirmPasswordControllerReg.text) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailControllerReg.text,
          password: passwordControllerReg.text,
        );

        UserModel userModel = UserModel(
          id: userCredential.user!.uid,
          email: emailControllerReg.text,
          name: fullNameControllerReg.text,
          role: UserRole.user,
          createdAt: DateTime.now(),
        );

        // Save user to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userModel.id)
            .set(userModel.toFirestore());

      } on FirebaseAuthException catch (e) {
        // showSignUpError('Account Created! Please Log in');
        showSignUpError(e);
      }
    } else {
      showSignUpError('Passwords doesn\'t match!');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // logo
            Image.asset(
              'lib/images/logo.png',
              height: 100,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'PHI Assistant',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: MyColors.mainColor,
              ),
            ),
            SizedBox(
              height: 20,
            ),

            // sign up error display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                signUpError,
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 10,
            ),

            // Name field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: LoginTextField(
                controller: fullNameControllerReg,
                obscureText: false,
                hintText: 'Full Name',
              ),
            ),
            SizedBox(
              height: 20,
            ),

            // email field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: LoginTextField(
                controller: emailControllerReg,
                obscureText: false,
                hintText: 'Email',
              ),
            ),
            SizedBox(
              height: 20,
            ),

            // password field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: LoginTextField(
                controller: passwordControllerReg,
                obscureText: true,
                hintText: 'Password',
              ),
            ),
            SizedBox(
              height: 20,
            ),

            //confirm password field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: LoginTextField(
                controller: confirmPasswordControllerReg,
                obscureText: true,
                hintText: 'Confirm Password',
              ),
            ),

            SizedBox(
              height: 30,
            ),

            // register button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: LoginButton(
                onTap: signUserUp,
                buttonText: 'Register',
              ),
            ),
            SizedBox(
              height: 20,
            ),

            // register button and text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already Registered?  ',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onTap,
                  child: Text(
                    'Log In',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
