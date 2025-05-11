
// /*
// Business Staff Rota Management Screen
// This screen allows business owners to manage staff working hours (rota)
// Features:
// - View staff rota entries
// - Add new rota entries (single or bulk)
// - Edit existing rota entries
// - Delete rota entries
// */

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../styles/app_styles.dart';
// import '../api/get_business_staff_api.dart';
// import '../api/get_staff_rota_api.dart';
// import '../api/add_staff_rota_api.dart';

// class BusinessStaffRotaScreen extends StatefulWidget {
//   // Business details
//   final Map<String, dynamic> business;

//   // Constructor
//   const BusinessStaffRotaScreen({
//     Key? key,
//     required this.business,
//   }) : super(key: key);

//   @override
//   State<BusinessStaffRotaScreen> createState() => _BusinessStaffRotaScreenState();
// }

// class _BusinessStaffRotaScreenState extends State<BusinessStaffRotaScreen> {
//   // Loading state
//   bool _isLoading = false;

//   // Error message
//   String? _errorMessage;

//   // Staff list
//   List<Map<String, dynamic>> _staffList = [];

//   // Selected staff member
//   Map<String, dynamic>? _selectedStaff;

//   // Selected date
//   DateTime _selectedDate = DateTime.now();

//   // Time controllers
//   final TextEditingController _startTimeController = TextEditingController(text: '09:00');
//   final TextEditingController _endTimeController = TextEditingController(text: '17:00');

//   // Rota entries
//   List<Map<String, dynamic>> _rotaEntries = [];

//   // Current month for rota display
//   DateTime _currentMonth = DateTime.now();

//   // Loading rota state
//   bool _loadingRota = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadStaff();
//   }

//   @override
//   void dispose() {
//     _startTimeController.dispose();
//     _endTimeController.dispose();
//     super.dispose();
//   }

//   // Load staff members from API
//   Future<void> _loadStaff() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//       // Reset selected staff to avoid dropdown issues when refreshing
//       _selectedStaff = null;
//       // Clear rota entries when staff selection changes
//       _rotaEntries = [];
//     });

//     try {
//       // Get business ID
//       final int businessId = widget.business['id'];

//       // Call API to get staff members
//       final result = await GetBusinessStaffApi.getBusinessStaff(businessId);

//       if (mounted) {
//         setState(() {
//           _isLoading = false;

//           if (result['success']) {
//             // Process staff data
//             final List<Map<String, dynamic>> staffData = List<Map<String, dynamic>>.from(result['staff']);

//             // Filter to only include active staff members
//             _staffList = staffData
//                 .where((staff) => staff['status'] == 'active')
//                 .map((staff) {
//                   // Format staff data for dropdown
//                   final String firstName = staff['first_name'] ?? '';
//                   final String lastName = staff['last_name'] ?? '';
//                   final String fullName = '$firstName $lastName'.trim();

//                   return {
//                     'id': staff['appuser_id'],
//                     'name': fullName,
//                     'email': staff['email'] ?? '',
//                     'role': staff['role'] ?? '',
//                   };
//                 })
//                 .toList();
//           } else {
//             _errorMessage = result['message'] ?? 'Failed to load staff members';
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _errorMessage = 'An error occurred: $e';
//         });
//       }
//     }
//   }

//   // Load rota entries for selected staff
//   Future<void> _loadRotaEntries() async {
//     // Check if a staff member is selected
//     if (_selectedStaff == null) {
//       setState(() {
//         _rotaEntries = [];
//       });
//       return;
//     }

//     setState(() {
//       _loadingRota = true;
//     });

//     try {
//       // Get business ID and staff ID
//       final int businessId = widget.business['id'];
//       final int staffId = _selectedStaff!['id'];

//       // Calculate start and end dates (selected month)
//       final DateTime startDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
//       final DateTime endDate = DateTime(_currentMonth.year, _currentMonth.month + 1, 0); // Last day of month

