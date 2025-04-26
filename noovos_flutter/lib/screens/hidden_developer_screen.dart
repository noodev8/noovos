/*
Hidden Developer Screen
This screen is only accessible through a secret gesture (tapping the logo 5 times)
Shows app version and other developer information
Allows editing of configuration settings
*/

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../styles/app_styles.dart';
import '../helpers/config_helper.dart';

class HiddenDeveloperScreen extends StatefulWidget {
  const HiddenDeveloperScreen({super.key});

  @override
  State<HiddenDeveloperScreen> createState() => _HiddenDeveloperScreenState();
}

class _HiddenDeveloperScreenState extends State<HiddenDeveloperScreen> {
  // Text controllers
  final _apiUrlController = TextEditingController();

  // Loading and saving states
  bool _isLoading = true;
  bool _isSaving = false;

  // Success message
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  // Load current settings
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current API URL
      final apiUrl = await ConfigHelper.getApiBaseUrl();

      if (mounted) {
        setState(() {
          _apiUrlController.text = apiUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiUrlController.text = AppConfig.apiBaseUrl;
          _isLoading = false;
        });
      }
    }
  }

  // Save settings
  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      // Save API URL
      await ConfigHelper.saveApiBaseUrl(_apiUrlController.text.trim());

      if (mounted) {
        setState(() {
          _successMessage = 'Settings saved successfully';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Reset settings to default
  Future<void> _resetSettings() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
      // Reset API URL
      await ConfigHelper.resetApiBaseUrl();

      if (mounted) {
        setState(() {
          _apiUrlController.text = AppConfig.apiBaseUrl;
          _successMessage = 'Settings reset to default';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting settings: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Mode'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Developer icon and title
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.developer_mode,
                          size: 60,
                          color: AppStyles.primaryColor,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Developer Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'App Version: ${AppConfig.appVersion}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Success message
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // API URL section
                  const Text(
                    'API Base URL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'The base URL for API requests. Changes will apply to all API calls in the app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _apiUrlController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'e.g., http://192.168.1.88:3000',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),

                  // Default values section
                  const Text(
                    'Default Values (Read Only)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoItem('Default API URL', AppConfig.apiBaseUrl),
                  _buildInfoItem('Image Base URL', AppConfig.imageBaseUrl),
                  const SizedBox(height: 30),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppStyles.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Settings'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _isSaving ? null : _resetSettings,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppStyles.primaryColor,
                        ),
                        child: const Text('Reset to Default'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Exit button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: const Text('Exit Developer Mode'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to build info items
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
