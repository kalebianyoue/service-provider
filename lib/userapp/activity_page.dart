import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({Key? key}) : super(key: key);

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all'; // 'all', 'pending', 'accepted', 'completed', 'cancelled'
  String _sortBy = 'date'; // 'date', 'created'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chip Bar
          _buildFilterChips(),

          // Booking List
          Expanded(
            child: _buildBookingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('All'),
              selected: _filterStatus == 'all',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? 'all' : _filterStatus;
                });
              },
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Pending'),
              selected: _filterStatus == 'pending',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? 'pending' : _filterStatus;
                });
              },
              backgroundColor: _filterStatus == 'pending' ? Colors.orange[100] : null,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Accepted'),
              selected: _filterStatus == 'accepted',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? 'accepted' : _filterStatus;
                });
              },
              backgroundColor: _filterStatus == 'accepted' ? Colors.blue[100] : null,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Completed'),
              selected: _filterStatus == 'completed',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? 'completed' : _filterStatus;
                });
              },
              backgroundColor: _filterStatus == 'completed' ? Colors.green[100] : null,
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Cancelled'),
              selected: _filterStatus == 'cancelled',
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? 'cancelled' : _filterStatus;
                });
              },
              backgroundColor: _filterStatus == 'cancelled' ? Colors.red[100] : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList() {
    Query query = _firestore.collection('jobs');

    // Apply status filter
    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    // Apply sorting
    if (_sortBy == 'date') {
      query = query.orderBy('selectedDate', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            var bookingDoc = snapshot.data!.docs[index];
            return _buildBookingCard(bookingDoc);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(DocumentSnapshot bookingDoc) {
    Map<String, dynamic> data = bookingDoc.data() as Map<String, dynamic>;
    String bookingId = bookingDoc.id;

    // Format date and time
    String formattedDate = 'Date not set';
    String formattedTime = 'Time not set';

    if (data['selectedDate'] != null) {
      DateTime date = (data['selectedDate'] as Timestamp).toDate();
      formattedDate = DateFormat('MMM dd, yyyy').format(date);
      formattedTime = data['selectedTime'] ?? 'Time not specified';
    }

    Color statusColor = _getStatusColor(data['status']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['jobName'] ?? 'Untitled Job',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (data['status'] ?? 'unknown').toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  formattedTime,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['location'] ?? 'Location not specified',
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['customerName'] ?? 'Customer name not specified',
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (data['budgetAmount'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${data['budgetAmount']} XAF',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (data['status'] == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateBookingStatus(bookingId, 'accepted'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
            if (data['status'] == 'accepted')
              ElevatedButton(
                onPressed: () => _updateBookingStatus(bookingId, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Mark as Completed'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_outline, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            "No bookings found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _filterStatus == 'all'
                ? "There are no bookings in the system."
                : "There are no ${_filterStatus} bookings.",
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    _firestore.collection('jobs').doc(bookingId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter & Sort Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<String>(
                title: const Text('Date'),
                value: 'date',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Created Date'),
                value: 'created',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}