//       // Format dates for API
//       final String startDateStr = _formatDate(startDate);
//       final String endDateStr = _formatDate(endDate);

//       // Call API to get rota entries
//       final result = await GetStaffRotaApi.getStaffRota(
//         businessId: businessId,
//         staffId: staffId,
//         startDate: startDateStr,
//         endDate: endDateStr,
//       );

//       if (mounted) {
//         setState(() {
//           _loadingRota = false;

//           if (result['success']) {
//             _rotaEntries = List<Map<String, dynamic>>.from(result['rota']);
//             // Sort entries by date and time
//             _rotaEntries.sort((a, b) {
//               // First compare by date
//               final int dateCompare = a['rota_date'].compareTo(b['rota_date']);
//               if (dateCompare != 0) return dateCompare;

//               // Then compare by start time
//               return a['start_time'].compareTo(b['start_time']);
//             });
//           } else {
//             // Show error in snackbar but don't set error message (to keep UI visible)
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(result['message'] ?? 'Failed to load rota entries'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//             _rotaEntries = [];
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _loadingRota = false;
//           _rotaEntries = [];
//         });

//         // Show error in snackbar
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('An error occurred: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Format date (YYYY-MM-DD)
//   String _formatDate(DateTime date) {
//     return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
//   }

//   // Format display date (e.g., "Monday, 1 May 2023")
//   String _formatDisplayDate(String dateStr) {
//     try {
//       final DateTime date = DateTime.parse(dateStr);
//       return DateFormat('EEEE, d MMMM yyyy').format(date);
//     } catch (e) {
//       return dateStr;
//     }
//   }

//   // Add a new rota entry
//   Future<void> _addRotaEntry() async {
//     // Check if a staff member is selected
//     if (_selectedStaff == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select a staff member first'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Validate time inputs
//     final String startTime = _startTimeController.text;
//     final String endTime = _endTimeController.text;

//     // Simple validation - check if end time is after start time
//     final List<String> startParts = startTime.split(':');
//     final List<String> endParts = endTime.split(':');

//     if (startParts.length != 2 || endParts.length != 2) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Invalid time format. Please use HH:MM format.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final int startHour = int.parse(startParts[0]);
//     final int startMinute = int.parse(startParts[1]);
//     final int endHour = int.parse(endParts[0]);
//     final int endMinute = int.parse(endParts[1]);

//     if (endHour < startHour || (endHour == startHour && endMinute <= startMinute)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('End time must be after start time'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Show loading indicator
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Get business ID and staff ID
//       final int businessId = widget.business['id'];
//       final int staffId = _selectedStaff!['id'];

//       // Format date for API
//       final String dateStr = _formatDate(_selectedDate);

//       // Create entry
//       final Map<String, dynamic> entry = {
//         'staff_id': staffId,
//         'rota_date': dateStr,
//         'start_time': startTime,
//         'end_time': endTime,
//       };

//       // Call API to add rota entry
//       final result = await AddStaffRotaApi.addStaffRota(
//         businessId: businessId,
//         entries: [entry],
//       );

//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });

//         if (result['success']) {
//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result['message'] ?? 'Working hours added successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );

//           // Reload rota entries
//           _loadRotaEntries();
//         } else {
//           // Show error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result['message'] ?? 'Failed to add working hours'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });

//         // Show error message
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('An error occurred: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Show date picker
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate,
//       firstDate: DateTime.now().subtract(const Duration(days: 365)),
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );

//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//       });
//     }
//   }

//   // Show time picker
//   Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
//     // Parse current time from controller
//     final List<String> timeParts = controller.text.split(':');
//     final TimeOfDay initialTime = TimeOfDay(
//       hour: int.tryParse(timeParts[0]) ?? 9,
//       minute: int.tryParse(timeParts[1]) ?? 0,
//     );

//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: initialTime,
//     );

//     if (picked != null) {
//       controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Staff Rota - ${widget.business['name']}'),
//         backgroundColor: AppStyles.primaryColor,
//         foregroundColor: Colors.white,
//         actions: [
//           // Refresh button
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _loadStaff,
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: _errorMessage != null
//           ? _buildErrorView()
//           : _buildRotaManagementUI(),
//     );
//   }

//   // Build error view
//   Widget _buildErrorView() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.error_outline,
//               color: AppStyles.errorColor,
//               size: 48,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _errorMessage!,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: AppStyles.errorColor,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loadStaff,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: AppStyles.primaryColor,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build rota management UI
//   Widget _buildRotaManagementUI() {
//     return Stack(
//       children: [
//         SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Staff selection section
//               _buildStaffSelectionSection(),

//               const SizedBox(height: 24),

//               // Add rota entry section
//               _buildAddRotaEntrySection(),

//               const SizedBox(height: 24),

//               // Rota entries section
//               _buildRotaEntriesSection(),
//             ],
//           ),
//         ),

//         // Loading overlay
//         if (_isLoading)
//           Container(
//             color: Colors.white.withAlpha(178), // 0.7 opacity = 178/255
//             child: const Center(
//               child: CircularProgressIndicator(),
//             ),
//           ),
//       ],
//     );
//   }

//   // Build staff selection section
//   Widget _buildStaffSelectionSection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Select Staff Member',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<Map<String, dynamic>>(
//               decoration: const InputDecoration(
//                 labelText: 'Staff Member',
//                 border: OutlineInputBorder(),
//               ),
//               hint: const Text('Select a staff member'),
//               value: _selectedStaff,
//               items: _staffList.map((staff) {
//                 return DropdownMenuItem<Map<String, dynamic>>(
//                   value: staff,
//                   child: Text(staff['name']),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedStaff = value;
//                 });

//                 // Load rota entries for selected staff
//                 _loadRotaEntries();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build add rota entry section
//   Widget _buildAddRotaEntrySection() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Add Working Hours',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Date picker
//             InkWell(
//               onTap: () => _selectDate(context),
//               child: InputDecorator(
//                 decoration: const InputDecoration(
//                   labelText: 'Date',
//                   border: OutlineInputBorder(),
//                   suffixIcon: Icon(Icons.calendar_today),
//                 ),
//                 child: Text(
//                   _formatDate(_selectedDate),
//                   style: const TextStyle(fontSize: 16),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Time pickers
//             Row(
//               children: [
//                 // Start time
//                 Expanded(
//                   child: InkWell(
//                     onTap: () => _selectTime(context, _startTimeController),
//                     child: InputDecorator(
//                       decoration: const InputDecoration(
//                         labelText: 'Start Time',
//                         border: OutlineInputBorder(),
//                         suffixIcon: Icon(Icons.access_time),
//                       ),
//                       child: Text(
//                         _startTimeController.text,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(width: 16),

//                 // End time
//                 Expanded(
//                   child: InkWell(
//                     onTap: () => _selectTime(context, _endTimeController),
//                     child: InputDecorator(
//                       decoration: const InputDecoration(
//                         labelText: 'End Time',
//                         border: OutlineInputBorder(),
//                         suffixIcon: Icon(Icons.access_time),
//                       ),
//                       child: Text(
//                         _endTimeController.text,
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 24),

//             // Add button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: _addRotaEntry,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Working Hours'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: AppStyles.primaryColor,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Build rota entries section
//   Widget _buildRotaEntriesSection() {
//     // Title with month indicator
//     final String monthTitle = DateFormat('MMMM yyyy').format(_currentMonth);

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Title row with month navigation
//         Row(
//           children: [
//             Expanded(
//               child: Text(
//                 'Scheduled Working Hours - $monthTitle',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             // Previous month button
//             IconButton(
//               icon: const Icon(Icons.chevron_left),
//               onPressed: () {
//                 setState(() {
//                   _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
//                 });
//                 _loadRotaEntries();
//               },
//               tooltip: 'Previous Month',
//             ),
//             // Next month button
//             IconButton(
//               icon: const Icon(Icons.chevron_right),
//               onPressed: () {
//                 setState(() {
//                   _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
//                 });
//                 _loadRotaEntries();
//               },
//               tooltip: 'Next Month',
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),

