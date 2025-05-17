/*
Staff Schedule Management Screen
This screen allows business owners to manage the regular working schedule for a staff member
Features:
- View current schedule entries
- Add new schedule entries
- Edit existing schedule entries
- Delete schedule entries
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../styles/app_styles.dart';
import '../../api/get_staff_schedule_api.dart';
import '../../api/set_staff_schedule_api.dart';
import '../../api/create_auto_staff_rota_api.dart';

class StaffScheduleScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Staff member details
  final Map<String, dynamic> staff;

  // Constructor
  const StaffScheduleScreen({
    Key? key,
    required this.business,
    required this.staff,
  }) : super(key: key);

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen> {
  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Schedule entries
  List<Map<String, dynamic>> _scheduleEntries = [];

  // Days of the week
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Day group options
  final List<Map<String, dynamic>> _dayGroups = [
    {'name': 'Single Day', 'value': 'single'},
    {'name': 'Weekdays (Mon-Fri)', 'value': 'weekdays'},
    {'name': 'Weekend (Sat-Sun)', 'value': 'weekend'},
    {'name': 'All Days', 'value': 'all'},
    {'name': 'Custom Selection', 'value': 'custom'},
  ];

  // Form controllers for adding/editing schedule
  final _formKey = GlobalKey<FormState>();
  String _selectedDayGroup = 'single';
  String _selectedDay = 'Monday';
  List<String> _selectedDays = ['Monday'];
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _repeatController = TextEditingController(text: '1');

  // Selected schedule entry for editing
  Map<String, dynamic>? _selectedScheduleEntry;

  // Pending changes (local only, not yet saved to server)
  List<Map<String, dynamic>> _pendingScheduleEntries = [];

  // Has unsaved changes
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();

    // Set default start date to today
    _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Load schedule entries
    _loadSchedule();
  }

  @override
  void dispose() {
    // Dispose controllers
    _startTimeController.dispose();
    _endTimeController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _repeatController.dispose();

    super.dispose();
  }

  // Load schedule entries
  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get business ID and staff ID
      final int businessId = widget.business['id'];
      final int staffId = widget.staff['appuser_id'];

      // Call API to get schedule entries
      final result = await GetStaffScheduleApi.getStaffSchedule(
        businessId: businessId,
        staffId: staffId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _scheduleEntries = List<Map<String, dynamic>>.from(result['schedules'] ?? []);
          } else {
            // Check if it's a "no schedules found" error, which is not really an error
            if (result['return_code'] == 'NO_SCHEDULES_FOUND') {
              _scheduleEntries = [];
            } else {
              _errorMessage = result['message'] ?? 'Failed to load schedule';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  // Check for time overlap between two time ranges
  bool _hasTimeOverlap(String startTime1, String endTime1, String startTime2, String endTime2) {
    // Parse times to minutes since midnight for easier comparison
    int start1 = _parseTimeToMinutes(startTime1);
    int end1 = _parseTimeToMinutes(endTime1);
    int start2 = _parseTimeToMinutes(startTime2);
    int end2 = _parseTimeToMinutes(endTime2);

    // Check for overlap
    return (start1 < end2 && start2 < end1);
  }

  // Parse time string to minutes since midnight
  int _parseTimeToMinutes(String timeStr) {
    try {
      // Handle both formats (HH:MM and HH:MM AM/PM)
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        // 12-hour format
        bool isPM = timeStr.contains('PM');
        timeStr = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();

        List<String> parts = timeStr.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        // Convert to 24-hour
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;

        return hour * 60 + minute;
      } else {
        // 24-hour format
        List<String> parts = timeStr.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return hour * 60 + minute;
      }
    } catch (e) {
      return 0; // Default in case of parsing error
    }
  }

  // Validate new time block against existing entries
  List<Map<String, dynamic>> _checkForTimeConflicts(String day, String startTime, String endTime) {
    List<Map<String, dynamic>> conflicts = [];

    // Check against existing entries
    for (final entry in _scheduleEntries) {
      if (entry['day_of_week'] == day) {
        if (_hasTimeOverlap(
          startTime,
          endTime,
          entry['start_time'],
          entry['end_time']
        )) {
          conflicts.add(entry);
        }
      }
    }

    // Check against pending entries
    for (final entry in _pendingScheduleEntries) {
      if (entry['day_of_week'] == day && entry['action'] != 'delete') {
        if (_hasTimeOverlap(
          startTime,
          endTime,
          entry['start_time'],
          entry['end_time']
        )) {
          conflicts.add(entry);
        }
      }
    }

    return conflicts;
  }

  // Add schedule entry to pending changes
  void _addScheduleEntry() {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get time values for validation
    final String startTime = _startTimeController.text;
    final String endTime = _endTimeController.text;

    // If editing an existing entry
    if (_selectedScheduleEntry != null) {
      setState(() {
        // If editing an existing entry in the pending list
        if (_selectedScheduleEntry!['pending'] == true) {
          // Find and remove the entry from pending list
          _pendingScheduleEntries.removeWhere((entry) =>
            entry['temp_id'] == _selectedScheduleEntry!['temp_id']);
        }

        // Create an updated entry
        final Map<String, dynamic> updatedEntry = {
          'id': _selectedScheduleEntry!['id'],
          'day_of_week': _selectedDay,
          'start_time': startTime,
          'end_time': endTime,
          'start_date': _startDateController.text,
          'pending': true,
          'action': 'update',
          'original': Map<String, dynamic>.from(_selectedScheduleEntry!),
        };

        // Add optional fields if provided
        if (_endDateController.text.isNotEmpty) {
          updatedEntry['end_date'] = _endDateController.text;
        }

        if (_repeatController.text.isNotEmpty) {
          updatedEntry['repeat_every_n_weeks'] = int.tryParse(_repeatController.text) ?? 1;
        }

        // Add to pending changes
        _pendingScheduleEntries.add(updatedEntry);

        // Set flag for unsaved changes
        _hasUnsavedChanges = true;

        // Clear form
        _clearForm();
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule entry updated'),
        ),
      );

      return;
    }

    // For new entries, check each selected day for conflicts
    List<String> daysWithConflicts = [];
    Map<String, List<Map<String, dynamic>>> conflictsByDay = {};

    for (final String day in _selectedDays) {
      List<Map<String, dynamic>> conflicts = _checkForTimeConflicts(day, startTime, endTime);
      if (conflicts.isNotEmpty) {
        daysWithConflicts.add(day);
        conflictsByDay[day] = conflicts;
      }
    }

    // If there are conflicts, show a dialog
    if (daysWithConflicts.isNotEmpty) {
      _showTimeConflictDialog(daysWithConflicts, conflictsByDay, startTime, endTime);
      return;
    }

    // No conflicts, add the entries
    setState(() {
      // For new entries, create one entry for each selected day
      for (final String day in _selectedDays) {
        final Map<String, dynamic> newEntry = {
          'day_of_week': day,
          'start_time': startTime,
          'end_time': endTime,
          'start_date': _startDateController.text,
          'pending': true,
          'action': 'add',
          'temp_id': '${DateTime.now().millisecondsSinceEpoch}_$day',
        };

        // Add optional fields if provided
        if (_endDateController.text.isNotEmpty) {
          newEntry['end_date'] = _endDateController.text;
        }

        if (_repeatController.text.isNotEmpty) {
          newEntry['repeat_every_n_weeks'] = int.tryParse(_repeatController.text) ?? 1;
        }

        // Add to pending changes
        _pendingScheduleEntries.add(newEntry);
      }

      // Set flag for unsaved changes
      _hasUnsavedChanges = true;

      // Clear form
      _clearForm();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule entries added for ${_selectedDays.length} day(s)'),
      ),
    );
  }

  // Show dialog for time conflicts
  void _showTimeConflictDialog(
    List<String> daysWithConflicts,
    Map<String, List<Map<String, dynamic>>> conflictsByDay,
    String newStartTime,
    String newEndTime
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Conflict Detected'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The time block $newStartTime - $newEndTime conflicts with existing schedule entries for the following days:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...daysWithConflicts.map((day) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...conflictsByDay[day]!.map((conflict) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Text('${conflict['start_time']} - ${conflict['end_time']}'),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'What would you like to do?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addEntriesWithoutConflictDays(daysWithConflicts, newStartTime, newEndTime);
            },
            child: const Text('Skip Conflicting Days'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addEntriesReplacingConflicts(daysWithConflicts, conflictsByDay, newStartTime, newEndTime);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Replace Existing Entries'),
          ),
        ],
      ),
    );
  }

  // Add entries for days without conflicts
  void _addEntriesWithoutConflictDays(List<String> daysWithConflicts, String startTime, String endTime) {
    setState(() {
      // Create entries only for days without conflicts
      List<String> daysWithoutConflicts = _selectedDays.where((day) => !daysWithConflicts.contains(day)).toList();

      for (final String day in daysWithoutConflicts) {
        final Map<String, dynamic> newEntry = {
          'day_of_week': day,
          'start_time': startTime,
          'end_time': endTime,
          'start_date': _startDateController.text,
          'pending': true,
          'action': 'add',
          'temp_id': '${DateTime.now().millisecondsSinceEpoch}_$day',
        };

        // Add optional fields if provided
        if (_endDateController.text.isNotEmpty) {
          newEntry['end_date'] = _endDateController.text;
        }

        if (_repeatController.text.isNotEmpty) {
          newEntry['repeat_every_n_weeks'] = int.tryParse(_repeatController.text) ?? 1;
        }

        // Add to pending changes
        _pendingScheduleEntries.add(newEntry);
      }

      // Set flag for unsaved changes if any entries were added
      _hasUnsavedChanges = daysWithoutConflicts.isNotEmpty;

      // Clear form
      _clearForm();
    });

    // Show success message if any entries were added
    List<String> daysWithoutConflicts = _selectedDays.where((day) => !daysWithConflicts.contains(day)).toList();
    if (daysWithoutConflicts.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added entries for ${daysWithoutConflicts.length} day(s) without conflicts'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No entries added - all selected days had conflicts'),
        ),
      );
    }
  }

  // Add entries replacing conflicts
  void _addEntriesReplacingConflicts(
    List<String> daysWithConflicts,
    Map<String, List<Map<String, dynamic>>> conflictsByDay,
    String startTime,
    String endTime
  ) {
    setState(() {
      // First, mark conflicting entries for deletion
      for (final String day in daysWithConflicts) {
        for (final conflict in conflictsByDay[day]!) {
          // If it's an existing entry (not pending)
          if (conflict['pending'] != true) {
            // Add to pending changes as delete
            _pendingScheduleEntries.add({
              'id': conflict['id'],
              'day_of_week': conflict['day_of_week'],
              'start_time': conflict['start_time'],
              'end_time': conflict['end_time'],
              'start_date': conflict['start_date'],
              'end_date': conflict['end_date'],
              'repeat_every_n_weeks': conflict['repeat_every_n_weeks'],
              'pending': true,
              'action': 'delete',
              'original': Map<String, dynamic>.from(conflict),
            });
          }
          // If it's a pending entry, just remove it
          else {
            if (conflict['temp_id'] != null) {
              _pendingScheduleEntries.removeWhere((e) => e['temp_id'] == conflict['temp_id']);
            } else if (conflict['id'] != null) {
              _pendingScheduleEntries.removeWhere((e) =>
                e['action'] == 'update' && e['id'] == conflict['id']);
            }
          }
        }
      }

      // Now add new entries for all selected days
      for (final String day in _selectedDays) {
        final Map<String, dynamic> newEntry = {
          'day_of_week': day,
          'start_time': startTime,
          'end_time': endTime,
          'start_date': _startDateController.text,
          'pending': true,
          'action': 'add',
          'temp_id': '${DateTime.now().millisecondsSinceEpoch}_$day',
        };

        // Add optional fields if provided
        if (_endDateController.text.isNotEmpty) {
          newEntry['end_date'] = _endDateController.text;
        }

        if (_repeatController.text.isNotEmpty) {
          newEntry['repeat_every_n_weeks'] = int.tryParse(_repeatController.text) ?? 1;
        }

        // Add to pending changes
        _pendingScheduleEntries.add(newEntry);
      }

      // Set flag for unsaved changes
      _hasUnsavedChanges = true;

      // Clear form
      _clearForm();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added entries for ${_selectedDays.length} day(s), replacing ${daysWithConflicts.length} conflicting day(s)'),
      ),
    );
  }

  // Save all pending changes to the server
  Future<void> _saveAllChanges() async {
    // Check if there are any pending changes
    if (_pendingScheduleEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No changes to save'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Get business ID and staff ID
      final int businessId = widget.business['id'];
      final int staffId = widget.staff['appuser_id'];

      // Create schedule list (we're replacing the entire schedule)
      final List<Map<String, dynamic>> schedule = [];

      // Add all existing entries that aren't being updated or deleted
      for (final entry in _scheduleEntries) {
        // Skip entries that are being updated or deleted
        bool isBeingModified = _pendingScheduleEntries.any((pendingEntry) =>
          (pendingEntry['action'] == 'update' || pendingEntry['action'] == 'delete') &&
          pendingEntry['id'] == entry['id']);

        if (!isBeingModified) {
          schedule.add({
            'day_of_week': entry['day_of_week'],
            'start_time': entry['start_time'],
            'end_time': entry['end_time'],
            'start_date': entry['start_date'],
            'end_date': entry['end_date'],
            'repeat_every_n_weeks': entry['repeat_every_n_weeks'],
          });
        }
      }

      // Add all pending entries (new and updated, but not deleted)
      for (final entry in _pendingScheduleEntries) {
        // Skip entries marked for deletion
        if (entry['action'] == 'delete') {
          continue;
        }

        final Map<String, dynamic> scheduleEntry = {
          'day_of_week': entry['day_of_week'],
          'start_time': entry['start_time'],
          'end_time': entry['end_time'],
          'start_date': entry['start_date'],
        };

        // Add optional fields if provided
        if (entry['end_date'] != null) {
          scheduleEntry['end_date'] = entry['end_date'];
        }

        if (entry['repeat_every_n_weeks'] != null) {
          scheduleEntry['repeat_every_n_weeks'] = entry['repeat_every_n_weeks'];
        }

        schedule.add(scheduleEntry);
      }

      // Call API to set schedule
      final result = await SetStaffScheduleApi.setStaffSchedule(
        businessId: businessId,
        staffId: staffId,
        schedule: schedule,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            // Clear pending changes
            _pendingScheduleEntries = [];
            _hasUnsavedChanges = false;

            // Reload schedule
            _loadSchedule();

            // Call create_auto_staff_rota API to update the rota based on the new schedule
            _generateAutoStaffRota(businessId, staffId);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'All changes saved successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to save changes'),
                backgroundColor: AppStyles.errorColor,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  // Generate auto staff rota
  Future<void> _generateAutoStaffRota(int businessId, int staffId) async {
    try {
      // Call API to generate auto staff rota
      final result = await CreateAutoStaffRotaApi.createAutoStaffRota(
        businessId: businessId,
        staffId: staffId,
      );

      if (mounted) {
        if (result['success']) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff rota generated successfully (${result['generated_count']} entries)'),
              backgroundColor: AppStyles.successColor,
            ),
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to generate staff rota'),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred while generating staff rota: $e'),
            backgroundColor: AppStyles.errorColor,
          ),
        );
      }
    }
  }

  // Mark schedule entry for deletion (adds to pending changes)
  Future<void> _deleteScheduleEntry(Map<String, dynamic> entry) async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Schedule Entry'),
        content: Text('Are you sure you want to delete this schedule entry for ${entry['day_of_week']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) {
      return;
    }

    // Add to pending changes as a delete action
    setState(() {
      // Add entry to pending changes with 'delete' action
      _pendingScheduleEntries.add({
        'id': entry['id'],
        'day_of_week': entry['day_of_week'],
        'start_time': entry['start_time'],
        'end_time': entry['end_time'],
        'start_date': entry['start_date'],
        'end_date': entry['end_date'],
        'repeat_every_n_weeks': entry['repeat_every_n_weeks'],
        'pending': true,
        'action': 'delete',
        'original': Map<String, dynamic>.from(entry),
      });

      // Set flag for unsaved changes
      _hasUnsavedChanges = true;
    });

    // Show message if still mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Schedule entry marked for deletion (not yet saved)'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'SAVE ALL',
            textColor: Colors.white,
            onPressed: _saveAllChanges,
          ),
        ),
      );
    }
  }

  // Edit schedule entry
  void _editScheduleEntry(Map<String, dynamic> entry) {
    // Set selected entry
    setState(() {
      _selectedScheduleEntry = entry;

      // Set form values
      _selectedDayGroup = 'single';
      _selectedDay = entry['day_of_week'];
      _selectedDays = [entry['day_of_week']];
      _startTimeController.text = entry['start_time'];
      _endTimeController.text = entry['end_time'];
      _startDateController.text = entry['start_date'];
      _endDateController.text = entry['end_date'] ?? '';
      _repeatController.text = entry['repeat_every_n_weeks']?.toString() ?? '1';
    });

    // Scroll to form
    // This would require a ScrollController, which we could add if needed
  }

  // Clear form
  void _clearForm() {
    setState(() {
      _selectedScheduleEntry = null;
      _selectedDayGroup = 'single';
      _selectedDay = 'Monday';
      _selectedDays = ['Monday'];
      _startTimeController.clear();
      _endTimeController.clear();
      _startDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _endDateController.clear();
      _repeatController.text = '1';
    });
  }

  // Show time picker
  Future<void> _showTimePicker(TextEditingController controller) async {
    // Parse current time if available
    TimeOfDay? initialTime;
    if (controller.text.isNotEmpty) {
      try {
        // Handle both formats (HH:MM and HH:MM AM/PM)
        String timeStr = controller.text;
        bool isPM = false;

        // Check if time includes AM/PM
        if (timeStr.contains('AM') || timeStr.contains('PM')) {
          isPM = timeStr.contains('PM');
          // Remove AM/PM
          timeStr = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        }

        final parts = timeStr.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        // Adjust for PM
        if (isPM && hour < 12) {
          hour += 12;
        }

        // Adjust for 12 AM
        if (!isPM && hour == 12) {
          hour = 0;
        }

        initialTime = TimeOfDay(hour: hour, minute: minute);
      } catch (e) {
        initialTime = TimeOfDay.now();
      }
    } else {
      initialTime = TimeOfDay.now();
    }

    // Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Format time as HH:MM (24-hour format)
      final String formattedTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

      // Set controller text
      controller.text = formattedTime;
    }
  }

  // Show date picker
  Future<void> _showDatePicker(TextEditingController controller) async {
    // Parse current date if available
    DateTime initialDate;
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd').parse(controller.text);
      } catch (e) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    // Show date picker
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      // Format date as YYYY-MM-DD
      final String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      // Set controller text
      controller.text = formattedDate;
    }
  }

  // Show custom day selection dialog
  Future<void> _showDaySelectionDialog() async {
    // Create a temporary list to hold selected days
    List<String> tempSelectedDays = List.from(_selectedDays);

    // Show dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Days'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _daysOfWeek.map((day) {
                    return CheckboxListTile(
                      title: Text(day),
                      value: tempSelectedDays.contains(day),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!tempSelectedDays.contains(day)) {
                              tempSelectedDays.add(day);
                            }
                          } else {
                            tempSelectedDays.remove(day);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update selected days
                    this.setState(() {
                      _selectedDays = tempSelectedDays;

                      // If no days selected, revert to single day
                      if (_selectedDays.isEmpty) {
                        _selectedDayGroup = 'single';
                        _selectedDays = [_selectedDay];
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Schedule - ${widget.staff['first_name']} ${widget.staff['last_name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : Stack(
              children: [
                _buildScheduleManagementUI(),
                if (_isLoading)
                  Container(
                    color: Colors.white.withAlpha(178), // 0.7 opacity = 178/255
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  // Build error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppStyles.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(
                fontSize: 16,
                color: AppStyles.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSchedule,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // Build schedule management UI
  Widget _buildScheduleManagementUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add/Edit schedule form
          _buildScheduleForm(),

          const SizedBox(height: 24),

          // Schedule entries list
          _buildScheduleEntriesList(),
        ],
      ),
    );
  }

  // Build schedule form
  Widget _buildScheduleForm() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Text(
                _selectedScheduleEntry == null ? 'Add Schedule Entry' : 'Edit Schedule Entry',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Day selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day group dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDayGroup,
                    decoration: AppStyles.inputDecoration('Day Selection'),
                    items: _dayGroups.map((group) {
                      return DropdownMenuItem<String>(
                        value: group['value'],
                        child: Text(group['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDayGroup = value!;

                        // Update selected days based on group
                        switch (value) {
                          case 'single':
                            _selectedDays = [_selectedDay];
                            break;
                          case 'weekdays':
                            _selectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
                            break;
                          case 'weekend':
                            _selectedDays = ['Saturday', 'Sunday'];
                            break;
                          case 'all':
                            _selectedDays = [..._daysOfWeek];
                            break;
                          case 'custom':
                            // Show custom selection dialog
                            Future.delayed(Duration.zero, () {
                              _showDaySelectionDialog();
                            });
                            break;
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a day group';
                      }
                      if (_selectedDays.isEmpty) {
                        return 'Please select at least one day';
                      }
                      return null;
                    },
                  ),

                  // Show single day dropdown if 'single' is selected
                  if (_selectedDayGroup == 'single') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDay,
                      decoration: AppStyles.inputDecoration('Day of Week'),
                      items: _daysOfWeek.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value!;
                          _selectedDays = [_selectedDay];
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a day';
                        }
                        return null;
                      },
                    ),
                  ],

                  // Show selected days summary for other options
                  if (_selectedDayGroup != 'single') ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        'Selected days: ${_selectedDays.join(', ')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Start time
              TextFormField(
                controller: _startTimeController,
                decoration: AppStyles.inputDecoration(
                  'Start Time (HH:MM)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _showTimePicker(_startTimeController),
                  ),
                ),
                readOnly: true,
                onTap: () => _showTimePicker(_startTimeController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a start time';
                  }
                  // Time format validation (HH:MM or HH:MM AM/PM)
                  final RegExp timeRegex24h = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                  final RegExp timeRegex12h = RegExp(r'^(0?[1-9]|1[0-2]):[0-5][0-9] (AM|PM)$');

                  if (!timeRegex24h.hasMatch(value) && !timeRegex12h.hasMatch(value)) {
                    return 'Please enter a valid time (HH:MM or HH:MM AM/PM)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // End time
              TextFormField(
                controller: _endTimeController,
                decoration: AppStyles.inputDecoration(
                  'End Time (HH:MM)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _showTimePicker(_endTimeController),
                  ),
                ),
                readOnly: true,
                onTap: () => _showTimePicker(_endTimeController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an end time';
                  }

                  // Time format validation (HH:MM or HH:MM AM/PM)
                  final RegExp timeRegex24h = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                  final RegExp timeRegex12h = RegExp(r'^(0?[1-9]|1[0-2]):[0-5][0-9] (AM|PM)$');

                  if (!timeRegex24h.hasMatch(value) && !timeRegex12h.hasMatch(value)) {
                    return 'Please enter a valid time (HH:MM or HH:MM AM/PM)';
                  }

                  // Check that end time is after or equal to start time
                  if (_startTimeController.text.isNotEmpty) {
                    try {
                      // Helper function to parse time string to minutes
                      int parseTimeToMinutes(String timeStr) {
                        // Remove any whitespace
                        timeStr = timeStr.trim();

                        bool isPM = false;

                        // Check if time includes AM/PM
                        if (timeStr.contains('AM') || timeStr.contains('PM')) {
                          isPM = timeStr.contains('PM');
                          // Remove AM/PM
                          timeStr = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
                        }

                        // Split into hours and minutes
                        final parts = timeStr.split(':');
                        if (parts.length == 2) {
                          int hours = int.parse(parts[0]);
                          int minutes = int.parse(parts[1]);

                          // Adjust for PM
                          if (isPM && hours < 12) {
                            hours += 12;
                          }

                          // Adjust for 12 AM
                          if (!isPM && hours == 12) {
                            hours = 0;
                          }

                          return hours * 60 + minutes;
                        }

                        return -1; // Invalid format
                      }

                      // Parse times to minutes
                      final startMinutes = parseTimeToMinutes(_startTimeController.text);
                      final endMinutes = parseTimeToMinutes(value);

                      // Check if end time is before start time
                      if (startMinutes >= 0 && endMinutes >= 0 && endMinutes < startMinutes) {
                        return 'End time must be after or equal to start time';
                      }
                    } catch (e) {
                      // If there's an error parsing, we'll let other validators handle it
                    }
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start date
              TextFormField(
                controller: _startDateController,
                decoration: AppStyles.inputDecoration(
                  'Start Date (YYYY-MM-DD)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _showDatePicker(_startDateController),
                  ),
                ),
                readOnly: true,
                onTap: () => _showDatePicker(_startDateController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a start date';
                  }
                  // Simple date format validation (YYYY-MM-DD)
                  final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Please enter a valid date (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // End date (optional)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _endDateController,
                          decoration: AppStyles.inputDecoration(
                            'End Date (YYYY-MM-DD) - Optional',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _showDatePicker(_endDateController),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _showDatePicker(_endDateController),
                          validator: (value) {
                            // This is optional, so empty is fine
                            if (value == null || value.isEmpty) {
                              return null;
                            }

                            // Simple date format validation (YYYY-MM-DD)
                            final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                            if (!dateRegex.hasMatch(value)) {
                              return 'Please enter a valid date (YYYY-MM-DD)';
                            }

                            // Check that end date is after start date
                            try {
                              final startDate = DateFormat('yyyy-MM-dd').parse(_startDateController.text);
                              final endDate = DateFormat('yyyy-MM-dd').parse(value);
                              if (endDate.isBefore(startDate)) {
                                return 'End date must be after start date';
                              }
                            } catch (e) {
                              return 'Invalid date format';
                            }

                            return null;
                          },
                        ),
                      ),
                      // Separate clear button
                      if (_endDateController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _endDateController.clear();
                            });
                          },
                          tooltip: 'Clear end date',
                        ),
                    ],
                  ),
                  // Help text
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Leave blank for no end date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppStyles.secondaryTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Repeat every N weeks
              TextFormField(
                controller: _repeatController,
                decoration: AppStyles.inputDecoration('Repeat Every N Weeks'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final n = int.tryParse(value);
                    if (n == null || n < 1) {
                      return 'Please enter a valid number (minimum 1)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Form buttons
              Row(
                children: [
                  // Save button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addScheduleEntry,
                      style: AppStyles.primaryButtonStyle,
                      child: Text(_selectedScheduleEntry == null ? 'Add Schedule' : 'Update Schedule'),
                    ),
                  ),

                  // Show clear button only when editing
                  if (_selectedScheduleEntry != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        style: AppStyles.secondaryButtonStyle,
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build schedule entries list
  Widget _buildScheduleEntriesList() {
    // Combine existing and pending entries for display
    List<Map<String, dynamic>> allEntries = [];

    // Add existing entries that aren't being updated or deleted
    for (final entry in _scheduleEntries) {
      bool isBeingModified = _pendingScheduleEntries.any((pendingEntry) =>
        (pendingEntry['action'] == 'update' || pendingEntry['action'] == 'delete') &&
        pendingEntry['id'] == entry['id']);

      if (!isBeingModified) {
        allEntries.add(entry);
      }
    }

    // Add all pending entries except those marked for deletion
    for (final entry in _pendingScheduleEntries) {
      if (entry['action'] != 'delete') {
        allEntries.add(entry);
      }
    }

    // Group entries by day of week for better organization
    Map<String, List<Map<String, dynamic>>> entriesByDay = {};
    for (final entry in allEntries) {
      final day = entry['day_of_week'] as String;
      if (!entriesByDay.containsKey(day)) {
        entriesByDay[day] = [];
      }
      entriesByDay[day]!.add(entry);
    }

    // Sort days according to standard week order
    final sortedDays = entriesByDay.keys.toList()
      ..sort((a, b) {
        final aIndex = _daysOfWeek.indexOf(a);
        final bIndex = _daysOfWeek.indexOf(b);
        return aIndex.compareTo(bIndex);
      });

    // Sort entries within each day by start time
    for (final day in entriesByDay.keys) {
      entriesByDay[day]!.sort((a, b) {
        final aMinutes = _parseTimeToMinutes(a['start_time']);
        final bMinutes = _parseTimeToMinutes(b['start_time']);
        return aMinutes.compareTo(bMinutes);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with save button if there are pending changes
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            const Text(
              'Current Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_hasUnsavedChanges)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _pendingScheduleEntries = [];
                        _hasUnsavedChanges = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Changes discarded'),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _saveAllChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Schedule entries
        if (allEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No schedule entries found',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              ),
            ),
          )
        else
          // Display entries grouped by day
          ...sortedDays.map((day) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header - cleaner, more subtle styling
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${entriesByDay[day]!.length} time block${entriesByDay[day]!.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Entries for this day
                  ...entriesByDay[day]!.map(_buildScheduleEntryCard),
                ],
              ),
            );
          }),

        // Add a "Save Schedule" button at the bottom if there are pending changes
        if (_hasUnsavedChanges)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAllChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Save Schedule'),
              ),
            ),
          ),
      ],
    );
  }

  // Build schedule entry card
  Widget _buildScheduleEntryCard(Map<String, dynamic> entry) {
    // Check if this is a pending entry
    final bool isPending = entry['pending'] == true;

    // Format repeat text
    String repeatText = '';
    if (entry['repeat_every_n_weeks'] != null) {
      final int repeatWeeks = entry['repeat_every_n_weeks'];
      repeatText = repeatWeeks == 1
          ? 'Weekly'
          : 'Every $repeatWeeks weeks';
    }

    // Format date range
    String dateRangeText = 'From ${entry['start_date']}';
    if (entry['end_date'] != null && entry['end_date'].isNotEmpty) {
      dateRangeText += ' to ${entry['end_date']}';
    } else {
      dateRangeText += ' onwards';
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time block
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${entry['start_time']} - ${entry['end_time']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Date range and repeat info with action buttons
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateRangeText,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      if (repeatText.isNotEmpty)
                        Text(
                          repeatText,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action buttons - more subtle styling
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    IconButton(
                      onPressed: () => _editScheduleEntry(entry),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      color: Colors.grey.shade700,
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),

                    // Delete button
                    IconButton(
                      onPressed: () => isPending ? _removePendingEntry(entry) : _deleteScheduleEntry(entry),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: Colors.grey.shade700,
                      tooltip: 'Delete',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Remove a pending entry (local only, not sent to server)
  void _removePendingEntry(Map<String, dynamic> entry) {
    setState(() {
      // If this is an update to an existing entry, restore the original
      if (entry['action'] == 'update' && entry['original'] != null) {
        // No need to do anything, the original entry will remain in _scheduleEntries
      }

      // Remove from pending entries
      if (entry['temp_id'] != null) {
        _pendingScheduleEntries.removeWhere((e) => e['temp_id'] == entry['temp_id']);
      } else if (entry['id'] != null) {
        _pendingScheduleEntries.removeWhere((e) =>
          e['action'] == 'update' && e['id'] == entry['id']);
      }

      // Update unsaved changes flag
      _hasUnsavedChanges = _pendingScheduleEntries.isNotEmpty;
    });

    // Show message if still mounted
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Change removed'),
        ),
      );
    }
  }
}
