/*
Set Schedule Screen
This screen allows managers to set recurring schedules for staff members.
Features:
- Select schedule type (weekly, bi-weekly, etc.)
- Set working days and hours for each week
- Define start and end dates
- Set break times for each working day
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../api/set_staff_schedule_api.dart';  // Import the API
import '../api/get_staff_schedule_api.dart';  // Import the GET API
import '../api/create_auto_staff_rota_api.dart';  // Import the auto rota API
import '../api/check_booking_integrity_api.dart';  // Import the booking integrity API

class SetScheduleScreen extends StatefulWidget {
  // Staff and business details
  final Map<String, dynamic> staff;
  final Map<String, dynamic> business;

  const SetScheduleScreen({
    Key? key,
    required this.staff,
    required this.business,
  }) : super(key: key);

  @override
  State<SetScheduleScreen> createState() => _SetScheduleScreenState();
}

class _SetScheduleScreenState extends State<SetScheduleScreen> {
  // Schedule type options
  final List<String> scheduleTypes = [
    'Every week',
    'Every 2 weeks',
    'Every 3 weeks',
    'Every 4 weeks'
  ];

  // State variables
  String selectedScheduleType = 'Every week';
  int selectedWeekIndex = 0;
  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = true;

  // Working days state for each week (up to 4 weeks)
  final List<Map<String, bool>> workingDays = List.generate(
    4,
    (_) => {
      'Monday': false,
      'Tuesday': false,
      'Wednesday': false,
      'Thursday': false,
      'Friday': false,
      'Saturday': false,
      'Sunday': false,
    },
  );

  // Working hours state for each day in each week
  final List<Map<String, Map<String, TimeOfDay>>> workingHours = List.generate(
    4,
    (_) => {
      'Monday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Tuesday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Wednesday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Thursday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Friday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Saturday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'Sunday': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
    },
  );

  // Break times state for each day in each week (multiple breaks)
  final List<Map<String, List<Map<String, TimeOfDay?>>>> breakTimes = List.generate(
    4,
    (_) => {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    },
  );

  @override
  void initState() {
    super.initState();
    _loadExistingSchedule();
  }

  // Load existing schedule from the API
  Future<void> _loadExistingSchedule() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Extract business and staff IDs, ensuring they are integers
      int businessId;
      int staffId;
      
      // Get business ID, handle both int and String types
      if (widget.business['id'] is int) {
        businessId = widget.business['id'];
      } else if (widget.business['id'] is String) {
        businessId = int.parse(widget.business['id']);
      } else {
        throw Exception('Business ID not found or invalid type');
      }
      
      // Get staff ID from appuser_id field, handle both int and String types
      if (widget.staff['appuser_id'] is int) {
        staffId = widget.staff['appuser_id'];
      } else if (widget.staff['appuser_id'] is String) {
        staffId = int.parse(widget.staff['appuser_id']);
      } else {
        // Try user_id as fallback
        if (widget.staff['user_id'] is int) {
          staffId = widget.staff['user_id'];
        } else if (widget.staff['user_id'] is String) {
          staffId = int.parse(widget.staff['user_id']);
        } else {
          throw Exception('Staff ID not found (looking for appuser_id or user_id field)');
        }
      }

      // Call API to get existing schedule
      final result = await GetStaffScheduleApi.getStaffSchedule(
        businessId: businessId,
        staffId: staffId,
      );

      if (result['success'] && result['schedules'] != null) {
        final schedules = result['schedules'] as List;
        
        if (schedules.isNotEmpty) {
          // Reset all selections first
          _resetAllSelections();
          
          // Determine the maximum week number to set the schedule type
          int maxWeek = 1;
          DateTime? firstStartDate;
          DateTime? lastEndDate;
          
          for (final schedule in schedules) {
            final week = schedule['week'] ?? 1;
            if (week > maxWeek) {
              maxWeek = week;
            }
            
            // Get start date from the first entry
            if (firstStartDate == null) {
              firstStartDate = _parseDate(schedule['start_date']);
            }
            
            // Keep track of end date
            if (schedule['end_date'] != null) {
              final parsedEndDate = _parseDate(schedule['end_date']);
              if (parsedEndDate != null) {
                if (lastEndDate == null || parsedEndDate.isAfter(lastEndDate)) {
                  lastEndDate = parsedEndDate;
                }
              }
            }
          }
          
          // Set schedule type based on max week
          if (maxWeek > 0 && maxWeek <= 4) {
            setState(() {
              selectedScheduleType = maxWeek == 1 ? 'Every week' : 'Every ${maxWeek} weeks';
              startDate = firstStartDate;
              endDate = lastEndDate;
            });
          }
          
          // Process each schedule entry
          for (final schedule in schedules) {
            final day = schedule['day_of_week'];
            final weekNum = (schedule['week'] ?? 1) - 1; // Convert to 0-based index
            
            if (weekNum >= 0 && weekNum < 4 && workingDays[weekNum].containsKey(day)) {
              // Parse times
              final startTime = _parseTimeOfDay(schedule['start_time']);
              final endTime = _parseTimeOfDay(schedule['end_time']);
              
              // Update working days and hours
              setState(() {
                workingDays[weekNum][day] = true;
                if (startTime != null) {
                  workingHours[weekNum][day]!['start'] = startTime;
                }
                if (endTime != null) {
                  workingHours[weekNum][day]!['end'] = endTime;
                }
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading existing schedule: $e');
      // Show error message if needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading existing schedule: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Parse date string in YYYY-MM-DD format
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      // Split by - and parse components
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[0]), // Year
          int.parse(parts[1]), // Month
          int.parse(parts[2]), // Day
        );
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return null;
  }
  
  // Parse time string (e.g., "09:00 AM") to TimeOfDay
  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    try {
      // Expected format: "09:00 AM" or "05:00 PM"
      final parts = timeStr.trim().split(' ');
      if (parts.length == 2) {
        final timeParts = parts[0].split(':');
        if (timeParts.length == 2) {
          int hours = int.parse(timeParts[0]);
          int minutes = int.parse(timeParts[1]);
          final period = parts[1]; // "AM" or "PM"
          
          // Adjust for 12-hour format
          if (period == 'PM' && hours < 12) {
            hours += 12;
          } else if (period == 'AM' && hours == 12) {
            hours = 0;
          }
          
          return TimeOfDay(hour: hours, minute: minutes);
        }
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }
  
  // Reset all selections
  void _resetAllSelections() {
    for (int i = 0; i < 4; i++) {
      workingDays[i].forEach((day, _) {
        workingDays[i][day] = false;
      });
      
      breakTimes[i].forEach((day, _) {
        breakTimes[i][day] = [];
      });
    }
  }

  // Add a new break slot to a specific day
  void _addBreak(String day) {
    setState(() {
      breakTimes[selectedWeekIndex][day]!.add({
        'start': null,
        'end': null,
      });
    });
  }

  // Remove a break slot from a specific day
  void _removeBreak(String day, int breakIndex) {
    setState(() {
      breakTimes[selectedWeekIndex][day]!.removeAt(breakIndex);
    });
  }

  // Copy all settings from week 1 to the current week
  void _copyFromWeekOne() {
    // Perform the copy without confirmation
    setState(() {
      // Copy working days
      workingDays[selectedWeekIndex].forEach((day, _) {
        workingDays[selectedWeekIndex][day] = workingDays[0][day]!;
      });
      
      // Copy working hours
      workingHours[selectedWeekIndex].forEach((day, _) {
        workingHours[selectedWeekIndex][day] = {
          'start': workingHours[0][day]!['start']!,
          'end': workingHours[0][day]!['end']!,
        };
      });
      
      // Copy break times
      breakTimes[selectedWeekIndex].forEach((day, _) {
        // Clear existing breaks
        breakTimes[selectedWeekIndex][day] = [];
        
        // Copy breaks from week 1
        for (final breakTime in breakTimes[0][day]!) {
          breakTimes[selectedWeekIndex][day]!.add({
            'start': breakTime['start'],
            'end': breakTime['end'],
          });
        }
      });
    });
    
    // Show subtle feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Week 1 schedule copied'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppStyles.primaryColor.withOpacity(0.8),
      ),
    );
  }

  // Get number of weeks based on schedule type
  int get numberOfWeeks {
    // For "Every week" return 1, otherwise parse the number
    if (selectedScheduleType == 'Every week') {
      return 1;
    }
    // Extract number from strings like "Every 2 weeks"
    final match = RegExp(r'Every (\d+) weeks').firstMatch(selectedScheduleType);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  @override
  Widget build(BuildContext context) {
    // Get staff name for display
    final String firstName = widget.staff['first_name'] ?? '';
    final String lastName = widget.staff['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Staff Schedule'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staff name display
                  Text(
                    fullName,
                    style: AppStyles.headingStyle,
                  ),
                  const Divider(height: 32),

                  // Schedule type selector
                  _buildScheduleTypeSelector(),
                  const SizedBox(height: 24),

                  // Date range selectors
                  _buildDateRangeSelectors(),
                  const SizedBox(height: 24),

                  // Week selector tabs
                  _buildWeekTabs(),
                  const SizedBox(height: 16),

                  // Working days and hours
                  _buildWorkingDaysSection(),
                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
    );
  }

  // Build schedule type dropdown
  Widget _buildScheduleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule Type', style: AppStyles.subheadingStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedScheduleType,
          decoration: AppStyles.inputDecoration('Select Type'),
          items: scheduleTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedScheduleType = value;
                selectedWeekIndex = 0;
              });
            }
          },
        ),
      ],
    );
  }

  // Build date range selectors
  Widget _buildDateRangeSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start date picker
        const Text('Start Date', style: AppStyles.subheadingStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: startDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => startDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  startDate != null
                      ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                      : 'Select start date',
                  style: AppStyles.bodyStyle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // End date picker (optional)
        const Text('End Date (Optional)', style: AppStyles.subheadingStyle),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: endDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() => endDate = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    endDate != null
                        ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                        : 'Select end date',
                    style: AppStyles.bodyStyle,
                  ),
                ),
                if (endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() => endDate = null);
                    },
                    tooltip: 'Clear date',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Build week selector tabs
  Widget _buildWeekTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Week', style: AppStyles.subheadingStyle),
        const SizedBox(height: 8),
        
        // Week selector buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(numberOfWeeks, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => selectedWeekIndex = index);
                  },
                  style: selectedWeekIndex == index
                      ? AppStyles.primaryButtonStyle
                      : AppStyles.secondaryButtonStyle,
                  child: Text('Week ${index + 1}'),
                ),
              );
            }),
          ),
        ),
        
        // Copy from Week 1 button (only show for weeks 2, 3, and 4)
        if (selectedWeekIndex > 0) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _copyFromWeekOne,
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.primaryColor,
            ),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy from Week 1'),
          ),
        ],
      ],
    );
  }

  // Build working days section
  Widget _buildWorkingDaysSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Working Days and Hours', style: AppStyles.subheadingStyle),
        const SizedBox(height: 16),
        ...workingDays[selectedWeekIndex].entries.map((entry) {
          final day = entry.key;
          final isSelected = entry.value;
          return _buildDayRow(day, isSelected);
        }).toList(),
      ],
    );
  }

  // Build individual day row with time pickers
  Widget _buildDayRow(String day, bool isSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Day toggle
            Row(
              children: [
                Switch(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      workingDays[selectedWeekIndex][day] = value;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(day, style: AppStyles.bodyStyle),
              ],
            ),

            // Show time pickers if day is selected
            if (isSelected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      'Start Time',
                      workingHours[selectedWeekIndex][day]!['start']!,
                      (time) {
                        setState(() {
                          workingHours[selectedWeekIndex][day]!['start'] = time;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      'End Time',
                      workingHours[selectedWeekIndex][day]!['end']!,
                      (time) {
                        setState(() {
                          workingHours[selectedWeekIndex][day]!['end'] = time;
                        });
                      },
                    ),
                  ),
                ],
              ),

              // Break time section
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Breaks:', style: AppStyles.bodyStyle),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _addBreak(day),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Break'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Show existing breaks or a message if none
                  if (breakTimes[selectedWeekIndex][day]!.isEmpty)
                    const Text(
                      'No breaks added',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    )
                  else
                    ...breakTimes[selectedWeekIndex][day]!.asMap().entries.map((entry) {
                      final breakIndex = entry.key;
                      final breakTime = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Text('Break ${breakIndex + 1}:', style: AppStyles.captionStyle),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildBreakTimePicker(
                                'Start',
                                breakTime['start'],
                                (time) {
                                  setState(() {
                                    breakTimes[selectedWeekIndex][day]![breakIndex]['start'] = time;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildBreakTimePicker(
                                'End',
                                breakTime['end'],
                                (time) {
                                  setState(() {
                                    breakTimes[selectedWeekIndex][day]![breakIndex]['end'] = time;
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeBreak(day, breakIndex),
                              tooltip: 'Remove break',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Build time picker button
  Widget _buildTimePicker(
    String label,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.captionStyle),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );
            if (time != null) {
              onTimeSelected(time);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}',
              style: AppStyles.bodyStyle,
            ),
          ),
        ),
      ],
    );
  }

  // Build break time picker button
  Widget _buildBreakTimePicker(
    String label,
    TimeOfDay? initialTime,
    Function(TimeOfDay?) onTimeSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppStyles.captionStyle),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: initialTime ?? const TimeOfDay(hour: 12, minute: 0),
            );
            onTimeSelected(time);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              initialTime != null
                  ? '${initialTime.hour.toString().padLeft(2, '0')}:${initialTime.minute.toString().padLeft(2, '0')}'
                  : 'Set time',
              style: AppStyles.bodyStyle,
            ),
          ),
        ),
      ],
    );
  }

  // Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppStyles.secondaryButtonStyle,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 16),

        // Save button
        ElevatedButton(
          onPressed: () async {
            if (startDate == null) {
              // Show error if start date is not selected
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select a start date'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              return;
            }

            // Check if at least one day is selected in any week
            bool hasDaysSelected = false;
            final int weeks = numberOfWeeks;
            
            for (int i = 0; i < weeks; i++) {
              final daysInWeek = workingDays[i];
              if (daysInWeek.values.contains(true)) {
                hasDaysSelected = true;
                break;
              }
            }

            if (!hasDaysSelected) {
              // Show error if no working days are selected
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select at least one working day'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
              return;
            }

            // Prepare schedule entries
            final schedule = _prepareScheduleData();
            
            // Extract business and staff IDs, ensuring they are integers
            int businessId;
            int staffId;
            
            try {
              // Get business ID, handle both int and String types
              if (widget.business['id'] is int) {
                businessId = widget.business['id'];
              } else if (widget.business['id'] is String) {
                businessId = int.parse(widget.business['id']);
              } else {
                throw Exception('Business ID not found or invalid type');
              }
              
              // Get staff ID from appuser_id field, handle both int and String types
              if (widget.staff['appuser_id'] is int) {
                staffId = widget.staff['appuser_id'];
              } else if (widget.staff['appuser_id'] is String) {
                staffId = int.parse(widget.staff['appuser_id']);
              } else {
                // Try user_id as fallback
                if (widget.staff['user_id'] is int) {
                  staffId = widget.staff['user_id'];
                } else if (widget.staff['user_id'] is String) {
                  staffId = int.parse(widget.staff['user_id']);
                } else {
                  throw Exception('Staff ID not found (looking for appuser_id or user_id field)');
                }
              }
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                // Check if this is a multi-week schedule
                bool isMultiWeekSchedule = selectedScheduleType != 'Every week';
                
                // Call API to save schedule
                final result = await SetStaffScheduleApi.setStaffSchedule(
                  businessId: businessId,
                  staffId: staffId,
                  schedule: schedule,
                  force: isMultiWeekSchedule, // Force bypass conflict check for multi-week schedules
                );
                
                // Close loading indicator
                Navigator.of(context).pop();
                
                if (result['success']) {
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Schedule saved successfully'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  
                  // Call create_auto_staff_rota API and check bookings
                  try {
                    // First generate the auto rota
                    final rotaResult = await CreateAutoStaffRotaApi.createAutoStaffRota(
                      businessId: businessId,
                      staffId: staffId,
                    );
                    
                    print('Auto rota creation result: $rotaResult');
                    
                    // Check for orphaned bookings
                    final bookingIntegrityResult = await CheckBookingIntegrityApi.checkBookingIntegrity(
                      businessId: businessId,
                      staffId: staffId,
                    );
                    
                    print('Booking integrity check result: $bookingIntegrityResult');
                    
                    // Only return to previous screen if no orphaned bookings or after showing the dialog
                    bool hasShownDialog = false;
                    
                    if (bookingIntegrityResult['success'] == true && 
                        bookingIntegrityResult['count'] > 0) {
                      // Get orphaned bookings
                      final orphanedBookings = bookingIntegrityResult['orphaned_bookings'] as List;
                      
                      print('Found ${orphanedBookings.length} orphaned bookings');
                      
                      // Display alert dialog with up to 3 orphaned bookings
                      if (context.mounted && orphanedBookings.isNotEmpty) {
                        hasShownDialog = true;
                        
                        // Build the message content
                        final messageBuilder = StringBuffer();
                        messageBuilder.write('The following bookings no longer have corresponding staff rota entries:\n\n');
                        
                        final displayCount = orphanedBookings.length > 3 ? 3 : orphanedBookings.length;
                        
                        for (int i = 0; i < displayCount; i++) {
                          final booking = orphanedBookings[i];
                          final date = booking['booking_date'] ?? 'Unknown date';
                          final startTime = booking['start_time']?.toString().substring(0, 5) ?? 'Unknown time';
                          final customerName = booking['customer_name'] ?? 'Unknown customer';
                          final serviceName = booking['service_name'] ?? 'Unknown service';
                          
                          messageBuilder.write('• $date at $startTime - $serviceName for $customerName\n');
                        }
                        
                        if (orphanedBookings.length > 3) {
                          messageBuilder.write('\nAnd ${orphanedBookings.length - 3} more...');
                        }
                        
                        // Show the alert dialog and wait for it to close before returning
                        await showDialog(
                          context: context,
                          barrierDismissible: false, // User must tap button
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              title: const Text('Affected Bookings'),
                              content: SingleChildScrollView(
                                child: Text(messageBuilder.toString()),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                    
                    // Now we can safely return to the previous screen
                    if (context.mounted) {
                      Navigator.of(context).pop(true); // Return success result
                    }
                  } catch (e) {
                    print('Error in post-schedule update process: $e');
                    // Still return to previous screen even if the additional checks fail
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  }
                } else {
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Failed to save schedule'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                }
              } catch (e) {
                // Close loading indicator and show error
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('An error occurred: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            } catch (e) {
              // Show error for ID parsing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error with business or staff ID: $e'),
                  backgroundColor: Colors.red.shade700,
                ),
              );
            }
          },
          style: AppStyles.primaryButtonStyle,
          child: const Text('Save Schedule'),
        ),
      ],
    );
  }
  
  // Prepare schedule data for API
  List<Map<String, dynamic>> _prepareScheduleData() {
    final List<Map<String, dynamic>> scheduleEntries = [];
    final int weeks = numberOfWeeks;
    
    // Get repeat cycle length from schedule type (how many weeks in the full cycle)
    int repeatCycleLength = 1;
    if (selectedScheduleType != 'Every week') {
      // Extract number from strings like "Every 2 weeks"
      final match = RegExp(r'Every (\d+) weeks').firstMatch(selectedScheduleType);
      repeatCycleLength = match != null ? int.parse(match.group(1)!) : 1;
    }
    
    // Format dates to YYYY-MM-DD
    final String formattedStartDate = '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
    
    // Format end date if it exists
    String? formattedEndDate;
    if (endDate != null) {
      formattedEndDate = '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
    }
    
    // Process each week's schedule
    for (int weekIndex = 0; weekIndex < weeks; weekIndex++) {
      // Loop through each day of the week
      workingDays[weekIndex].forEach((day, isSelected) {
        // Only add days that are selected as working days
        if (isSelected) {
          // Format times to HH:MM
          final startHour = workingHours[weekIndex][day]!['start']!.hour.toString().padLeft(2, '0');
          final startMinute = workingHours[weekIndex][day]!['start']!.minute.toString().padLeft(2, '0');
          final endHour = workingHours[weekIndex][day]!['end']!.hour.toString().padLeft(2, '0');
          final endMinute = workingHours[weekIndex][day]!['end']!.minute.toString().padLeft(2, '0');
          
          final String formattedStartTime = '$startHour:$startMinute';
          final String formattedEndTime = '$endHour:$endMinute';
          
          // Calculate start date for this entry
          String entryStartDate = formattedStartDate;
          if (repeatCycleLength > 1 && weekIndex > 0) {
            // Calculate the offset date by adding (weekIndex * 7) days to the start date
            final offsetStartDate = startDate!.add(Duration(days: weekIndex * 7));
            entryStartDate = '${offsetStartDate.year}-${offsetStartDate.month.toString().padLeft(2, '0')}-${offsetStartDate.day.toString().padLeft(2, '0')}';
          }
          
          // Create schedule entry
          final Map<String, dynamic> entry = {
            'day_of_week': day,
            'start_time': formattedStartTime,
            'end_time': formattedEndTime,
            'start_date': entryStartDate,
            // Set week to indicate which week in the rotation (1-based)
            'week': weekIndex + 1,
          };
          
          // Add end date if specified
          if (formattedEndDate != null) {
            entry['end_date'] = formattedEndDate;
          }
          
          // Add entry to schedule list
          scheduleEntries.add(entry);
        }
      });
    }
    
    return scheduleEntries;
  }
} 