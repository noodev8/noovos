/*
Staff Invitation Helper
Provides functions to check for and handle staff invitations
*/

import 'package:flutter/material.dart';
import '../api/get_staff_invitations_api.dart';
import '../widgets/staff_invitations_dialog.dart';

class StaffInvitationHelper {
  // Check for staff invitations and show dialog if any are found
  static Future<void> checkForInvitations(BuildContext context) async {
    try {
      // Get staff invitations
      final result = await GetStaffInvitationsApi.getStaffInvitations();

      // If there are invitations, show dialog
      if (result['success'] && result['invitations'] != null) {
        final invitations = List<Map<String, dynamic>>.from(result['invitations']);
        
        if (invitations.isNotEmpty && context.mounted) {
          // Show dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => StaffInvitationsDialog(
              invitations: invitations,
              onInvitationResponded: () {
                // Refresh invitations
                checkForInvitations(context);
              },
            ),
          );
        }
      }
    } catch (e) {
      // Silently handle error
      print('Error checking for staff invitations: $e');
    }
  }
}
