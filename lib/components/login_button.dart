import 'package:flutter/material.dart';
import 'package:phi_app/components/my_colors.dart';

class LoginButton extends StatelessWidget {
  final String buttonText;
  final void Function()? onTap;

  LoginButton({super.key, required this.buttonText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        //padding: EdgeInsets.all(20),
        height: 70,
        decoration: BoxDecoration(
          color: MyColors.mainColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
