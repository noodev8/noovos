/*
Version mismatch popup widget
Shows a popup when the app version is below the minimum required version
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../styles/app_styles.dart';

class VersionMismatchPopup {
  // Show the version mismatch popup
  static void show(BuildContext context, String currentVersion, String minimumVersion) {
    // Show dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return WillPopScope(
          // Prevent back button from dismissing the dialog
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text(
              'Update Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppStyles.errorColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your app version is outdated and needs to be updated to continue.',
                  style: AppStyles.bodyStyle,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'Current version: ',
                      style: AppStyles.bodyStyle,
                    ),
                    Text(
                      currentVersion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.errorColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Required version: ',
                      style: AppStyles.bodyStyle,
                    ),
                    Text(
                      minimumVersion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Please update your app from the app store.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Exit the app
                  SystemNavigator.pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppStyles.primaryColor,
                ),
                child: const Text('Exit App'),
              ),
            ],
          ),
        );
      },
    );
  }
}
