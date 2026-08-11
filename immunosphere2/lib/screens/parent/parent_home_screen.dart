/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentHomeScreen extends StatefulWidget {
  final String parentCnic;
  final Function(int)? onNavigateToTab;

  const ParentHomeScreen({
    Key? key,
    required this.parentCnic,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color primaryGreen = Color(0xFF0F8A5F);

  String _cleanCNIC(String cnic) {
    return cnic.replaceAll('-', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final rawCnic = widget.parentCnic.trim();
    final sanitizedCnic = _cleanCNIC(rawCnic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. TOP GREEN HEADER SECTION (EXACT LOGGED-IN PARENT FETCH)
              // -------------------------------------------------------------
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  String displayName = '';

                  // Check 1: Check in 'users' collection by CNIC
                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    for (var doc in userSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                      if (docCnic == sanitizedCnic) {
                        displayName = (data['name'] ?? data['fullName'] ?? data['parentName'] ?? '').toString().trim();
                        if (displayName.isNotEmpty) break;
                      }
                    }
                  }

                  if (displayName.isNotEmpty) {
                    return _buildHeaderUI(context, displayName, sanitizedCnic);
                  }

                  // Check 2: Fallback check in 'parents' collection
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('parents').snapshots(),
                    builder: (context, parentSnapshot) {
                      String parentName = '';

                      if (parentSnapshot.hasData && parentSnapshot.data!.docs.isNotEmpty) {
                        for (var doc in parentSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                          if (docCnic == sanitizedCnic) {
                            parentName = (data['name'] ?? data['parentName'] ?? data['fullName'] ?? '').toString().trim();
                            if (parentName.isNotEmpty) break;
                          }
                        }
                      }

                      if (parentName.isNotEmpty) {
                        return _buildHeaderUI(context, parentName, sanitizedCnic);
                      }

                      // Check 3: If not found in profiles, check children collection matching EXACT CNIC
                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('children').where('parentCNIC', isEqualTo: sanitizedCnic).snapshots(),
                        builder: (context, childSnapshot) {
                          String childParentName = 'Parent';
                          if (childSnapshot.hasData && childSnapshot.data!.docs.isNotEmpty) {
                            final firstDoc = childSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            childParentName = (firstDoc['parentName'] ?? firstDoc['fatherName'] ?? 'Parent').toString().trim();
                          }
                          return _buildHeaderUI(context, childParentName, sanitizedCnic);
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. UPCOMING VACCINATIONS FOR LOGGED-IN PARENT'S CHILDREN ONLY
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upcoming Vaccinations',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.onNavigateToTab != null) {
                              widget.onNavigateToTab!(1); 
                            }
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('vaccination_tasks')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: primaryGreen),
                            ),
                          );
                        }

                        final taskDocs = snapshot.data?.docs ?? [];
                        final pendingTasks = taskDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString().toLowerCase();
                          return status != 'completed' && status != 'done';
                        }).toList();

                        if (pendingTasks.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No upcoming vaccinations due.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: pendingTasks.take(2).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final childName = data['childName'] ?? 'Child';
                            final vaccineName = data['vaccineName'] ?? 'Vaccine';
                            final dueDate = data['dueDate'] != null
                                ? (data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]
                                : 'N/A';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE5F7ED),
                                    child: Icon(Icons.person, color: primaryGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('Vaccine: $vaccineName', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                        Text('Due: $dueDate', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Due Soon', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. HEALTH EDUCATION VIDEOS
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Health Education Videos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EducationVideosScreen(),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('health_videos').snapshots(),
                      builder: (context, videoSnapshot) {
                        if (videoSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final videoDocs = videoSnapshot.data?.docs ?? [];

                        if (videoDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No health videos uploaded yet.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 175,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: videoDocs.length,
                            itemBuilder: (context, index) {
                              final video = videoDocs[index].data() as Map<String, dynamic>;
                              return _buildVideoCard(
                                title: video['title'] ?? 'Health Video',
                                duration: video['duration'] ?? '',
                                thumbnailUrl: video['thumbnailUrl'] ?? '',
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 4. RECENT NOTIFICATIONS FOR THIS PARENT
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recent Notifications',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('notifications')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, notifSnapshot) {
                        if (notifSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final notifDocs = notifSnapshot.data?.docs ?? [];

                        if (notifDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No recent notifications.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: notifDocs.take(3).map((doc) {
                              final notif = doc.data() as Map<String, dynamic>;
                              return Column(
                                children: [
                                  _notificationItem(
                                    Icons.notifications_active_outlined,
                                    notif['title'] ?? 'Alert',
                                    notif['message'] ?? '',
                                    notif['time'] ?? 'Just now',
                                  ),
                                  if (doc != notifDocs.take(3).last) const Divider(height: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderUI(BuildContext context, String displayName, String sanitizedCnic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hello, $displayName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay updated on your child\'s vaccinations.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard({required String title, required String duration, required String thumbnailUrl}) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: thumbnailUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnailUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: const Center(
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (duration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(duration, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _notificationItem(IconData icon, String title, String message, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE5F7ED),
          child: Icon(icon, color: primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(message, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR HEALTH EDUCATION VIDEOS
// -------------------------------------------------------------
class EducationVideosScreen extends StatelessWidget {
  const EducationVideosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education Videos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('health_videos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F8A5F)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No health education videos available.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final video = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        image: (video['thumbnailUrl'] ?? '').isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(video['thumbnailUrl']),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: const Center(
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['title'] ?? 'Health Video',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if ((video['duration'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(video['duration'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR NOTIFICATIONS LIST
// -------------------------------------------------------------
class NotificationsListScreen extends StatelessWidget {
  final String parentCnic;

  const NotificationsListScreen({Key? key, required this.parentCnic}) : super(key: key);

  String _cleanCNIC(String cnic) => cnic.replaceAll('-', '').trim();

  @override
  Widget build(BuildContext context) {
    final sanitizedCnic = _cleanCNIC(parentCnic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('parentCNIC', isEqualTo: sanitizedCnic)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F8A5F)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications found.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE5F7ED),
                  child: Icon(Icons.notifications_outlined, color: Color(0xFF0F8A5F)),
                ),
                title: Text(notif['title'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notif['message'] ?? ''),
                trailing: Text(notif['time'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }
} */
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentHomeScreen extends StatefulWidget {
  final String parentCnic;
  final Function(int)? onNavigateToTab;

  const ParentHomeScreen({
    Key? key,
    required this.parentCnic,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color primaryGreen = Color(0xFF0F8A5F);

  String _cleanCNIC(String cnic) {
    return cnic.replaceAll('-', '').trim();
  }

  // Helper method to open YouTube links directly
  Future<void> _launchVideoUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawCnic = widget.parentCnic.trim();
    final sanitizedCnic = _cleanCNIC(rawCnic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. TOP GREEN HEADER SECTION (EXACT LOGGED-IN PARENT FETCH)
              // -------------------------------------------------------------
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  String displayName = '';

                  // Check 1: Check in 'users' collection by CNIC
                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    for (var doc in userSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                      if (docCnic == sanitizedCnic) {
                        displayName = (data['name'] ?? data['fullName'] ?? data['parentName'] ?? '').toString().trim();
                        if (displayName.isNotEmpty) break;
                      }
                    }
                  }

                  if (displayName.isNotEmpty) {
                    return _buildHeaderUI(context, displayName, sanitizedCnic);
                  }

                  // Check 2: Fallback check in 'parents' collection
                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('parents').snapshots(),
                    builder: (context, parentSnapshot) {
                      String parentName = '';

                      if (parentSnapshot.hasData && parentSnapshot.data!.docs.isNotEmpty) {
                        for (var doc in parentSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                          if (docCnic == sanitizedCnic) {
                            parentName = (data['name'] ?? data['parentName'] ?? data['fullName'] ?? '').toString().trim();
                            if (parentName.isNotEmpty) break;
                          }
                        }
                      }

                      if (parentName.isNotEmpty) {
                        return _buildHeaderUI(context, parentName, sanitizedCnic);
                      }

                      // Check 3: If not found in profiles, check children collection matching EXACT CNIC
                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('children').where('parentCNIC', isEqualTo: sanitizedCnic).snapshots(),
                        builder: (context, childSnapshot) {
                          String childParentName = 'Parent';
                          if (childSnapshot.hasData && childSnapshot.data!.docs.isNotEmpty) {
                            final firstDoc = childSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            childParentName = (firstDoc['parentName'] ?? firstDoc['fatherName'] ?? 'Parent').toString().trim();
                          }
                          return _buildHeaderUI(context, childParentName, sanitizedCnic);
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. UPCOMING VACCINATIONS FOR LOGGED-IN PARENT'S CHILDREN ONLY
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upcoming Vaccinations',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.onNavigateToTab != null) {
                              widget.onNavigateToTab!(1); 
                            }
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('vaccination_tasks')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: primaryGreen),
                            ),
                          );
                        }

                        final taskDocs = snapshot.data?.docs ?? [];
                        final pendingTasks = taskDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString().toLowerCase();
                          return status != 'completed' && status != 'done';
                        }).toList();

                        if (pendingTasks.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No upcoming vaccinations due.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: pendingTasks.take(2).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final childName = data['childName'] ?? 'Child';
                            final vaccineName = data['vaccineName'] ?? 'Vaccine';
                            final dueDate = data['dueDate'] != null
                                ? (data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]
                                : 'N/A';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE5F7ED),
                                    child: Icon(Icons.person, color: primaryGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('Vaccine: $vaccineName', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                        Text('Due: $dueDate', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Due Soon', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. HEALTH EDUCATION VIDEOS (UPDATED FOR YOUR FIREBASE COLLECTION)
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Health Education Videos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EducationVideosScreen(),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      // Stream points to 'education_videos'
                      stream: _firestore.collection('education_videos').snapshots(),
                      builder: (context, videoSnapshot) {
                        if (videoSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final videoDocs = videoSnapshot.data?.docs ?? [];

                        if (videoDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No health videos uploaded yet.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 175,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: videoDocs.length,
                            itemBuilder: (context, index) {
                              final video = videoDocs[index].data() as Map<String, dynamic>;
                              final title = video['titleUrdu'] ?? video['titleEnglish'] ?? video['title'] ?? 'Health Video';
                              final videoUrl = video['videoUrl'] ?? '';
                              final duration = video['duration'] ?? '';
                              final category = video['category'] ?? 'Health';
                              
                              // Extract Thumbnail or build fallback YouTube Thumbnail
                              String thumbnailUrl = video['thumbnailUrl'] ?? video['thumbnail'] ?? '';
                              if (thumbnailUrl.isEmpty && videoUrl.contains('v=')) {
                                final videoId = videoUrl.split('v=').last.split('&').first;
                                thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                              }

                              return InkWell(
                                onTap: () => _launchVideoUrl(videoUrl),
                                child: _buildVideoCard(
                                  title: title,
                                  duration: duration.isNotEmpty ? duration : category,
                                  thumbnailUrl: thumbnailUrl,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 4. RECENT NOTIFICATIONS FOR THIS PARENT
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recent Notifications',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('notifications')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, notifSnapshot) {
                        if (notifSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final notifDocs = notifSnapshot.data?.docs ?? [];

                        if (notifDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No recent notifications.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: notifDocs.take(3).map((doc) {
                              final notif = doc.data() as Map<String, dynamic>;
                              return Column(
                                children: [
                                  _notificationItem(
                                    Icons.notifications_active_outlined,
                                    notif['title'] ?? 'Alert',
                                    notif['message'] ?? '',
                                    notif['time'] ?? 'Just now',
                                  ),
                                  if (doc != notifDocs.take(3).last) const Divider(height: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderUI(BuildContext context, String displayName, String sanitizedCnic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hello, $displayName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay updated on your child\'s vaccinations.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard({required String title, required String duration, required String thumbnailUrl}) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: thumbnailUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnailUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: const Center(
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (duration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(duration, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _notificationItem(IconData icon, String title, String message, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE5F7ED),
          child: Icon(icon, color: primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(message, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR HEALTH EDUCATION VIDEOS (FULL SCREEN VIEW)
// -------------------------------------------------------------
class EducationVideosScreen extends StatelessWidget {
  const EducationVideosScreen({Key? key}) : super(key: key);

  Future<void> _launchVideoUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education Videos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('education_videos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F8A5F)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No health education videos available.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final video = docs[index].data() as Map<String, dynamic>;
              final title = video['titleUrdu'] ?? video['titleEnglish'] ?? video['title'] ?? 'Health Video';
              final videoUrl = video['videoUrl'] ?? '';
              final duration = video['duration'] ?? '';
              final category = video['category'] ?? '';

              String thumbnailUrl = video['thumbnailUrl'] ?? video['thumbnail'] ?? '';
              if (thumbnailUrl.isEmpty && videoUrl.contains('v=')) {
                final videoId = videoUrl.split('v=').last.split('&').first;
                thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
              }

              return InkWell(
                onTap: () => _launchVideoUrl(videoUrl),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          image: thumbnailUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(thumbnailUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: const Center(
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (duration.isNotEmpty || category.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                duration.isNotEmpty ? duration : category,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR NOTIFICATIONS LIST
// -------------------------------------------------------------
class NotificationsListScreen extends StatelessWidget {
  final String parentCnic;

  const NotificationsListScreen({Key? key, required this.parentCnic}) : super(key: key);

  String _cleanCNIC(String cnic) => cnic.replaceAll('-', '').trim();

  @override
  Widget build(BuildContext context) {
    final sanitizedCnic = _cleanCNIC(parentCnic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('parentCNIC', isEqualTo: sanitizedCnic)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F8A5F)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No notifications found.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notif = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE5F7ED),
                  child: Icon(Icons.notifications_outlined, color: Color(0xFF0F8A5F)),
                ),
                title: Text(notif['title'] ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(notif['message'] ?? ''),
                trailing: Text(notif['time'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              );
            },
          );
        },
      ),
    );
  }
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// Helper function to extract high-quality YouTube thumbnail URL from video URL
String _getYouTubeThumbnail(String videoUrl) {
  final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
  if (videoId != null && videoId.isNotEmpty) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
  return '';
}

class ParentHomeScreen extends StatefulWidget {
  final String parentCnic;
  final Function(int)? onNavigateToTab;

  const ParentHomeScreen({
    Key? key,
    required this.parentCnic,
    this.onNavigateToTab,
  }) : super(key: key);

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Color primaryGreen = Color(0xFF0F8A5F);

  String _cleanCNIC(String cnic) {
    return cnic.replaceAll('-', '').trim();
  }

  // App ke andar hi Video Play karne ka Dialog
  void _playInAppVideo(BuildContext context, String videoUrl, String title) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null || videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid video URL')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _InAppVideoDialog(videoId: videoId, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawCnic = widget.parentCnic.trim();
    final sanitizedCnic = _cleanCNIC(rawCnic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // 1. TOP GREEN HEADER SECTION
              // -------------------------------------------------------------
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, userSnapshot) {
                  String displayName = '';

                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    for (var doc in userSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                      if (docCnic == sanitizedCnic) {
                        displayName = (data['name'] ?? data['fullName'] ?? data['parentName'] ?? '').toString().trim();
                        if (displayName.isNotEmpty) break;
                      }
                    }
                  }

                  if (displayName.isNotEmpty) {
                    return _buildHeaderUI(context, displayName, sanitizedCnic);
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('parents').snapshots(),
                    builder: (context, parentSnapshot) {
                      String parentName = '';

                      if (parentSnapshot.hasData && parentSnapshot.data!.docs.isNotEmpty) {
                        for (var doc in parentSnapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final docCnic = _cleanCNIC(data['cnic'] ?? data['parentCNIC'] ?? doc.id);
                          if (docCnic == sanitizedCnic) {
                            parentName = (data['name'] ?? data['parentName'] ?? data['fullName'] ?? '').toString().trim();
                            if (parentName.isNotEmpty) break;
                          }
                        }
                      }

                      if (parentName.isNotEmpty) {
                        return _buildHeaderUI(context, parentName, sanitizedCnic);
                      }

                      return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('children').where('parentCNIC', isEqualTo: sanitizedCnic).snapshots(),
                        builder: (context, childSnapshot) {
                          String childParentName = 'Parent';
                          if (childSnapshot.hasData && childSnapshot.data!.docs.isNotEmpty) {
                            final firstDoc = childSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            childParentName = (firstDoc['parentName'] ?? firstDoc['fatherName'] ?? 'Parent').toString().trim();
                          }
                          return _buildHeaderUI(context, childParentName, sanitizedCnic);
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. UPCOMING VACCINATIONS
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upcoming Vaccinations',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            if (widget.onNavigateToTab != null) {
                              widget.onNavigateToTab!(1);
                            }
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('vaccination_tasks')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: primaryGreen),
                            ),
                          );
                        }

                        final taskDocs = snapshot.data?.docs ?? [];
                        final pendingTasks = taskDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = (data['status'] ?? '').toString().toLowerCase();
                          return status != 'completed' && status != 'done';
                        }).toList();

                        if (pendingTasks.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No upcoming vaccinations due.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: pendingTasks.take(2).map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final childName = data['childName'] ?? 'Child';
                            final vaccineName = data['vaccineName'] ?? 'Vaccine';
                            final dueDate = data['dueDate'] != null
                                ? (data['dueDate'] as Timestamp).toDate().toString().split(' ')[0]
                                : 'N/A';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE5F7ED),
                                    child: Icon(Icons.person, color: primaryGreen),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('Vaccine: $vaccineName', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                        Text('Due: $dueDate', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('Due Soon', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. HEALTH EDUCATION VIDEOS
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_outline, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Health Education Videos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EducationVideosScreen(),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('education_videos').snapshots(),
                      builder: (context, videoSnapshot) {
                        if (videoSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final videoDocs = videoSnapshot.data?.docs ?? [];

                        if (videoDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No health videos uploaded yet.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 175,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: videoDocs.length,
                            itemBuilder: (context, index) {
                              final video = videoDocs[index].data() as Map<String, dynamic>;
                              final title = video['titleUrdu'] ?? video['titleEnglish'] ?? video['title'] ?? 'Health Video';
                              final videoUrl = video['videoUrl'] ?? '';
                              final duration = video['duration'] ?? '';
                              final category = video['category'] ?? 'Health';

                              String thumbnailUrl = video['thumbnailUrl'] ?? video['thumbnail'] ?? '';
                              if (thumbnailUrl.isEmpty && videoUrl.isNotEmpty) {
                                thumbnailUrl = _getYouTubeThumbnail(videoUrl);
                              }

                              return InkWell(
                                onTap: () => _playInAppVideo(context, videoUrl, title),
                                child: _buildVideoCard(
                                  title: title,
                                  duration: duration.isNotEmpty ? duration : category,
                                  thumbnailUrl: thumbnailUrl,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 4. RECENT NOTIFICATIONS
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Recent Notifications',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                              ),
                            );
                          },
                          child: const Text('View All >', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('notifications')
                          .where('parentCNIC', isEqualTo: sanitizedCnic)
                          .snapshots(),
                      builder: (context, notifSnapshot) {
                        if (notifSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: primaryGreen));
                        }

                        final notifDocs = notifSnapshot.data?.docs ?? [];

                        if (notifDocs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'No recent notifications.',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: notifDocs.take(3).map((doc) {
                              final notif = doc.data() as Map<String, dynamic>;
                              return Column(
                                children: [
                                  _notificationItem(
                                    Icons.notifications_active_outlined,
                                    notif['title'] ?? 'Alert',
                                    notif['message'] ?? '',
                                    notif['time'] ?? 'Just now',
                                  ),
                                  if (doc != notifDocs.take(3).last) const Divider(height: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderUI(BuildContext context, String displayName, String sanitizedCnic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Hello, $displayName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsListScreen(parentCnic: sanitizedCnic),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay updated on your child\'s vaccinations.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard({required String title, required String duration, required String thumbnailUrl}) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              image: thumbnailUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnailUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: const Center(
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (duration.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(duration, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ),
        ],
      ),
    );
  }

  Widget _notificationItem(IconData icon, String title, String message, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFE5F7ED),
          child: Icon(icon, color: primaryGreen, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(message, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              const SizedBox(height: 2),
              Text(time, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// WEB & MOBILE COMPATIBLE IN-APP VIDEO DIALOG
// -------------------------------------------------------------
class _InAppVideoDialog extends StatefulWidget {
  final String videoId;
  final String title;

  const _InAppVideoDialog({Key? key, required this.videoId, required this.title}) : super(key: key);

  @override
  State<_InAppVideoDialog> createState() => _InAppVideoDialogState();
}

class _InAppVideoDialogState extends State<_InAppVideoDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: Text(widget.title, style: const TextStyle(fontSize: 14, color: Colors.white)),
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Flexible(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR HEALTH EDUCATION VIDEOS
// -------------------------------------------------------------
class EducationVideosScreen extends StatelessWidget {
  const EducationVideosScreen({Key? key}) : super(key: key);

  void _playInAppVideo(BuildContext context, String videoUrl, String title) {
    final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
    if (videoId == null || videoId.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _InAppVideoDialog(videoId: videoId, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education Videos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('education_videos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F8A5F)));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No health education videos available.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final video = docs[index].data() as Map<String, dynamic>;
              final title = video['titleUrdu'] ?? video['titleEnglish'] ?? video['title'] ?? 'Health Video';
              final videoUrl = video['videoUrl'] ?? '';
              final duration = video['duration'] ?? '';
              final category = video['category'] ?? '';

              String thumbnailUrl = video['thumbnailUrl'] ?? video['thumbnail'] ?? '';
              if (thumbnailUrl.isEmpty && videoUrl.isNotEmpty) {
                thumbnailUrl = _getYouTubeThumbnail(videoUrl);
              }

              return InkWell(
                onTap: () => _playInAppVideo(context, videoUrl, title),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          image: thumbnailUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(thumbnailUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: const Center(
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.play_arrow, color: Colors.white, size: 32),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (duration.isNotEmpty || category.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                duration.isNotEmpty ? duration : category,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// DEDICATED SCREEN FOR NOTIFICATIONS LIST
// -------------------------------------------------------------
class NotificationsListScreen extends StatelessWidget {
  final String parentCnic;

  const NotificationsListScreen({Key? key, required this.parentCnic}) : super(key: key);

  String _cleanCNIC(String cnic) => cnic.replaceAll('-', '').trim();

  @override
  Widget build(BuildContext context) {
    final sanitizedCnic = _cleanCNIC(parentCnic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Notifications', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F8A5F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('parentCNIC', isEqualTo: sanitizedCnic)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F8A5F)),
            );
          }

          final notifDocs = snapshot.data?.docs ?? [];

          if (notifDocs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications found.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifDocs.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final notif = notifDocs[index].data() as Map<String, dynamic>;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFE5F7ED),
                    child: Icon(Icons.notifications_active_outlined, color: Color(0xFF0F8A5F), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['title'] ?? 'Alert',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['message'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['time'] ?? 'Just now',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}