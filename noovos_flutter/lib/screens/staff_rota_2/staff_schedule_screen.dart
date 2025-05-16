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

  // Form controllers for adding/editing schedule
  final _formKey = GlobalKey<FormState>();
  String _selectedDay = 'Monday';
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _repeatController = TextEditingController(text: '1');

  // Selected schedule entry for editing
  Map<String, dynamic>? _selectedScheduleEntry;

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

  // Save schedule entry
  Future<void> _saveScheduleEntry() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
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

      // Create schedule entry
      final Map<String, dynamic> scheduleEntry = {
        'day_of_week': _selectedDay,
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'start_date': _startDateController.text,
      };

      // Add optional fields if provided
      if (_endDateController.text.isNotEmpty) {
        scheduleEntry['end_date'] = _endDateController.text;
      }

      if (_repeatController.text.isNotEmpty) {
        scheduleEntry['repeat_every_n_weeks'] = int.tryParse(_repeatController.text) ?? 1;
      }

      // Create schedule list (we're replacing the entire schedule)
      final List<Map<String, dynamic>> schedule = [scheduleEntry];

      // Add all existing schedule entries except the one being edited
      for (final entry in _scheduleEntries) {
        // Skip the entry being edited
        if (_selectedScheduleEntry != null && entry['id'] == _selectedScheduleEntry!['id']) {
          continue;
        }

        // Add entry to schedule
        schedule.add({
          'day_of_week': entry['day_of_week'],
          'start_time': entry['start_time'],
          'end_time': entry['end_time'],
          'start_date': entry['start_date'],
          'end_date': entry['end_date'],
          'repeat_every_n_weeks': entry['repeat_every_n_weeks'],
        });
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
            // Clear form
            _clearForm();

            // Reload schedule
            _loadSchedule();

            // Call create_auto_staff_rota API to update the rota based on the new schedule
            _generateAutoStaffRota(businessId, staffId);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Schedule updated successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update schedule'),
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

  // Delete schedule entry
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

      // Add all existing schedule entries except the one being deleted
      for (final existingEntry in _scheduleEntries) {
        // Skip the entry being deleted
        if (existingEntry['id'] == entry['id']) {
          continue;
        }

        // Add entry to schedule
        schedule.add({
          'day_of_week': existingEntry['day_of_week'],
          'start_time': existingEntry['start_time'],
          'end_time': existingEntry['end_time'],
          'start_date': existingEntry['start_date'],
          'end_date': existingEntry['end_date'],
          'repeat_every_n_weeks': existingEntry['repeat_every_n_weeks'],
        });
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
            // Reload schedule
            _loadSchedule();

            // Call create_auto_staff_rota API to update the rota based on the updated schedule
            _generateAutoStaffRota(businessId, staffId);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Schedule entry deleted successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to delete schedule entry'),
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

  // Edit schedule entry
  void _editScheduleEntry(Map<String, dynamic> entry) {
    // Set selected entry
    setState(() {
      _selectedScheduleEntry = entry;

      // Set form values
      _selectedDay = entry['day_of_week'];
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
      _selectedDay = 'Monday';
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

              // Day of week dropdown
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
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a day';
                  }
                  return null;
                },
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
                      onPressed: _saveScheduleEntry,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        const Text(
          'Current Schedule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Schedule entries
        if (_scheduleEntries.isEmpty)
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
          ..._scheduleEntries.map(_buildScheduleEntryCard),
      ],
    );
  }

  // Build schedule entry card
  Widget _buildScheduleEntryCard(Map<String, dynamic> entry) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day and time
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${entry['day_of_week']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${entry['start_time']} - ${entry['end_time']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date range and repeat
            Text(
              dateRangeText,
              style: const TextStyle(
                color: AppStyles.secondaryTextColor,
              ),
            ),
            if (repeatText.isNotEmpty)
              Text(
                repeatText,
                style: const TextStyle(
                  color: AppStyles.secondaryTextColor,
                ),
              ),

            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                TextButton.icon(
                  onPressed: () => _editScheduleEntry(entry),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppStyles.primaryColor,
                  ),
                ),

                // Delete button
                TextButton.icon(
                  onPressed: () => _deleteScheduleEntry(entry),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
