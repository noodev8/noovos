import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../styles/app_styles.dart';

class WeekPickerWidget extends StatefulWidget {
  // Number of weeks to display
  final int numberOfWeeks;
  
  // Initial selected week index
  final int initialWeekIndex;
  
  // Callback when a week is selected
  final Function(int weekIndex, Map<String, dynamic> weekData) onWeekSelected;
  
  // Constructor
  const WeekPickerWidget({
    Key? key,
    this.numberOfWeeks = 12,
    this.initialWeekIndex = 0,
    required this.onWeekSelected,
  }) : super(key: key);

  @override
  State<WeekPickerWidget> createState() => _WeekPickerWidgetState();
}

class _WeekPickerWidgetState extends State<WeekPickerWidget> {
  // Currently selected week index
  late int _selectedWeekIndex;
  
  // Scroll controller for the horizontal list
  late ScrollController _scrollController;
  
  // Week options (generated based on numberOfWeeks)
  List<Map<String, dynamic>> _weekOptions = [];

  @override
  void initState() {
    super.initState();
    _selectedWeekIndex = widget.initialWeekIndex;
    _scrollController = ScrollController();
    _generateWeekOptions();
    
    // Scroll to the selected week after rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_weekOptions.isNotEmpty && _selectedWeekIndex > 0) {
        // Calculate position to scroll to (approximate)
        final double itemWidth = 140.0; // Approximate width of each week card
        final double offset = _selectedWeekIndex * itemWidth;
        
        // Scroll to position
        if (offset > 0 && _scrollController.hasClients) {
          _scrollController.animateTo(
            offset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Generate week options (Sunday to Saturday)
  void _generateWeekOptions() {
    // Get the current date
    final DateTime now = DateTime.now();

    // Find the most recent Sunday (start of the week)
    final DateTime currentWeekStart = now.subtract(Duration(days: now.weekday % 7));

    // Generate weeks
    _weekOptions = List.generate(widget.numberOfWeeks, (index) {
      // Calculate start date (Sunday) for this week
      final DateTime startDate = currentWeekStart.add(Duration(days: 7 * index));

      // Calculate end date (Saturday) for this week
      final DateTime endDate = startDate.add(const Duration(days: 6));

      // Format dates for display and API
      final String displayText = '${DateFormat('MMM d').format(startDate)} - ${DateFormat('MMM d').format(endDate)}';
      final String fullDisplayText = '${DateFormat('d MMM yyyy').format(startDate)} - ${DateFormat('d MMM yyyy').format(endDate)}';
      final String startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
      final String endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

      return {
        'index': index,
        'startDate': startDate,
        'endDate': endDate,
        'apiStartDate': startDateStr,
        'apiEndDate': endDateStr,
        'displayText': displayText,
        'fullDisplayText': fullDisplayText,
      };
    });
  }

  // Handle week selection
  void _handleWeekTap(int index) {
    if (index != _selectedWeekIndex) {
      setState(() {
        _selectedWeekIndex = index;
      });
      
      // Call the callback
      widget.onWeekSelected(index, _weekOptions[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if our week options are not generated yet or index is out of range
    if (_weekOptions.isEmpty || _selectedWeekIndex >= _weekOptions.length) {
      return const SizedBox(); // Return empty widget if no data
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current selection text display (more detailed)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            _weekOptions[_selectedWeekIndex]['fullDisplayText'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppStyles.primaryColor,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Horizontal scrollable week cards
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: _weekOptions.length,
            itemBuilder: (context, index) {
              // Get start date of the week
              
              // Check if this is the current week
              final bool isCurrentWeek = index == 0;
              
              // Is this the selected week?
              final bool isSelected = index == _selectedWeekIndex;
              
              return GestureDetector(
                onTap: () => _handleWeekTap(index),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppStyles.primaryColor : isCurrentWeek ? AppStyles.primaryColor.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppStyles.primaryColor : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppStyles.primaryColor.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Week label 
                        Text(
                          isCurrentWeek ? 'Current Week' : 'Week ${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Date range
                        Text(
                          _weekOptions[index]['displayText'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppStyles.primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 