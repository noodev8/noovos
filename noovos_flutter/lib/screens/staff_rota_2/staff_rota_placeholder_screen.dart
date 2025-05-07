/*
Staff Rota Placeholder Screen (Version 2)
This is a simple placeholder for the new staff rota management functionality
*/

import 'package:flutter/material.dart';
import '../../styles/app_styles.dart';

class StaffRotaPlaceholderScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Constructor
  const StaffRotaPlaceholderScreen({
    Key? key,
    required this.business,
  }) : super(key: key);

  @override
  State<StaffRotaPlaceholderScreen> createState() => _StaffRotaPlaceholderScreenState();
}

class _StaffRotaPlaceholderScreenState extends State<StaffRotaPlaceholderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Rota - ${widget.business['name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month,
                size: 80,
                color: AppStyles.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Staff Rota Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppStyles.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Version 2 - New Implementation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppStyles.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'This is a placeholder for the new staff rota management functionality. '
                'The new implementation will provide improved features for managing staff working hours.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New functionality coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.construction),
                label: const Text('Under Construction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
