/*
Staff Invitations Dialog
This widget displays pending staff invitations and allows users to accept or reject them
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../helpers/image_helper.dart';
import '../helpers/cloudinary_helper.dart';
import '../api/respond_to_staff_invitation_api.dart';

class StaffInvitationsDialog extends StatefulWidget {
  // List of invitations
  final List<Map<String, dynamic>> invitations;

  // Callback when an invitation is responded to
  final Function() onInvitationResponded;

  // Constructor
  const StaffInvitationsDialog({
    Key? key,
    required this.invitations,
    required this.onInvitationResponded,
  }) : super(key: key);

  @override
  State<StaffInvitationsDialog> createState() => _StaffInvitationsDialogState();
}

class _StaffInvitationsDialogState extends State<StaffInvitationsDialog> {
  // Loading state for each invitation
  Map<int, bool> _loadingStates = {};

  @override
  void initState() {
    super.initState();
    // Initialize loading states
    for (final invitation in widget.invitations) {
      _loadingStates[invitation['id']] = false;
    }
  }

  // Respond to invitation
  Future<void> _respondToInvitation(int invitationId, String action) async {
    // Set loading state
    setState(() {
      _loadingStates[invitationId] = true;
    });

    try {
      // Call API to respond to invitation
      final result = await RespondToStaffInvitationApi.respondToStaffInvitation(
        invitationId,
        action,
      );

      if (mounted) {
        // Reset loading state
        setState(() {
          _loadingStates[invitationId] = false;
        });

        // Show success or error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        // If successful, call the callback
        if (result['success']) {
          widget.onInvitationResponded();

          // Close the dialog if this was the last invitation
          if (widget.invitations.length == 1) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Reset loading state
        setState(() {
          _loadingStates[invitationId] = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      // Add constraints to limit the width of the dialog
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            const Text(
              'Staff Invitations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Invitations list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: widget.invitations.map((invitation) {
                    final int id = invitation['id'];
                    final String businessName = invitation['business_name'] ?? 'Unknown Business';
                    final String role = invitation['role'] ?? 'Staff';
                    final String? businessImage = invitation['business_image'];
                    final bool isLoading = _loadingStates[id] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Business info
                            Row(
                              children: [
                                // Business image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: businessImage != null
                                      ? ImageHelper.getCachedNetworkImage(
                                          imageUrl: CloudinaryHelper.getCloudinaryUrl(businessImage),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorWidget: const Icon(
                                            Icons.business,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                            Icons.business,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 16),

                                // Business details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        businessName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Role: $role',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppStyles.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Invitation message
                            const Text(
                              'You have been invited to join this business as a staff member.',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Action buttons
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Column(
                                    children: [
                                      // First row with Accept and Reject buttons
                                      Row(
                                        children: [
                                          // Reject button
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _respondToInvitation(id, 'reject'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(color: Colors.red),
                                              ),
                                              child: const Text('Reject'),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          // Accept button
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _respondToInvitation(id, 'accept'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppStyles.primaryColor,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Accept'),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Decide Later button
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Decide Later'),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