//         // Loading indicator or content
//         if (_loadingRota)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.all(32.0),
//               child: CircularProgressIndicator(),
//             ),
//           )
//         else if (_selectedStaff == null)
//           const Card(
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: Center(
//                 child: Text(
//                   'Please select a staff member to view their schedule',
//                   style: TextStyle(
//                     fontStyle: FontStyle.italic,
//                     color: AppStyles.secondaryTextColor,
//                   ),
//                 ),
//               ),
//             ),
//           )
//         else if (_rotaEntries.isEmpty)
//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Center(
//                 child: Text(
//                   'No working hours scheduled for ${_selectedStaff!['name']}',
//                   style: const TextStyle(
//                     fontStyle: FontStyle.italic,
//                     color: AppStyles.secondaryTextColor,
//                   ),
//                 ),
//               ),
//             ),
//           )
//         else
//           ..._buildGroupedRotaEntries(),
//       ],
//     );
//   }

//   // Group rota entries by date
//   List<Widget> _buildGroupedRotaEntries() {
//     // Group entries by date
//     final Map<String, List<Map<String, dynamic>>> groupedEntries = {};

//     for (final entry in _rotaEntries) {
//       final String date = entry['rota_date'];
//       if (!groupedEntries.containsKey(date)) {
//         groupedEntries[date] = [];
//       }
//       groupedEntries[date]!.add(entry);
//     }

//     // Build a card for each date
//     final List<Widget> dateCards = [];

//     // Sort dates
//     final List<String> sortedDates = groupedEntries.keys.toList()..sort();

//     for (final date in sortedDates) {
//       dateCards.add(
//         Card(
//           margin: const EdgeInsets.only(bottom: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Date header
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFEEF2F6),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(4),
//                     topRight: Radius.circular(4),
//                   ),
//                 ),
//                 child: Text(
//                   _formatDisplayDate(date),
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ),

