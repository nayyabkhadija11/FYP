import 'package:flutter/material.dart';

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
}