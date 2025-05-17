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

  // Working days state for each week (up to 4 weeks)
  final List<Map<String, bool>> workingDays = List.generate(
    4,
    (_) => {
      'MON': false,
      'TUE': false,
      'WED': false,
      'THU': false,
      'FRI': false,
      'SAT': false,
      'SUN': false,
    },
  );

  // Working hours state for each day in each week
  final List<Map<String, Map<String, TimeOfDay>>> workingHours = List.generate(
    4,
    (_) => {
      'MON': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'TUE': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'WED': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'THU': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'FRI': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'SAT': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
      'SUN': {'start': const TimeOfDay(hour: 9, minute: 0), 'end': const TimeOfDay(hour: 17, minute: 0)},
    },
  );

  // Break times state for each day in each week (multiple breaks)
  final List<Map<String, List<Map<String, TimeOfDay?>>>> breakTimes = List.generate(
    4,
    (_) => {
      'MON': [],
      'TUE': [],
      'WED': [],
      'THU': [],
      'FRI': [],
      'SAT': [],
      'SUN': [],
    },
  );

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
      body: SingleChildScrollView(
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
                Text(
                  endDate != null
                      ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                      : 'Select end date',
                  style: AppStyles.bodyStyle,
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
          onPressed: () {
            // TODO: Implement save functionality
            Navigator.of(context).pop();
          },
          style: AppStyles.primaryButtonStyle,
          child: const Text('Save Schedule'),
        ),
      ],
    );
  }
} 