/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';

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
  bool _showAllUpcoming = false;
  static const int _upcomingCollapsedLimit = 3;

  String _cleanCNIC(String cnic) {
    return cnic.replaceAll('-', '').trim();
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
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
                        stream: _firestore.collection('children').where('cnic', isEqualTo: sanitizedCnic).snapshots(),
                        builder: (context, childSnapshot) {
                          String childParentName = 'Parent';
                          if (childSnapshot.hasData && childSnapshot.data!.docs.isNotEmpty) {
                            final firstDoc = childSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            childParentName = (firstDoc['parentName'] ?? firstDoc['motherName'] ?? firstDoc['fatherName'] ?? 'Parent').toString().trim();
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
              // 2. UPCOMING VACCINATIONS (EPI schedule based, same logic as
              //    the vaccinator module's Routine History tab)
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

                    _UpcomingVaccinationsList(
                      cnic: sanitizedCnic,
                      firestore: _firestore,
                      primaryGreen: primaryGreen,
                      normalize: _normalize,
                      parseDob: _parseDob,
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
// UPCOMING VACCINATIONS LIST (all children of this parent)
// For every child, finds the NEAREST vaccine that is not yet
// given and not missed (missed doses are intentionally excluded
// -- this section is "what's coming next", not "what was missed").
// All children's next-due items are combined into one list,
// sorted by due date (soonest first), with a View More / View
// Less toggle when there are more than 3 items.
// -------------------------------------------------------------
class _UpcomingVaccinationsList extends StatefulWidget {
  final String cnic;
  final FirebaseFirestore firestore;
  final Color primaryGreen;
  final String Function(String) normalize;
  final DateTime Function(dynamic) parseDob;

  const _UpcomingVaccinationsList({
    Key? key,
    required this.cnic,
    required this.firestore,
    required this.primaryGreen,
    required this.normalize,
    required this.parseDob,
  }) : super(key: key);

  @override
  State<_UpcomingVaccinationsList> createState() => _UpcomingVaccinationsListState();
}

class _UpcomingVaccinationsListState extends State<_UpcomingVaccinationsList> {
  bool _showAll = false;
  static const int _collapsedCount = 3;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.firestore
          .collection('children')
          .where('cnic', isEqualTo: widget.cnic)
          .snapshots(),
      builder: (context, childrenSnapshot) {
        if (childrenSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final childDocs = childrenSnapshot.data?.docs ?? [];

        if (childDocs.isEmpty) {
          return _buildEmptyBox();
        }

        // Same collection-wide read pattern already used elsewhere in
        // the app (history screen), then filtered client-side per child.
        return StreamBuilder<QuerySnapshot>(
          stream: widget.firestore.collection('vaccinations').snapshots(),
          builder: (context, vaxSnapshot) {
            final Map<String, List<Map<String, dynamic>>> recordsByChild = {};
            if (vaxSnapshot.hasData) {
              for (var doc in vaxSnapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final String cid = (d['childId'] ?? '').toString();
                if (cid.isEmpty) continue;
                recordsByChild.putIfAbsent(cid, () => []).add({
                  'vaccineName': (d['vaccineName'] ?? '').toString(),
                  'status': (d['status'] ?? 'vaccinated').toString().toLowerCase(),
                });
              }
            }

            final now = DateTime.now();
            List<Map<String, dynamic>> items = [];

            for (var doc in childDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final String childId = doc.id;
              final String childName = data['fullName'] ??
                  data['name'] ??
                  data['childName'] ??
                  'Child';
              final dob = widget.parseDob(data['dob'] ?? data['dateOfBirth']);
              final givenRecords = recordsByChild[childId] ?? [];

              final schedule = EpiScheduleHelper.generateEpiSchedule(dob);

              String? nextVaccineName;
              DateTime? nextDueDate;

              for (var stage in schedule) {
                final DateTime dueDate = stage['dueDate'];
                final List<String> vaccines = List<String>.from(stage['vaccines']);

                for (var vaccine in vaccines) {
                  String targetNorm = widget.normalize(vaccine);

                  bool isGiven = givenRecords.any((r) {
                    String storedNorm = widget.normalize(r['vaccineName']);
                    return storedNorm == targetNorm ||
                        storedNorm.contains(targetNorm) ||
                        targetNorm.contains(storedNorm);
                  });

                  if (isGiven) continue;

                  bool isMissed =
                      now.isAfter(dueDate.add(const Duration(days: 14)));
                  if (isMissed) continue; // skip missed doses entirely

                  if (nextDueDate == null || dueDate.isBefore(nextDueDate)) {
                    nextDueDate = dueDate;
                    nextVaccineName = vaccine;
                  }
                }
              }

              if (nextVaccineName != null && nextDueDate != null) {
                items.add({
                  'childName': childName,
                  'vaccine': nextVaccineName,
                  'dueDate': nextDueDate,
                  'isDueNow': now.isAfter(nextDueDate) || now.isAtSameMomentAs(nextDueDate),
                });
              }
            }

            if (items.isEmpty) {
              return _buildEmptyBox();
            }

            // Soonest due date first.
            items.sort((a, b) =>
                (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

            final bool hasMore = items.length > _collapsedCount;
            final List<Map<String, dynamic>> visibleItems =
                _showAll ? items : items.take(_collapsedCount).toList();

            return Column(
              children: [
                ...visibleItems.map((item) {
                  final DateTime dueDate = item['dueDate'] as DateTime;
                  final bool isDueNow = item['isDueNow'] as bool;
                  final String dueDateFormatted =
                      '${dueDate.day.toString().padLeft(2, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.year}';

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
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE5F7ED),
                          child: Icon(Icons.person, color: widget.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['childName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('Vaccine: ${item['vaccine']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text('Due: $dueDateFormatted', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDueNow ? Colors.red.shade50 : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isDueNow ? 'Due Now' : 'Upcoming',
                            style: TextStyle(
                              color: isDueNow ? Colors.red : Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (hasMore)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? 'View Less' : 'View More (${items.length - _collapsedCount} more)',
                      style: TextStyle(color: widget.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyBox() {
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
} */
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'package:immunosphere2/models/campaign_model.dart';
import 'campaign_details_screen.dart';
import 'notification_center_screen.dart';

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
  static const Color darkGreen = Color(0xFF0B4D30);
  static const Color primaryGreen = Color(0xFF0E7A45);
  static const Color lightGreenBg = Color(0xFFE5F7ED);
  bool _showAllUpcoming = false;
  static const int _upcomingCollapsedLimit = 2;

  String _cleanCNIC(String cnic) {
    return cnic.replaceAll('-', '').trim();
  }

  String _normalize(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  DateTime _parseDob(dynamic dobVal) {
    if (dobVal is Timestamp) return dobVal.toDate();
    if (dobVal is DateTime) return dobVal;
    if (dobVal is String && dobVal.trim().isNotEmpty) {
      return DateTime.tryParse(dobVal) ?? DateTime.now();
    }
    return DateTime.now();
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
                        stream: _firestore.collection('children').where('cnic', isEqualTo: sanitizedCnic).snapshots(),
                        builder: (context, childSnapshot) {
                          String childParentName = 'Parent';
                          if (childSnapshot.hasData && childSnapshot.data!.docs.isNotEmpty) {
                            final firstDoc = childSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                            childParentName = (firstDoc['parentName'] ?? firstDoc['motherName'] ?? firstDoc['fatherName'] ?? 'Parent').toString().trim();
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
              // 1B. ACTIVE / UPCOMING CAMPAIGN BANNER
              // -------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _CampaignBanner(
                  cnic: sanitizedCnic,
                  firestore: _firestore,
                  darkGreen: darkGreen,
                  primaryGreen: primaryGreen,
                  lightGreenBg: lightGreenBg,
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. UPCOMING VACCINATIONS (EPI schedule based, same logic as
              //    the vaccinator module's Routine History tab)
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

                    _UpcomingVaccinationsList(
                      cnic: sanitizedCnic,
                      firestore: _firestore,
                      primaryGreen: primaryGreen,
                      normalize: _normalize,
                      parseDob: _parseDob,
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
                                builder: (context) => NotificationCenterScreen(parentCNIC: sanitizedCnic),
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
        color: darkGreen,
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
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ImmunoSphere',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'AI-Powered Immunization & Vaccination',
                        style: TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('notifications')
                    .where('parentCNIC', isEqualTo: sanitizedCnic)
                    .snapshots(),
                builder: (context, notifSnap) {
                  final unreadCount = (notifSnap.data?.docs ?? [])
                      .where((d) => (d.data() as Map<String, dynamic>)['isRead'] != true)
                      .length;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationCenterScreen(parentCNIC: sanitizedCnic),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Hello, $displayName 👋',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Stay updated on your child\'s vaccinations.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
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
// ACTIVE / UPCOMING CAMPAIGN BANNER
// Finds campaigns this parent's children are actually assigned to
// (via campaign_assignments), picks whichever is currently active,
// else the soonest upcoming one, and links through to its real
// details screen for one of the assigned children.
// -------------------------------------------------------------
class _CampaignBanner extends StatelessWidget {
  final String cnic;
  final FirebaseFirestore firestore;
  final Color darkGreen;
  final Color primaryGreen;
  final Color lightGreenBg;

  const _CampaignBanner({
    Key? key,
    required this.cnic,
    required this.firestore,
    required this.darkGreen,
    required this.primaryGreen,
    required this.lightGreenBg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('children').where('cnic', isEqualTo: cnic).snapshots(),
      builder: (context, childrenSnap) {
        final childIds = (childrenSnap.data?.docs ?? []).map((d) => d.id).toList();
        if (childIds.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchAssignments(childIds),
          builder: (context, assignSnap) {
            if (!assignSnap.hasData || assignSnap.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final assignments = assignSnap.data!;
            final campaignToChild = <String, String>{};
            for (var doc in assignments) {
              final data = doc.data() as Map<String, dynamic>;
              final cid = (data['campaignId'] ?? '').toString();
              final childId = (data['childId'] ?? '').toString();
              if (cid.isNotEmpty && !campaignToChild.containsKey(cid)) {
                campaignToChild[cid] = childId;
              }
            }

            return FutureBuilder<List<CampaignModel>>(
              future: _fetchCampaigns(campaignToChild.keys.toList()),
              builder: (context, campSnap) {
                final campaigns = campSnap.data ?? [];
                if (campaigns.isEmpty) return const SizedBox.shrink();

                final now = DateTime.now();
                CampaignModel? selected;

                // Prefer a campaign that's currently running.
                for (var c in campaigns) {
                  if (!now.isBefore(c.startDate) && !now.isAfter(c.endDate)) {
                    selected = c;
                    break;
                  }
                }
                // Otherwise the soonest upcoming one.
                if (selected == null) {
                  final upcoming = campaigns.where((c) => now.isBefore(c.startDate)).toList()
                    ..sort((a, b) => a.startDate.compareTo(b.startDate));
                  if (upcoming.isNotEmpty) selected = upcoming.first;
                }

                if (selected == null) return const SizedBox.shrink();

                final isActive = !now.isBefore(selected.startDate) && !now.isAfter(selected.endDate);
                final area = selected.targetAreas.isNotEmpty ? selected.targetAreas.join(', ') : 'your area';
                final dateRange =
                    '${_fmt(selected.startDate)} – ${_fmt(selected.endDate)}';
                final childId = campaignToChild[selected.id] ?? childIds.first;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CampaignDetailsScreen(
                          campaign: selected!,
                          childId: childId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.shield_outlined, color: darkGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selected.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87)),
                              const SizedBox(height: 4),
                              Text(
                                isActive
                                    ? '${selected.name} is currently active in $area.'
                                    : '${selected.name} will start soon in $area.',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 6),
                              Text(dateRange, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('View Details', style: TextStyle(fontSize: 11, color: primaryGreen, fontWeight: FontWeight.bold)),
                            Icon(Icons.chevron_right, color: primaryGreen, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';

  String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Future<List<QueryDocumentSnapshot>> _fetchAssignments(List<String> childIds) async {
    final List<QueryDocumentSnapshot> result = [];
    for (var i = 0; i < childIds.length; i += 10) {
      final end = (i + 10 > childIds.length) ? childIds.length : i + 10;
      final chunk = childIds.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await firestore
          .collection('campaign_assignments')
          .where('childId', whereIn: chunk)
          .get();
      result.addAll(snap.docs);
    }
    return result;
  }

  Future<List<CampaignModel>> _fetchCampaigns(List<String> ids) async {
    final List<CampaignModel> result = [];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 > ids.length) ? ids.length : i + 10;
      final chunk = ids.sublist(i, end);
      if (chunk.isEmpty) continue;
      final snap = await firestore.collection('campaigns').where(FieldPath.documentId, whereIn: chunk).get();
      for (var doc in snap.docs) {
        result.add(CampaignModel.fromMap(doc.data(), doc.id));
      }
    }
    return result;
  }
}

// -------------------------------------------------------------
// UPCOMING VACCINATIONS LIST (all children of this parent)
// For every child, finds the NEAREST vaccine that is not yet
// given and not missed (missed doses are intentionally excluded
// -- this section is "what's coming next", not "what was missed").
// All children's next-due items are combined into one list,
// sorted by due date (soonest first), with a View More / View
// Less toggle when there are more than 3 items.
// -------------------------------------------------------------
class _UpcomingVaccinationsList extends StatefulWidget {
  final String cnic;
  final FirebaseFirestore firestore;
  final Color primaryGreen;
  final String Function(String) normalize;
  final DateTime Function(dynamic) parseDob;

  const _UpcomingVaccinationsList({
    Key? key,
    required this.cnic,
    required this.firestore,
    required this.primaryGreen,
    required this.normalize,
    required this.parseDob,
  }) : super(key: key);

  @override
  State<_UpcomingVaccinationsList> createState() => _UpcomingVaccinationsListState();
}

class _UpcomingVaccinationsListState extends State<_UpcomingVaccinationsList> {
  bool _showAll = false;
  static const int _collapsedCount = 2;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: widget.firestore
          .collection('children')
          .where('cnic', isEqualTo: widget.cnic)
          .snapshots(),
      builder: (context, childrenSnapshot) {
        if (childrenSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final childDocs = childrenSnapshot.data?.docs ?? [];

        if (childDocs.isEmpty) {
          return _buildEmptyBox();
        }

        // Same collection-wide read pattern already used elsewhere in
        // the app (history screen), then filtered client-side per child.
        return StreamBuilder<QuerySnapshot>(
          stream: widget.firestore.collection('vaccinations').snapshots(),
          builder: (context, vaxSnapshot) {
            final Map<String, List<Map<String, dynamic>>> recordsByChild = {};
            if (vaxSnapshot.hasData) {
              for (var doc in vaxSnapshot.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final String cid = (d['childId'] ?? '').toString();
                if (cid.isEmpty) continue;
                recordsByChild.putIfAbsent(cid, () => []).add({
                  'vaccineName': (d['vaccineName'] ?? '').toString(),
                  'status': (d['status'] ?? 'vaccinated').toString().toLowerCase(),
                });
              }
            }

            final now = DateTime.now();
            List<Map<String, dynamic>> items = [];

            for (var doc in childDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final String childId = doc.id;
              final String childName = data['fullName'] ??
                  data['name'] ??
                  data['childName'] ??
                  'Child';
              final dob = widget.parseDob(data['dob'] ?? data['dateOfBirth']);
              final gender = (data['gender'] ?? 'boy').toString().toLowerCase();
              final givenRecords = recordsByChild[childId] ?? [];

              final schedule = EpiScheduleHelper.generateEpiSchedule(dob);

              String? nextVaccineName;
              DateTime? nextDueDate;

              for (var stage in schedule) {
                final DateTime dueDate = stage['dueDate'];
                final List<String> vaccines = List<String>.from(stage['vaccines']);

                for (var vaccine in vaccines) {
                  String targetNorm = widget.normalize(vaccine);

                  bool isGiven = givenRecords.any((r) {
                    String storedNorm = widget.normalize(r['vaccineName']);
                    return storedNorm == targetNorm ||
                        storedNorm.contains(targetNorm) ||
                        targetNorm.contains(storedNorm);
                  });

                  if (isGiven) continue;

                  bool isMissed =
                      now.isAfter(dueDate.add(const Duration(days: 14)));
                  if (isMissed) continue; // skip missed doses entirely

                  if (nextDueDate == null || dueDate.isBefore(nextDueDate)) {
                    nextDueDate = dueDate;
                    nextVaccineName = vaccine;
                  }
                }
              }

              if (nextVaccineName != null && nextDueDate != null) {
                items.add({
                  'childName': childName,
                  'gender': gender,
                  'vaccine': nextVaccineName,
                  'dueDate': nextDueDate,
                  'isDueNow': now.isAfter(nextDueDate) || now.isAtSameMomentAs(nextDueDate),
                });
              }
            }

            if (items.isEmpty) {
              return _buildEmptyBox();
            }

            // Soonest due date first.
            items.sort((a, b) =>
                (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

            final bool hasMore = items.length > _collapsedCount;
            final List<Map<String, dynamic>> visibleItems =
                _showAll ? items : items.take(_collapsedCount).toList();

            return Column(
              children: [
                ...visibleItems.map((item) {
                  final DateTime dueDate = item['dueDate'] as DateTime;
                  final bool isDueNow = item['isDueNow'] as bool;
                  final String gender = item['gender'] as String;
                  final isMale = gender == 'boy' || gender == 'male';
                  final daysUntil = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;

                  String badgeText;
                  if (daysUntil < 0) {
                    badgeText = 'Overdue';
                  } else if (daysUntil == 0) {
                    badgeText = 'Due Today';
                  } else {
                    badgeText = 'Due in $daysUntil day${daysUntil != 1 ? 's' : ''}';
                  }

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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE5F7ED),
                          child: Text(isMale ? '👦' : '👧', style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['childName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(item['vaccine'], style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              Text(
                                'Due on ${dueDate.day.toString().padLeft(2, '0')} ${_month(dueDate.month)} ${dueDate.year}',
                                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDueNow || daysUntil < 0 ? Colors.red.shade50 : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: isDueNow || daysUntil < 0 ? Colors.red : Colors.blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                if (hasMore)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? 'View Less' : '+${items.length - _collapsedCount} more vaccine due',
                      style: TextStyle(color: widget.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }

  Widget _buildEmptyBox() {
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
        backgroundColor: const Color(0xFF0B4D30),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('education_videos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0B4D30)));
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
        backgroundColor: const Color(0xFF0B4D30),
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
              child: CircularProgressIndicator(color: Color(0xFF0B4D30)),
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
                    child: Icon(Icons.notifications_active_outlined, color: Color(0xFF0B4D30), size: 20),
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