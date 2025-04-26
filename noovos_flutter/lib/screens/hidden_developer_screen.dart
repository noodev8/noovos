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

// Available base URLs for quick selection
const Map<String, String> availableBaseUrls = {
  'Home': 'http://192.168.1.88:3000',
  'Chippy': 'http://192.168.1.174:3000',
  'Cumberland': 'http://192.168.1.94:3000',
  'Grays': 'http://10.249.1.230:43352',
  'Test Server': 'https://api.noodev8.com',
  'VPS': 'http://77.68.13.150:3003',
};

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

  // Selected environment
  String? _selectedEnvironment;

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

          // Check if the current URL matches any of the presets
          _selectedEnvironment = null;
          for (var entry in availableBaseUrls.entries) {
            if (entry.value == apiUrl) {
              _selectedEnvironment = entry.key;
              break;
            }
          }

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

  // Handle environment selection
  void _handleEnvironmentChange(String? environmentName) {
    if (environmentName != null && availableBaseUrls.containsKey(environmentName)) {
      setState(() {
        _selectedEnvironment = environmentName;
        _apiUrlController.text = availableBaseUrls[environmentName]!;
      });
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

                  // Environment dropdown
                  const Text(
                    'Select Environment:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedEnvironment,
                      isExpanded: true,
                      hint: const Text('Select an environment'),
                      underline: const SizedBox(),
                      onChanged: _handleEnvironmentChange,
                      items: availableBaseUrls.keys.map((String environment) {
                        return DropdownMenuItem<String>(
                          value: environment,
                          child: Text(environment),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Custom URL input
                  const Text(
                    'Or enter custom URL:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
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
