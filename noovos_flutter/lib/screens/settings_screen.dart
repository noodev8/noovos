/*
Show the settings screen allowing users to configure application settings
This screen allows users to update the API URL and other configuration options
*/

import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../helpers/config_helper.dart';
import '../styles/app_styles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Text controllers
  final _apiUrlController = TextEditingController();

  // Loading state
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
    // Clean up controllers
    _apiUrlController.dispose();
    super.dispose();
  }

  // Load settings
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
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
            backgroundColor: AppStyles.errorColor,
          ),
        );

        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Reset settings
  Future<void> _resetSettings() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
    });

    try {
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
            backgroundColor: AppStyles.errorColor,
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
        title: const Text('Developer Settings'),
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
                  // Settings title
                  const Text(
                    'Developer Settings',
                    style: AppStyles.headingStyle,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(50),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withAlpha(100)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'These settings are for development purposes only. They will be hidden in production.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  if (_successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppStyles.successColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStyles.successColor.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppStyles.successColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: AppStyles.successColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // API URL field
                  const Text(
                    'API URL',
                    style: AppStyles.subheadingStyle,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Enter the URL of the API server. Use http://localhost:3000 for local development or the IP address of your server.',
                    style: AppStyles.captionStyle,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _apiUrlController,
                    decoration: AppStyles.inputDecoration(
                      'API URL',
                      hint: 'http://localhost:3000',
                      prefixIcon: const Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 30),

                  // Save button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: AppStyles.primaryButtonStyle,
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
                        style: AppStyles.secondaryButtonStyle,
                        child: const Text('Reset to Default'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // App info
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'About',
                    style: AppStyles.subheadingStyle,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoItem('App Name', AppConfig.appName),
                  _buildInfoItem('Version', AppConfig.appVersion),
                ],
              ),
            ),
    );
  }

  // Build info item
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
                color: AppStyles.secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppStyles.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}
