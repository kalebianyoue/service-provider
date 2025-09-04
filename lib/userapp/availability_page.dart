import 'package:flutter/material.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  final List<String> selectedSlots = [];

  Future<void> pickSlot() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          selectedSlots.add("${date.toLocal().toString().split(' ')[0]} ${time.format(context)}");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Availability")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickSlot,
              icon: const Icon(Icons.add),
              label: const Text("Add Availability Slot"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: selectedSlots.length,
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(selectedSlots[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => selectedSlots.removeAt(index)),
                  ),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedSlots.isNotEmpty
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text("✅ Save & Continue"),
            )
          ],
        ),
      ),
    );
  }
}
