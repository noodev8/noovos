/*
Add Staff Rota Screen
This screen allows business owners to add, edit, and delete manual staff rota entries
for a specific staff member. It displays the rota for the selected week and provides
a form for managing individual rota entries.
*/

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../styles/app_styles.dart';
import '../../api/get_staff_rota_api.dart';
import '../../api/add_staff_rota_api.dart';
import '../../api/update_staff_rota_api.dart';
import '../../api/delete_staff_rota_api.dart';
import '../../widgets/week_picker_widget.dart';

class AddStaffRotaScreen extends StatefulWidget {
  // Business details
  final Map<String, dynamic> business;

  // Staff details
  final Map<String, dynamic> staff;

  // Week selection data from previous screen
  final Map<String, dynamic> weekData;

  // Constructor
  const AddStaffRotaScreen({
    Key? key,
    required this.business,
    required this.staff,
    required this.weekData,
  }) : super(key: key);

  @override
  State<AddStaffRotaScreen> createState() => _AddStaffRotaScreenState();
}

class _AddStaffRotaScreenState extends State<AddStaffRotaScreen> {
  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;

  // Error message
  String? _errorMessage;

  // Rota entries
  List<Map<String, dynamic>> _rotaEntries = [];

  // Selected entry for editing
  Map<String, dynamic>? _selectedEntry;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  // Date formatters
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _displayDateFormat = DateFormat('EEE, MMM d, yyyy');
  final _timeFormat = DateFormat('HH:mm');
  final _displayTimeFormat = DateFormat('h:mm a');

  // Week selection
  int _selectedWeekIndex = 0;
  Map<String, dynamic>? _selectedWeekData;

  @override
  void initState() {
    super.initState();

    // Set initial week index from passed data
    _selectedWeekIndex = widget.weekData['index'] ?? 0;
    _selectedWeekData = widget.weekData;

    // Load rota entries
    _loadRotaEntries();
  }

