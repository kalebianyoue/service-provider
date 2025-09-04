import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _selectedDate = DateTime.now();
  Map<DateTime, List<Task>> _tasks = {};

  final TextEditingController _taskController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Professional Agenda",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Calendar for selecting date
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDate = selectedDay;
                });
              },
            ),
            const SizedBox(height: 10),
            // Display tasks for selected day
            Expanded(child: _buildTaskList()),
            const SizedBox(height: 10),
            // Section to add new task
            _buildAddTaskSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final dayTasks = _tasks[_selectedDate] ?? [];
    if (dayTasks.isEmpty) {
      return const Center(
        child: Text(
          "No tasks for this day",
          style: TextStyle(fontSize: 16),
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
            title: Text(task.name),
            subtitle: Text(
                "${task.startTime.format(context)} - ${task.endTime.format(context)}"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  dayTasks.removeAt(index);
                  if (dayTasks.isEmpty) _tasks.remove(_selectedDate);
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddTaskSection() {
    return Column(
      children: [
        TextField(
          controller: _taskController,
          decoration: const InputDecoration(
            labelText: "Task / Work",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
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
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _endTime = picked;
                    });
                  }
                },
                child: Text(_endTime == null ? "End Time" : _endTime!.format(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (_taskController.text.isEmpty || _startTime == null || _endTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please fill all fields")),
              );
              return;
            }

            final newTask = Task(
              name: _taskController.text,
              startTime: _startTime!,
              endTime: _endTime!,
            );

            setState(() {
              _tasks[_selectedDate] ??= [];
              _tasks[_selectedDate]!.add(newTask);
              _taskController.clear();
              _startTime = null;
              _endTime = null;
            });
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
          ),
          child: const Text(
            "Add Task",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}

class Task {
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Task({required this.name, required this.startTime, required this.endTime});
}
