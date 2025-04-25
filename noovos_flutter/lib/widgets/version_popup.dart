/*
Version popup widget
Shows the app version in a simple popup dialog when the app starts
*/

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../styles/app_styles.dart';

class VersionPopup {
  // Show the version popup
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thank you for using Noovos!',
                style: AppStyles.bodyStyle,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text(
                    'App Version: ',
                    style: AppStyles.bodyStyle,
                  ),
                  Text(
                    AppConfig.appVersion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppStyles.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
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
