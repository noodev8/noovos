/*
Welcome popup widget
Shows a welcome message in a simple popup dialog
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class VersionPopup {
  // Show the welcome popup
  static void show(BuildContext context) {
    // Show dialog
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Welcome to Noovos',
            style: AppStyles.subheadingStyle,
          ),
          content: const Text(
            'Thank you for using Noovos!',
            style: AppStyles.bodyStyle,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppStyles.primaryColor,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
