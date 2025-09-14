import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  Map<DateTime, List<Task>> _tasks = {};
  bool _showAddTaskForm = false;

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  DateTime? _taskDate;

  @override
  void initState() {
    super.initState();
    _taskDate = _selectedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showAddTaskForm ? "Add New Task" : "Weekly Work Planner",
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _showAddTaskForm ? Colors.green : Colors.blue,
        centerTitle: true,
        actions: [
          if (!_showAddTaskForm)
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                  _taskDate = DateTime.now();
                });
              },
            ),
          IconButton(
            icon: Icon(_showAddTaskForm ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _showAddTaskForm = !_showAddTaskForm;
                if (!_showAddTaskForm) {
                  // Clear form when closing
                  _taskController.clear();
                  _descriptionController.clear();
                  _startTime = null;
                  _endTime = null;
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_showAddTaskForm) ...[
              // Calendar for selecting date
              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                eventLoader: (day) {
                  return _tasks[DateTime(day.year, day.month, day.day)] ?? [];
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markersAutoAligned: true,
                  markerSize: 6,
                ),
              ),
              const SizedBox(height: 10),
              // Display tasks for selected day with day name
              Text(
                _getFormattedDate(_selectedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Expanded(child: _buildTaskList()),
            ] else ...[
              // Show add task form
              Expanded(child: _buildAddTaskForm()),
            ],
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildTaskList() {
    final dayTasks = _tasks[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ?? [];

    // Sort tasks by start time
    dayTasks.sort((a, b) {
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });

    if (dayTasks.isEmpty) {
      return const Center(
        child: Text(
          "No tasks planned for this day\n\nTap the + button to add tasks",
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: dayTasks.length,
      itemBuilder: (context, index) {
        final task = dayTasks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(
              task.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description.isNotEmpty)
                  Text(task.description, style: const TextStyle(fontSize: 14)),
                Text(
                  "${task.startTime.format(context)} - ${task.endTime.format(context)}",
                  style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  dayTasks.removeAt(index);
                  if (dayTasks.isEmpty) {
                    _tasks.remove(DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day));
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _taskController,
            decoration: const InputDecoration(
              labelText: "Task Title ",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: "Task Description",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _taskDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _taskDate = picked;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    _taskDate == null
                        ? "Select Date *"
                        : "${_taskDate!.day}/${_taskDate!.month}/${_taskDate!.year}",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _startTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startTime = picked;
                      });
                    }
                  },
                  child: Text(
                    _startTime == null ? "Start Time" : _startTime!.format(context),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _endTime ?? (_startTime ?? TimeOfDay.fromDateTime(DateTime.now().add(const Duration()))),
                    );
                    if (picked != null) {
                      setState(() {
                        _endTime = picked;
                      });
                    }
                  },
                  child: Text(_endTime == null ? "End Time *" : _endTime!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_taskController.text.isEmpty || _startTime == null || _endTime == null || _taskDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill all required fields (*)")),
                );
                return;
              }

              final newTask = Task(
                name: _taskController.text,
                description: _descriptionController.text,
                startTime: _startTime!,
                endTime: _endTime!,
              );

              setState(() {
                final dateKey = DateTime(_taskDate!.year, _taskDate!.month, _taskDate!.day);
                _tasks[dateKey] ??= [];
                _tasks[dateKey]!.add(newTask);
                _taskController.clear();
                _descriptionController.clear();
                _startTime = null;
                _endTime = null;
                _showAddTaskForm = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Task added successfully")),
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ),
            child: const Text(
              "Add Task",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              setState(() {
                _showAddTaskForm = false;
              });
            },
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class Task {
  final String name;
  final String description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Task({
    required this.name,
    this.description = "",
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() => name;
}