//               // Entries for this date
//               ...groupedEntries[date]!.map((entry) => _buildRotaEntryCard(entry)),
//             ],
//           ),
//         ),
//       );
//     }

//     return dateCards;
//   }

//   // Build rota entry card
//   Widget _buildRotaEntryCard(Map<String, dynamic> entry) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Row(
//         children: [
//           // Time information
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   '${entry['start_time']} - ${entry['end_time']}',
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: AppStyles.primaryColor,
//                   ),
//                 ),
//                 if (entry['staff_name'] != null && _selectedStaff != null && entry['staff_name'] != _selectedStaff!['name'])
//                   Text(
//                     entry['staff_name'],
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: AppStyles.secondaryTextColor,
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Action buttons
//           Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               IconButton(
//                 icon: const Icon(Icons.edit, color: AppStyles.primaryColor),
//                 onPressed: () {
//                   // Edit functionality will be implemented later
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Edit functionality coming soon!'),
//                     ),
//                   );
//                 },
//                 tooltip: 'Edit',
//                 constraints: const BoxConstraints(
//                   minWidth: 40,
//                   minHeight: 40,
//                 ),
//                 padding: EdgeInsets.zero,
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Colors.red),
//                 onPressed: () {
//                   // Delete functionality will be implemented later
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(
//                       content: Text('Delete functionality coming soon!'),
//                     ),
//                   );
//                 },
//                 tooltip: 'Delete',
//                 constraints: const BoxConstraints(
//                   minWidth: 40,
//                   minHeight: 40,
//                 ),
//                 padding: EdgeInsets.zero,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
