/*import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final String time;
  final String section; // 'Today' or 'Earlier'
  bool isUnread;

  NotificationModel({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.time,
    required this.section,
    this.isUnread = true,
  });
}

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const Color primaryGreen = Color(0xFF0E9F6E);

  // Mock Notifications Data List
  List<NotificationModel> notifications = [
    NotificationModel(
      id: '1',
      icon: Icons.notifications_active_rounded,
      iconColor: Colors.red,
      iconBg: const Color(0xFFFEF2F2),
      title: 'Vaccine Reminder',
      message: 'Measles (Dose 1) is due on 24 July 2026 for Ali Ahmad.',
      time: 'Just now',
      section: 'Today',
      isUnread: true,
    ),
    NotificationModel(
      id: '2',
      icon: Icons.verified_rounded,
      iconColor: primaryGreen,
      iconBg: const Color(0xFFE5F7ED),
      title: 'Vaccination Completed',
      message: 'Penta (Dose 3) for Ali Ahmad has been updated by BHU Jand.',
      time: '2 hours ago',
      section: 'Today',
      isUnread: true,
    ),
    NotificationModel(
      id: '3',
      icon: Icons.campaign_rounded,
      iconColor: Colors.blue,
      iconBg: const Color(0xFFE0F2FE),
      title: 'Polio Campaign Alert',
      message:
          'Door-to-door Polio Vaccination drive starts next Monday in Attock district.',
      time: '2 days ago',
      section: 'Earlier',
      isUnread: false,
    ),
    NotificationModel(
      id: '4',
      icon: Icons.article_rounded,
      iconColor: Colors.orange,
      iconBg: const Color(0xFFFFF7ED),
      title: 'New Health Tip',
      message:
          'Read about managing mild fever after vaccination in Education section.',
      time: '5 days ago',
      section: 'Earlier',
      isUnread: false,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isUnread = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onNotificationTap(NotificationModel item) {
    setState(() {
      item.isUnread = false;
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.time,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Text(
                item.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifications =
        notifications.where((n) => n.section == 'Today').toList();
    final earlierNotifications =
        notifications.where((n) => n.section == 'Earlier').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: notifications.any((n) => n.isUnread)
                ? _markAllAsRead
                : null,
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: notifications.any((n) => n.isUnread)
                    ? primaryGreen
                    : Colors.grey.shade400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No Notifications Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView(
                  children: [
                    if (todayNotifications.isNotEmpty) ...[
                      _buildSectionTitle('Today'),
                      ...todayNotifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildNotificationItem(item),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (earlierNotifications.isNotEmpty) ...[
                      _buildSectionTitle('Earlier'),
                      ...earlierNotifications.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: _buildNotificationItem(item),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    return InkWell(
      onTap: () => _onNotificationTap(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isUnread ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isUnread ? const Color(0xFFE5E7EB) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: item.isUnread
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationCenterScreen extends StatefulWidget {
  final String parentCNIC;

  const NotificationCenterScreen({Key? key, required this.parentCNIC}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  static const Color primaryGreen = Color(0xFF0B4D30);

  String get _cleanCNIC => widget.parentCNIC.replaceAll('-', '').trim();

  // Picks an icon/color based on the notification title, since the
  // Cloud Function only sends a plain title/message pair, not a type.
  Map<String, dynamic> _styleFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('missed') || t.contains('refused')) {
      return {'icon': Icons.notifications_active_rounded, 'color': Colors.red, 'bg': const Color(0xFFFEF2F2)};
    }
    if (t.contains('administered') || t.contains('completed') || t.contains('vaccinated')) {
      return {'icon': Icons.verified_rounded, 'color': primaryGreen, 'bg': const Color(0xFFE5F7ED)};
    }
    if (t.contains('campaign')) {
      return {'icon': Icons.campaign_rounded, 'color': Colors.blue, 'bg': const Color(0xFFE0F2FE)};
    }
    if (t.contains('registered')) {
      return {'icon': Icons.person_add_alt_1_rounded, 'color': Colors.orange, 'bg': const Color(0xFFFFF7ED)};
    }
    return {'icon': Icons.article_rounded, 'color': Colors.orange, 'bg': const Color(0xFFFFF7ED)};
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is! Timestamp) return 'Just now';
    final dt = createdAt.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  bool _isToday(dynamic createdAt) {
    if (createdAt is! Timestamp) return true;
    final dt = createdAt.toDate();
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> unreadDocs) async {
    if (unreadDocs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadDocs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _onNotificationTap(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    // Mark this one as read as soon as it's opened.
    doc.reference.update({'isRead': true});

    final style = _styleFor((data['title'] ?? '').toString());

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: style['bg'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style['icon'] as IconData, color: style['color'] as Color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (data['title'] ?? 'Alert').toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatTime(data['createdAt']),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Text(
                (data['message'] ?? '').toString(),
                style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('parentCNIC', isEqualTo: _cleanCNIC)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }

            final docs = List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

            // Newest first (createdAt may briefly be null right after a
            // write, before the server timestamp resolves -- those sort last).
            docs.sort((a, b) {
              final ta = (a.data() as Map<String, dynamic>)['createdAt'];
              final tb = (b.data() as Map<String, dynamic>)['createdAt'];
              final da = ta is Timestamp ? ta.toDate() : DateTime(1970);
              final db_ = tb is Timestamp ? tb.toDate() : DateTime(1970);
              return db_.compareTo(da);
            });

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No Notifications Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final todayDocs = docs.where((d) => _isToday((d.data() as Map<String, dynamic>)['createdAt'])).toList();
            final earlierDocs = docs.where((d) => !_isToday((d.data() as Map<String, dynamic>)['createdAt'])).toList();
            final unreadDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['isRead'] != true).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: unreadDocs.isNotEmpty ? () => _markAllAsRead(unreadDocs) : null,
                        child: Text(
                          'Mark all read',
                          style: TextStyle(
                            color: unreadDocs.isNotEmpty ? primaryGreen : Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView(
                      children: [
                        if (todayDocs.isNotEmpty) ...[
                          _buildSectionTitle('Today'),
                          ...todayDocs.map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildNotificationItem(doc),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (earlierDocs.isNotEmpty) ...[
                          _buildSectionTitle('Earlier'),
                          ...earlierDocs.map(
                            (doc) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildNotificationItem(doc),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildNotificationItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isUnread = data['isRead'] != true;
    final style = _styleFor((data['title'] ?? '').toString());

    return InkWell(
      onTap: () => _onNotificationTap(doc, data),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUnread ? const Color(0xFFE5E7EB) : Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: style['bg'] as Color, shape: BoxShape.circle),
              child: Icon(style['icon'] as IconData, color: style['color'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (data['title'] ?? 'Alert').toString(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(data['createdAt']),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (data['message'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}