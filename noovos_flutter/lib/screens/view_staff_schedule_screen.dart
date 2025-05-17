/*
View Staff Schedule Screen
This screen displays a staff member's schedule and provides navigation to modify it.
Currently a placeholder screen that will be enhanced with full schedule viewing functionality.
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import 'set_schedule_screen.dart';

class ViewStaffScheduleScreen extends StatelessWidget {
  // Staff member details passed from previous screen
  final Map<String, dynamic> staff;
  final Map<String, dynamic> business;

  // Constructor
  const ViewStaffScheduleScreen({
    Key? key,
    required this.staff,
    required this.business,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get staff name for display
    final String firstName = staff['first_name'] ?? '';
    final String lastName = staff['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();

    return Scaffold(
      // App bar with staff name
      appBar: AppBar(
        title: Text('$fullName\'s Schedule'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),

      // Main body content
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder text
              const Text(
                'Staff Schedule View',
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 20),
              const Text(
                'This screen will show the staff member\'s current schedule.',
                style: AppStyles.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Button to navigate to schedule modification
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to set schedule screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SetScheduleScreen(
                        staff: staff,
                        business: business,
                      ),
                    ),
                  );
                },
                style: AppStyles.primaryButtonStyle,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Modify Schedule'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 