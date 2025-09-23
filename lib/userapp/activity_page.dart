import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:serviceprovider/userapp/chat_page.dart';

class BookingListPage extends StatefulWidget {
  const BookingListPage({Key? key}) : super(key: key);

  @override
  State<BookingListPage> createState() => _BookingListPageState();
}

class _BookingListPageState extends State<BookingListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _filterStatus = 'all';
  String _sortBy = 'date';
  final Map<String, String> _userNamesCache = {}; // Cache for user names
  final Map<String, String> _providerNamesCache = {}; // Cache for provider names

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Service Requests',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 28),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Sort',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chip Bar with gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: _buildFilterChips(),
            ),
          ),

          // Booking List
          Expanded(
            child: _buildBookingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final List<Map<String, dynamic>> filters = [
      {'label': 'All', 'value': 'all', 'color': Colors.grey},
      {'label': 'Pending', 'value': 'pending', 'color': Colors.orange},
      {'label': 'Accepted', 'value': 'accepted', 'color': Colors.blue},
      {'label': 'Completed', 'value': 'completed', 'color': Colors.green},
      {'label': 'Cancelled', 'value': 'cancelled', 'color': Colors.red},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                filter['label'],
                style: TextStyle(
                  color: _filterStatus == filter['value'] ? Colors.white : filter['color'],
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: _filterStatus == filter['value'],
              onSelected: (selected) {
                setState(() {
                  _filterStatus = selected ? filter['value'] : _filterStatus;
                });
              },
              selectedColor: filter['color'],
              backgroundColor: Colors.white,
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: filter['color'],
                  width: 2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingList() {
    Query query = _firestore.collection('jobs');

    if (_filterStatus != 'all') {
      query = query.where('status', isEqualTo: _filterStatus);
    }

    if (_sortBy == 'date') {
      query = query.orderBy('selectedDate', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
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
            return FutureBuilder<Map<String, dynamic>>(
              future: _getBookingWithUserName(bookingDoc),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildBookingCardSkeleton();
                }

                if (userSnapshot.hasError) {
                  return _buildBookingCard(bookingDoc, 'Unknown User');
                }

                final userData = userSnapshot.data;
                final userName = userData?['userName'] ?? 'Unknown User';

                return _buildBookingCard(bookingDoc, userName);
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getBookingWithUserName(DocumentSnapshot bookingDoc) async {
    final Map<String, dynamic> data = bookingDoc.data() as Map<String, dynamic>;
    final String userId = data['UserId'] ?? '';

    // Return cached data if available
    if (_userNamesCache.containsKey(userId)) {
      return {
        'userName': _userNamesCache[userId]!,
        'bookingData': data
      };
    }

    // Check if userName is already in booking data (optimization)
    if (data['userName'] != null && data['userName'].toString().isNotEmpty) {
      _userNamesCache[userId] = data['userName'];
      return {
        'userName': data['userName'],
        'bookingData': data
      };
    }

    // Fetch user data from Firestore users collection
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userName = userDoc.get('name') ??
            userDoc.get('displayName') ??
            userDoc.get('userName') ??
            (userDoc.get('email') != null ? userDoc.get('email').toString().split('@')[0] : null) ??
            'Unknown User';

        // Cache the user name
        _userNamesCache[userId] = userName;

        // Update the booking document with the user name for future reference
        try {
          await bookingDoc.reference.update({
            'userName': userName,
            'userFetchedAt': FieldValue.serverTimestamp()
          });
        } catch (e) {
          print('Error updating booking with user name: $e');
        }

        return {
          'userName': userName,
          'bookingData': data
        };
      } else {
        // Try to get user info from Firebase Auth
        try {
          // Get current user if it matches the userId
          final currentUser = _auth.currentUser;
          if (currentUser != null && currentUser.uid == userId) {
            final userName = currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'User';

            _userNamesCache[userId] = userName;
            return {
              'userName': userName,
              'bookingData': data
            };
          }

          // If we can't find the user, use a generic name
          _userNamesCache[userId] = 'User';
          return {
            'userName': 'User',
            'bookingData': data
          };
        } catch (authError) {
          print('Error fetching user from Auth: $authError');
          _userNamesCache[userId] = 'Unknown User';
          return {
            'userName': 'Unknown User',
            'bookingData': data
          };
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _userNamesCache[userId] = 'Unknown User';
      return {
        'userName': 'Unknown User',
        'bookingData': data
      };
    }
  }

  Widget _buildBookingCard(DocumentSnapshot bookingDoc, String userName) {
    Map<String, dynamic> data = bookingDoc.data() as Map<String, dynamic>;
    String bookingId = bookingDoc.id;

    // Format dates
    String formattedDate = 'Not set';
    String formattedTime = 'Not specified';
    String formattedCreatedDate = 'Not available';

    if (data['selectedDate'] != null) {
      DateTime date = (data['selectedDate'] as Timestamp).toDate();
      formattedDate = DateFormat('MMM dd, yyyy').format(date);
      formattedTime = data['selectedTime'] ?? 'Not specified';
    }

    if (data['createdAt'] != null) {
      DateTime createdDate = (data['createdAt'] as Timestamp).toDate();
      formattedCreatedDate = DateFormat('MMM dd, yyyy • HH:mm').format(createdDate);
    }

    Color statusColor = _getStatusColor(data['status']);
    IconData statusIcon = _getStatusIcon(data['status']);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['jobName'] ?? 'Untitled Service',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        (data['status'] ?? 'unknown').toString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // User Information Section
            _buildInfoSection(
              icon: Icons.person,
              title: 'Posted by',
              content: userName,
              subtitle: 'User ID: ${data['UserId'] ?? 'N/A'}',
            ),

            _buildInfoSection(
              icon: Icons.calendar_today,
              title: 'Posted on',
              content: formattedCreatedDate,
            ),

            // Show provider info if job is accepted
            if (data['status'] == 'accepted' && data['acceptedBy'] != null)
              FutureBuilder<String>(
                future: _getProviderName(data['acceptedBy']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoSection(
                      icon: Icons.person,
                      title: 'Accepted by',
                      content: 'Loading...',
                    );
                  }
                  return _buildInfoSection(
                    icon: Icons.person,
                    title: 'Accepted by',
                    content: snapshot.data ?? 'Unknown Provider',
                    onTap: () => _viewProviderProfile(data['acceptedBy']),
                  );
                },
              ),

            // Service Details Section
            const SizedBox(height: 16),
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            _buildDetailRow(
              icon: Icons.event,
              label: 'Service Date',
              value: formattedDate,
            ),

            _buildDetailRow(
              icon: Icons.access_time,
              label: 'Time',
              value: formattedTime,
            ),

            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: data['location'] ?? 'Not specified',
            ),

            if (data['hours'] != null)
              _buildDetailRow(
                icon: Icons.timer,
                label: 'Duration',
                value: '${data['hours']} hours',
              ),

            if (data['budgetAmount'] != null)
              _buildDetailRow(
                icon: Icons.attach_money,
                label: 'Budget',
                value: '${data['budgetAmount']} XAF ${data['budgetType'] != 'none' ? '(${data['budgetType']})' : ''}',
                valueStyle: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            _buildDetailRow(
              icon: Icons.phone,
              label: 'Contact',
              value: data['phoneNumber'] != null ? '+237 ${data['phoneNumber']}' : 'Not provided',
            ),

            // Description Section
            if (data['description'] != null && data['description'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['description'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(data['status'], bookingId, data['UserId'],data['acceptedBy'],data['userName']),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton loading effect
            SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required IconData icon, required String title, required String content, String? subtitle, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                '$title:',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(
                    color: onTap != null ? Colors.blue : Colors.grey,
                    fontSize: 14,
                    decoration: onTap != null ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String? status, String bookingId, String clientId, String UserId, String name) {
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptBooking(bookingId, clientId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Accept Request'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateBookingStatus(bookingId, 'cancelled'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Decline'),
              ),
            ),
          ],
        );

      case 'accepted':
        return Column(
          children: [
            ElevatedButton.icon(
              onPressed: () => _updateBookingStatus(bookingId, 'completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Mark as Completed'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _chatWithClient(name,clientId,UserId),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat, size: 20),
              label: const Text('Chat with Client'),
            ),
          ],
        );

      default:
        return OutlinedButton.icon(
          onPressed: () => _PostTojob(bookingId),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.blue,
            side: const BorderSide(color: Colors.blue),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text('Apply'),
        );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.blue),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading service requests...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            _filterStatus == 'all'
                ? "No service requests yet"
                : "No ${_filterStatus} requests",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _filterStatus == 'all'
                ? "When clients post service requests, they'll appear here."
                : "There are no ${_filterStatus} service requests at the moment.",
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'accepted': return Icons.check_circle;
      case 'completed': return Icons.done_all;
      case 'cancelled': return Icons.cancel;
      default: return Icons.help;
    }
  }

  Future<String> _getProviderName(String providerId) async {
    if (_providerNamesCache.containsKey(providerId)) {
      return _providerNamesCache[providerId]!;
    }

    try {
      final providerDoc = await _firestore.collection('providers').doc(providerId).get();
      if (providerDoc.exists) {
        final providerName = providerDoc.get('imageUrl') ??
            providerDoc.get('name') ??
            providerDoc.get('displayName') ??
            'Unknown Provider';
        _providerNamesCache[providerId] = providerName;
        return providerName;
      }
    } catch (e) {
      print('Error fetching provider name: $e');
    }

    return 'Unknown Provider';
  }

  void _acceptBooking(String bookingId, String clientId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Get provider info
      final providerDoc = await _firestore.collection('providers').doc(currentUser.uid).get();
      final providerName = providerDoc.get('imageUrl') ??
          providerDoc.get('name') ??
          currentUser.displayName ??
          'A service provider';

      // Update booking status
      await _firestore.collection('jobs').doc(bookingId).update({
        'status': 'accepted',
        'acceptedBy': currentUser.uid,
        'acceptedByName': providerName,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create notification for the client
      await _firestore.collection('notifications').add({
        'userId': clientId,
        'title': 'Job Accepted',
        'message': '$providerName has accepted your service request',
        'type': 'job_accepted',
        'jobId': bookingId,
        'providerId': currentUser.uid,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have accepted this job. The client has been notified.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept job: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _updateBookingStatus(String bookingId, String newStatus) {
    _firestore.collection('jobs').doc(bookingId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
      'updatedByName': _auth.currentUser?.displayName ?? 'Provider',
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request status updated to $newStatus'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }
  Future<void> _PostTojob(String jobId) async {
    try {
      // Récupérer l'ID de l'utilisateur connecté
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == null) {
        print("Aucun utilisateur connecté");
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        print("⚠️ Document introuvable !");
        return;
      }

      // Mettre à jour le document en une seule fois
      await docRef.update({
        "AcceptList": FieldValue.arrayUnion([currentUserId]),
        "status": "pending",
      });

      print("✅ Utilisateur ajouté et statut mis à jour avec succès !");
    } catch (e) {
      print("❌ Erreur lors de la mise à jour : $e");
    }
  }

  void _viewBookingDetails(String bookingId) {
    _firestore.collection('jobs').doc(bookingId).get().then((bookingDoc) {
      if (!bookingDoc.exists) return;

      Map<String, dynamic> data = bookingDoc.data() as Map<String, dynamic>;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '📋 Service Request Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailItem('Service', data['jobName'] ?? 'N/A'),
                _buildDetailItem('Status', data['status'] ?? 'N/A'),
                _buildDetailItem('Location', data['location'] ?? 'N/A'),
                _buildDetailItem('Phone', data['phoneNumber'] != null ? '+237 ${data['phoneNumber']}' : 'N/A'),
                _buildDetailItem('Hours', data['hours']?.toString() ?? 'N/A'),
                _buildDetailItem('Budget', data['budgetAmount'] != null ? '${data['budgetAmount']} XAF' : 'N/A'),
                if (data['description'] != null)
                  _buildDetailItem('Description', data['description']),
                if (data['acceptedByName'] != null)
                  _buildDetailItem('Accepted by', data['acceptedByName']),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _viewProviderProfile(String providerId) {
    // Navigate to provider profile page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderProfilePage(providerId: providerId),
      ),
    );
  }

  void _chatWithClient(String name,String clientId,String UserId) {
    // Navigate to chat screen with client
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          Name: name,
          providerId: UserId,
          clientId: clientId,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔧 Filter & Sort Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sort by:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...['date', 'created'].map((value) {
                return RadioListTile<String>(
                  title: Text(value == 'date' ? 'Service Date' : 'Creation Date'),
                  value: value,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for Provider Profile Page
class ProviderProfilePage extends StatelessWidget {
  final String providerId;

  const ProviderProfilePage({Key? key, required this.providerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Profile'),
      ),
      body: Center(
        child: Text('Provider Profile Page for ID: $providerId'),
      ),
    );
  }
}

// Placeholder for Chat Screen
class ChatScreen extends StatelessWidget {
  final String recipientId;
  final String recipientType;

  const ChatScreen({Key? key, required this.recipientId, required this.recipientType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${recipientType == 'client' ? 'Client' : 'Provider'}'),
      ),
      body: Center(
        child: Text('Chat Screen with $recipientType ID: $recipientId'),
      ),
    );
  }
}