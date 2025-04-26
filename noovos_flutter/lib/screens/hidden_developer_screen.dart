/*
Hidden Developer Screen
This screen is only accessible through a secret gesture (tapping the logo 5 times)
Shows app version and other developer information
*/

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../styles/app_styles.dart';

class HiddenDeveloperScreen extends StatelessWidget {
  const HiddenDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Mode'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Developer icon
            const Icon(
              Icons.developer_mode,
              size: 80,
              color: AppStyles.primaryColor,
            ),
            const SizedBox(height: 20),
            
            // App version
            const Text(
              'App Version',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppConfig.appVersion,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppStyles.primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            
            // Exit button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Exit Developer Mode'),
            ),
          ],
        ),
      ),
    );
  }
}