  @override
  void dispose() {
    // Dispose controllers
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  // Handle week selection from the WeekPickerWidget
  void _onWeekSelected(int index, Map<String, dynamic> weekData) {
    if (index != _selectedWeekIndex || _selectedWeekData != weekData) {
      setState(() {
        _selectedWeekIndex = index;
        _selectedWeekData = weekData;
      });

      // Reload rota entries for the new week
      _loadRotaEntries();
    }
  }

  // Load rota entries for the selected staff and week
  Future<void> _loadRotaEntries() async {
    // Don't load if we don't have selected week data
    if (_selectedWeekData == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get business ID and staff ID
      final int businessId = widget.business['id'];
      final int staffId = widget.staff['appuser_id'];

      // Get date range for the selected week
      final String startDate = _selectedWeekData!['apiStartDate'] ?? DateFormat('yyyy-MM-dd').format(_selectedWeekData!['startDate']);
      final String endDate = _selectedWeekData!['apiEndDate'] ?? DateFormat('yyyy-MM-dd').format(_selectedWeekData!['endDate']);

      // Call API to get rota entries
      final result = await GetStaffRotaApi.getStaffRota(
        businessId: businessId,
        staffId: staffId,
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success']) {
            _rotaEntries = List<Map<String, dynamic>>.from(result['rota'] ?? []);
          } else {
            _errorMessage = result['message'] ?? 'Failed to load rota entries';
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

  // Add a new rota entry
  Future<void> _addRotaEntry() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get business ID and staff ID
      final int businessId = widget.business['id'];
      final int staffId = widget.staff['appuser_id'];

      // Get form values
      final String rotaDate = _dateController.text;
      final String startTime = _startTimeController.text;
      final String endTime = _endTimeController.text;

      // Create entry object
      final List<Map<String, dynamic>> entries = [
        {
          'staff_id': staffId,
          'rota_date': rotaDate,
          'start_time': startTime,
          'end_time': endTime,
        }
      ];

      // Call API to add rota entry
      final result = await AddStaffRotaApi.addStaffRota(
        businessId: businessId,
        entries: entries,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;

          if (result['success']) {
            // Clear form
            _clearForm();

            // Reload rota entries
            _loadRotaEntries();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Rota entry added successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to add rota entry'),
                backgroundColor: AppStyles.errorColor,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

  // Update an existing rota entry
  Future<void> _updateRotaEntry() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if we have a selected entry
    if (_selectedEntry == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Get business ID
      final int businessId = widget.business['id'];

      // Get rota ID from selected entry
      final int rotaId = _selectedEntry!['id'];

      // Get form values
      final String rotaDate = _dateController.text;
      final String startTime = _startTimeController.text;
      final String endTime = _endTimeController.text;

      // Call API to update rota entry
      final result = await UpdateStaffRotaApi.updateStaffRota(
        businessId: businessId,
        rotaId: rotaId,
        rotaDate: rotaDate,
        startTime: startTime,
        endTime: endTime,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;

          if (result['success']) {
            // Clear form and selected entry
            _clearForm();

            // Reload rota entries
            _loadRotaEntries();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Rota entry updated successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update rota entry'),
                backgroundColor: AppStyles.errorColor,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
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

  // Delete a rota entry
  Future<void> _deleteRotaEntry(int rotaId) async {
    // Show confirmation dialog
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this rota entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get business ID
      final int businessId = widget.business['id'] as int;

      // Call API to delete rota entry
      final result = await DeleteStaffRotaApi.deleteStaffRota(
        businessId: businessId,
        rotaId: rotaId,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;

          if (result['success'] as bool) {
            // If the deleted entry was selected, clear the form
            if (_selectedEntry != null && (_selectedEntry!['id'] as int) == rotaId) {
              _clearForm();
            }

            // Reload rota entries
            _loadRotaEntries();

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String? ?? 'Rota entry deleted successfully'),
                backgroundColor: AppStyles.successColor,
              ),
            );
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String? ?? 'Failed to delete rota entry'),
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

  // Clear the form and reset selected entry
  void _clearForm() {
    setState(() {
      _selectedEntry = null;
      _dateController.clear();
      _startTimeController.clear();
      _endTimeController.clear();
    });
  }

  // Set form values for editing an entry

  // Format a date string for display
  String _formatDateForDisplay(String dateStr) {
    try {
      final date = _dateFormat.parse(dateStr);
      return _displayDateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // Format a time string for display
  String _formatTimeForDisplay(String timeStr) {
    try {
      // Handle both 24-hour and 12-hour formats
      if (timeStr.contains('AM') || timeStr.contains('PM')) {
        // Already in 12-hour format
        return timeStr;
      } else {
        // Convert from 24-hour to 12-hour format
        final time = _timeFormat.parse(timeStr);
        return _displayTimeFormat.format(time);
      }
    } catch (e) {
      return timeStr;
    }
  }

  // Group rota entries by date
  Map<String, List<Map<String, dynamic>>> _getGroupedEntries() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final entry in _rotaEntries) {
      final String date = entry['rota_date'] as String;

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }

      grouped[date]!.add(entry);
    }

    return grouped;
  }

  // Show add/edit entry dialog
  Future<void> _showAddEditEntryDialog({Map<String, dynamic>? entry}) async {
    // Reset form
    _clearForm();
    
    // If we have an entry, set form values for editing
    if (entry != null) {
      setState(() {
        _selectedEntry = entry;
        _dateController.text = entry['rota_date'] as String;
        _startTimeController.text = entry['start_time'] as String;
        _endTimeController.text = entry['end_time'] as String;
      });
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry == null ? 'Add Rota Entry' : 'Edit Rota Entry'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date field
                TextFormField(
                  controller: _dateController,
                  decoration: AppStyles.inputDecoration(
                    'Date',
                    hint: 'YYYY-MM-DD',
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () async {
                    // Ensure we have week data
                    if (_selectedWeekData == null) {
                      return;
                    }
                    
                    // Get date range for the selected week
                    final DateTime startDate = _selectedWeekData!['startDate'] as DateTime;
                    final DateTime endDate = _selectedWeekData!['endDate'] as DateTime;

                    // Show date picker
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dateController.text.isNotEmpty
                          ? _dateFormat.parse(_dateController.text)
                          : DateTime.now().isBefore(startDate) ? startDate : DateTime.now().isAfter(endDate) ? endDate : DateTime.now(),
                      firstDate: startDate,
                      lastDate: endDate,
                    );

                    if (pickedDate != null) {
                      setState(() {
                        _dateController.text = _dateFormat.format(pickedDate);
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start time field
                TextFormField(
                  controller: _startTimeController,
                  decoration: AppStyles.inputDecoration(
                    'Start Time',
                    hint: 'HH:MM',
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  readOnly: true,
                  onTap: () async {
                    // Show time picker
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _startTimeController.text.isNotEmpty
                          ? TimeOfDay.fromDateTime(_timeFormat.parse(_startTimeController.text))
                          : TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        // Format time as HH:MM
                        _startTimeController.text =
                            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a start time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // End time field
                TextFormField(
                  controller: _endTimeController,
                  decoration: AppStyles.inputDecoration(
                    'End Time',
                    hint: 'HH:MM',
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  readOnly: true,
                  onTap: () async {
                    // Show time picker
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: _endTimeController.text.isNotEmpty
                          ? TimeOfDay.fromDateTime(_timeFormat.parse(_endTimeController.text))
                          : TimeOfDay.now(),
                    );

                    if (pickedTime != null) {
                      setState(() {
                        // Format time as HH:MM
                        _endTimeController.text =
                            '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an end time';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          
          // Save button
          ElevatedButton(
            onPressed: _isSaving 
              ? null 
              : () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, true); // Close dialog and return true to save
                  }
                },
            style: AppStyles.primaryButtonStyle,
            child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(_selectedEntry == null ? 'Add Entry' : 'Update Entry'),
          ),
        ],
      ),
    ).then((result) async {
      // If dialog was confirmed, save the entry
      if (result == true) {
        if (_selectedEntry == null) {
          await _addRotaEntry();
        } else {
          await _updateRotaEntry();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Rota - ${widget.staff['first_name']} ${widget.staff['last_name']}'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : Stack(
              children: [
                _buildRotaManagementUI(),
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
        padding: const EdgeInsets.all(16),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppStyles.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRotaEntries,
              style: AppStyles.primaryButtonStyle,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Build rota management UI
  Widget _buildRotaManagementUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week selection (optional)
          _buildWeekSelectionSection(),

          const SizedBox(height: 24),

          // Rota entries list with add button
          _buildRotaEntriesList(),
        ],
      ),
    );
  }

  // Build week selection section
  Widget _buildWeekSelectionSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: WeekPickerWidget(
          numberOfWeeks: 8,
          initialWeekIndex: _selectedWeekIndex,
          onWeekSelected: _onWeekSelected,
        ),
      ),
    );
  }

  // Build rota entries list
  Widget _buildRotaEntriesList() {
    // Get grouped entries
    final groupedEntries = _getGroupedEntries();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title and add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rota Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditEntryDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Entry'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // No entries message
        if (groupedEntries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No rota entries found for this week',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppStyles.secondaryTextColor,
                  ),
                ),
              ),
            ),
          )
        else
          // Entries list grouped by date
          ...groupedEntries.entries.map((entry) {
            final String date = entry.key;
            final List<Map<String, dynamic>> entries = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _formatDateForDisplay(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Entries for this date
                ...entries.map((rotaEntry) => _buildRotaEntryCard(rotaEntry)),

                const SizedBox(height: 16),
              ],
            );
          }).toList(),
      ],
    );
  }

  // Build a card for a single rota entry
  Widget _buildRotaEntryCard(Map<String, dynamic> entry) {
    // Format times for display
    final startTime = _formatTimeForDisplay(entry['start_time']);
    final endTime = _formatTimeForDisplay(entry['end_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Time info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showAddEditEntryDialog(entry: entry),
              tooltip: 'Edit',
              color: AppStyles.primaryColor,
            ),

            // Delete button
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteRotaEntry(entry['id']),
              tooltip: 'Delete',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}