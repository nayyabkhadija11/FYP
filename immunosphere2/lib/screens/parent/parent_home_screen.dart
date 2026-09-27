import 'package:flutter/material.dart';
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
} 
/*import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:immunosphere2/helpers/epi_schedule_helper.dart';
import 'child_detail_screen.dart';

// =====================================================================
// THEME (ImmunoSphere dark-green design) -- kept inside this file
// =====================================================================
class _C {
  static const Color primary = Color(0xFF0B4D30);
  static const Color accent = Color(0xFF0E7A45);
  static const Color bg = Color(0xFFF1F7F4);
  static const Color mint = Color(0xFFE3F2EA);
  static const Color border = Color(0xFFE2EAE6);
  static const Color text = Color(0xFF1F2937);
  static const Color grey = Color(0xFF6B7280);
  static const Color due = Color(0xFFDC2626);
  static const Color dueBg = Color(0xFFFDECEC);
  static const Color upcoming = Color(0xFF2563EB);
  static const Color upcomingBg = Color(0xFFE0ECFF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFF4DD);
  static const Color ok = Color(0xFF16A34A);
  static const Color okBg = Color(0xFFE5F5EB);
}

// =====================================================================
// SMALL HELPERS
// =====================================================================
DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final p = s.split(RegExp(r'[/-]'));
    if (p.length == 3 && p[0].length <= 2 && p[2].length == 4) {
      return DateTime.tryParse(
          '${p[2]}-${p[1].padLeft(2, '0')}-${p[0].padLeft(2, '0')}');
    }
    return DateTime.tryParse(s);
  }
  return null;
}

String _fmt(DateTime? d) =>
    d == null ? 'N/A' : DateFormat('dd MMM yyyy').format(d);

String _fmtRange(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 'Dates not announced';
  if (a == null) return _fmt(b);
  if (b == null) return _fmt(a);
  if (a.year == b.year) {
    return '${DateFormat('dd MMM').format(a)} – ${DateFormat('dd MMM yyyy').format(b)}';
  }
  return '${_fmt(a)} – ${_fmt(b)}';
}

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// "Pentavalent-1" -> "Pentavalent (Dose 1)"
String _pretty(String v) {
  final m = RegExp(r'^(.*?)-(\d+)$').firstMatch(v.trim());
  if (m != null) return '${m.group(1)} (Dose ${m.group(2)})';
  return v;
}

String _cleanCnic(String c) => c.replaceAll('-', '').replaceAll(' ', '').trim();

String _childName(Map<String, dynamic> d) =>
    (d['childName'] ?? d['fullName'] ?? d['name'] ?? 'Child').toString();

bool _isMale(Map<String, dynamic> d) {
  final g = (d['gender'] ?? '').toString().toLowerCase();
  return g == 'male' || g == 'boy' || g.isEmpty;
}

String _ageText(dynamic dobVal) {
  final dob = _toDate(dobVal);
  if (dob == null) return 'Age: N/A';
  final now = DateTime.now();
  int years = now.year - dob.year;
  int months = now.month - dob.month;
  if (now.day < dob.day) months--;
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years < 0) return '0 Months';
  final m = '$months Month${months != 1 ? 's' : ''}';
  return years > 0 ? '$years Year${years > 1 ? 's' : ''}, $m' : m;
}

String _notifCategory(Map<String, dynamic> n) {
  final t =
      '${n['type'] ?? ''} ${n['title'] ?? ''} ${n['message'] ?? ''}'.toLowerCase();
  if (t.contains('polio') || t.contains('campaign')) return 'Campaign';
  if (t.contains('education') || t.contains('video') || t.contains('health tip')) {
    return 'Education';
  }
  return 'Routine';
}

DateTime? _notifDate(Map<String, dynamic> n) =>
    _toDate(n['createdAt'] ?? n['timestamp'] ?? n['sentAt']);

String _timeAgo(Map<String, dynamic> n) {
  final d = _notifDate(n);
  if (d == null) return (n['time'] ?? 'Just now').toString();
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _fmt(d);
}

String _youtubeThumb(String url) {
  final id = YoutubePlayerController.convertUrlToId(url);
  if (id != null && id.isNotEmpty) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  return '';
}

class _Video {
  final String title, url, duration, thumb;
  _Video(this.title, this.url, this.duration, this.thumb);

  factory _Video.fromMap(Map<String, dynamic> d) {
    final title =
        (d['titleUrdu'] ?? d['titleEnglish'] ?? d['title'] ?? 'Health Video')
            .toString();
    String url = (d['videoUrl'] ?? '').toString();
    final vid = (d['videoId'] ?? '').toString();
    if (url.isEmpty && vid.isNotEmpty) url = 'https://www.youtube.com/watch?v=$vid';
    String thumb = (d['thumbnailUrl'] ?? d['thumbnail'] ?? '').toString();
    if (thumb.isEmpty && url.isNotEmpty) thumb = _youtubeThumb(url);
    final duration = (d['duration'] ?? d['category'] ?? '').toString();
    return _Video(title, url, duration, thumb);
  }
}

void _playVideo(BuildContext context, _Video v) {
  final id = YoutubePlayerController.convertUrlToId(v.url);
  if (id == null || id.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Invalid video URL')));
    return;
  }
  showDialog(
    context: context,
    builder: (_) => _InAppVideoDialog(videoId: id, title: v.title),
  );
}

// ---------------------------------------------------------------------
// Campaign model (raw Firestore map -> safe object)
// ---------------------------------------------------------------------
class _Campaign {
  final String id, name, type, status;
  final DateTime? start, end;
  final List<String> areas;

  _Campaign(this.id, this.name, this.type, this.status, this.start, this.end,
      this.areas);

  factory _Campaign.fromMap(String id, Map<String, dynamic> d) {
    final a = d['targetAreas'];
    return _Campaign(
      id,
      (d['name'] ?? 'Polio Campaign').toString(),
      (d['type'] ?? 'Polio').toString(),
      (d['status'] ?? 'active').toString().toLowerCase(),
      _toDate(d['startDate']),
      _toDate(d['endDate']),
      a is List ? a.map((e) => e.toString()).toList() : <String>[],
    );
  }

  bool get isCompleted {
    if (status == 'completed') return true;
    if (end != null && DateTime.now().isAfter(end!.add(const Duration(days: 1)))) {
      return true;
    }
    return false;
  }

  bool get hasStarted => start != null && !DateTime.now().isBefore(start!);

  bool targets(String village) {
    final v = village.trim().toLowerCase();
    if (v.isEmpty) return false;
    return areas.any((a) => a.trim().toLowerCase() == v);
  }

  String get areaText => areas.join(', ');
  String get dates => _fmtRange(start, end);
  String get vaccineLabel =>
      type.toLowerCase().contains('polio') ? 'OPV (Oral Polio Vaccine)' : type;
}

// ---------------------------------------------------------------------
// Shared little widgets
// ---------------------------------------------------------------------
class _Chip extends StatelessWidget {
  final String text;
  final Color color, bg;
  const _Chip(this.text, this.color, this.bg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsetsGeometry padding;
  const _Card({
    required this.child,
    this.onTap,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onTap, child: box);
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: _C.accent),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard(this.text);
  @override
  Widget build(BuildContext context) => _Card(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(text,
              style: const TextStyle(color: _C.grey, fontWeight: FontWeight.w500)),
        ),
      );
}

// =====================================================================
// PARENT HOME / DASHBOARD
// =====================================================================
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
  late final String _cnic;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _childrenStream;
  late final Future<String> _nameFuture;

  // ---- new-campaign popup state ----
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _popupChildrenSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _popupCampaignsSub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _popupChildren = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _popupCampaigns = [];
  Set<String> _seenCampaigns = {};
  bool _seenLoaded = false;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    _cnic = _cleanCnic(widget.parentCnic);
    _childrenStream = FirebaseFirestore.instance
        .collection('children')
        .where('cnic', isEqualTo: _cnic)
        .snapshots();
    _nameFuture = _loadName();
    _initCampaignPopup();
  }

  @override
  void dispose() {
    _popupChildrenSub?.cancel();
    _popupCampaignsSub?.cancel();
    super.dispose();
  }

  Future<String> _loadName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final n = (doc.data()?['fullName'] ?? doc.data()?['name'] ?? '')
            .toString()
            .trim();
        if (n.isNotEmpty) return n.split(' ').first;
      }
    } catch (_) {}
    return 'Parent';
  }

  // -------------------------------------------------------------------
  // NEW CAMPAIGN POPUP
  // Once per campaign per parent, live. Seen ids are stored in
  // users/{uid}.seenCampaignPopups.
  // -------------------------------------------------------------------
  Future<void> _initCampaignPopup() async {
    final db = FirebaseFirestore.instance;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await db.collection('users').doc(uid).get();
        final seen = doc.data()?['seenCampaignPopups'];
        if (seen is List) {
          _seenCampaigns = seen.map((e) => e.toString()).toSet();
        }
      }
    } catch (_) {}
    _seenLoaded = true;
    if (!mounted) return;

    _popupChildrenSub = db
        .collection('children')
        .where('cnic', isEqualTo: _cnic)
        .snapshots()
        .listen((snap) {
      _popupChildren = snap.docs;
      _maybeShowCampaignPopup();
    }, onError: (_) {});

    _popupCampaignsSub = db.collection('campaigns').snapshots().listen((snap) {
      _popupCampaigns = snap.docs;
      _maybeShowCampaignPopup();
    }, onError: (_) {});
  }

  Future<void> _markCampaignSeen(String id) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'seenCampaignPopups': FieldValue.arrayUnion([id]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _maybeShowCampaignPopup() {
    if (!mounted || !_seenLoaded || _popupShowing) return;
    if (_popupChildren.isEmpty || _popupCampaigns.isEmpty) return;

    final candidates = _popupCampaigns
        .map((d) => _Campaign.fromMap(d.id, d.data()))
        .where((c) => !c.isCompleted && !_seenCampaigns.contains(c.id))
        .toList()
      ..sort((a, b) =>
          (a.start ?? DateTime(2100)).compareTo(b.start ?? DateTime(2100)));

    _Campaign? found;
    List<QueryDocumentSnapshot<Map<String, dynamic>>> targets = [];
    for (final c in candidates) {
      final t = _popupChildren
          .where((ch) => c.targets((ch.data()['village'] ?? '').toString()))
          .toList();
      if (t.isNotEmpty) {
        found = c;
        targets = t;
        break;
      }
    }
    if (found == null) return;

    final campaign = found;
    _popupShowing = true;
    _seenCampaigns.add(campaign.id);
    _markCampaignSeen(campaign.id);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _popupShowing = false;
        return;
      }
      await showDialog(
        context: context,
        builder: (ctx) => _CampaignPopup(
          campaign: campaign,
          children: targets,
          onView: () {
            Navigator.pop(ctx);
            _showCampaignSheet(context, campaign, targets);
          },
        ),
      );
      _popupShowing = false;
      _maybeShowCampaignPopup(); // next unseen campaign, if any
    });
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => NotificationsListScreen(parentCnic: _cnic)),
    );
  }

  // -------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final double top = MediaQuery.of(context).padding.top;
    const double overlap = 46;
    final double headerHeight = top + 176;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green header + white "Upcoming Vaccinations" card overlapping it
            Stack(
              children: [
                _buildHeader(context, headerHeight, top),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, headerHeight - overlap, 16, 0),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _childrenStream,
                    builder: (context, snap) => _UpcomingCard(
                      docs: snap.data?.docs ?? [],
                      loading: !snap.hasData,
                      onViewAll: () => widget.onNavigateToTab?.call(1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // 99 = open Health Education (handled by the navigation screen)
            _VideosSection(onViewAll: () => widget.onNavigateToTab?.call(99)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RecentNotificationsCard(
                cnic: _cnic,
                onViewAll: _openNotifications,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double height, double top) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4A2E), Color(0xFF0F5F3D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // faint shield watermark (as in the design)
          Positioned(
            right: 26,
            top: top + 62,
            child: Icon(Icons.shield_outlined,
                size: 84, color: Colors.white.withOpacity(0.07)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 18, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _nameFuture,
                        builder: (context, s) => Text(
                          'Hello, ${s.data ?? 'Parent'} 👋',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(
                        width: 230,
                        child: Text("Stay updated on your child's vaccinations.",
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14, height: 1.3)),
                      ),
                    ],
                  ),
                ),
                _BellButton(cnic: _cnic, onTap: _openNotifications),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Bell with unread badge
// =====================================================================
class _BellButton extends StatefulWidget {
  final String cnic;
  final VoidCallback onTap;
  const _BellButton({required this.cnic, required this.onTap});

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('parentCNIC', isEqualTo: widget.cnic)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        final unread = (snap.data?.docs ?? [])
            .where((d) => d.data()['isRead'] != true)
            .length;
        return IconButton(
          onPressed: widget.onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  color: Colors.white, size: 28),
              if (unread > 0)
                Positioned(
                  right: -4,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _C.primary, width: 1.2),
                    ),
                    child: Center(
                      child: Text(unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Campaign details bottom sheet (used by the popup "View Details").
void _showCampaignSheet(
  BuildContext context,
  _Campaign c,
  List<QueryDocumentSnapshot<Map<String, dynamic>>> children,
) {
  Widget row(IconData icon, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _C.accent),
            const SizedBox(width: 10),
            Text(k, style: const TextStyle(fontSize: 12, color: _C.grey)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _C.text)),
            ),
          ],
        ),
      );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                      color: _C.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(c.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                _Chip(
                  c.hasStarted ? 'Active' : 'Upcoming',
                  c.hasStarted ? _C.warning : _C.upcoming,
                  c.hasStarted ? _C.warningBg : _C.upcomingBg,
                ),
              ],
            ),
            const Divider(height: 26),
            row(Icons.water_drop_outlined, 'Vaccine', c.vaccineLabel),
            row(Icons.calendar_today_outlined, 'Dates', c.dates),
            row(Icons.location_on_outlined, 'Target Area', c.areaText),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _C.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                children.isEmpty
                    ? 'Your child is eligible for this campaign.'
                    : '${children.map((d) => _childName(d.data())).join(', ')} ${children.length == 1 ? 'is' : 'are'} eligible for this campaign. Please keep your ${children.length == 1 ? 'child' : 'children'} ready at home for the vaccinator visit.',
                style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _C.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// =====================================================================
// New-campaign popup dialog
// =====================================================================
class _CampaignPopup extends StatelessWidget {
  final _Campaign campaign;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> children;
  final VoidCallback onView;

  const _CampaignPopup({
    required this.campaign,
    required this.children,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final names = children.map((c) => _childName(c.data())).join(', ');

    Widget line(IconData icon, String text) => Row(
          children: [
            Icon(icon, size: 16, color: _C.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.text)),
            ),
          ],
        );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                color: _C.primary,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 10),
                    const Text('New Polio Campaign',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(campaign.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    line(Icons.calendar_today_outlined, campaign.dates),
                    const SizedBox(height: 8),
                    line(Icons.location_on_outlined,
                        '${campaign.areaText} (Target Area)'),
                    const SizedBox(height: 8),
                    line(Icons.water_drop_outlined, campaign.vaccineLabel),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _C.mint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        children.length == 1
                            ? '$names is eligible for this campaign. Please keep your child ready at home for the vaccinator visit.'
                            : '$names are eligible for this campaign. Please keep your children ready at home for the vaccinator visit.',
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: _C.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _C.primary),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Later',
                            style: TextStyle(
                                color: _C.primary, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onView,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _C.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Details',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Upcoming vaccinations card (white card overlapping the green header)
// Per child: nearest dose that is not given and not missed.
// =====================================================================
class _Due {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String vaccine;
  final DateTime due;
  final List<String> others; // other doses due in the same stage
  _Due(this.doc, this.vaccine, this.due, this.others);

  bool get isDueNow => !DateTime.now().isBefore(due);

  int get daysLeft {
    final t = DateTime.now();
    final a = DateTime(t.year, t.month, t.day);
    final b = DateTime(due.year, due.month, due.day);
    return b.difference(a).inDays;
  }

  bool get soon => !isDueNow && daysLeft <= 7;

  String get label => isDueNow
      ? 'Due Now'
      : soon
          ? 'Due in $daysLeft day${daysLeft == 1 ? '' : 's'}'
          : 'Upcoming';

  Color get color => isDueNow ? _C.warning : (soon ? _C.due : _C.upcoming);
  Color get bg => isDueNow ? _C.warningBg : (soon ? _C.dueBg : _C.upcomingBg);
}

class _IconSquare extends StatelessWidget {
  final IconData icon;
  const _IconSquare(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: _C.accent, width: 1.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 17, color: _C.accent),
      );
}

class _ViewAll extends StatelessWidget {
  final VoidCallback onTap;
  const _ViewAll(this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('View All',
                style: TextStyle(
                    color: _C.accent, fontWeight: FontWeight.bold, fontSize: 12)),
            Icon(Icons.chevron_right_rounded, color: _C.accent, size: 18),
          ],
        ),
      );
}

class _UpcomingCard extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final bool loading;
  final VoidCallback onViewAll;
  const _UpcomingCard({
    required this.docs,
    required this.loading,
    required this.onViewAll,
  });

  @override
  State<_UpcomingCard> createState() => _UpcomingCardState();
}

class _UpcomingCardState extends State<_UpcomingCard> {
  static const int _limit = 2;
  bool _expanded = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String _key = '';

  String _keyOf() => (widget.docs.map((d) => d.id).toList()..sort()).join(',');

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant _UpcomingCard old) {
    super.didUpdateWidget(old);
    if (_keyOf() != _key) _setup();
  }

  void _setup() {
    _key = _keyOf();
    final ids = widget.docs.map((d) => d.id).take(30).toList();
    _stream = ids.isEmpty
        ? null
        : FirebaseFirestore.instance
            .collection('vaccinations')
            .where('childId', whereIn: ids)
            .snapshots();
  }

  _Due? _nextFor(QueryDocumentSnapshot<Map<String, dynamic>> doc,
      List<Map<String, dynamic>> records) {
    final data = doc.data();
    final dob = _toDate(data['dob'] ?? data['dateOfBirth']) ?? DateTime.now();

    final given = <String>[];
    for (final r in records) {
      final st = (r['status'] ?? 'vaccinated').toString().toLowerCase().trim();
      if (const ['pending', 'missed', 'absent', 'due', 'duetoday', 'scheduled']
          .contains(st)) {
        continue;
      }
      final n =
          _norm((r['vaccineName'] ?? r['vaccine'] ?? r['title'] ?? '').toString());
      if (n.isNotEmpty) given.add(n);
    }

    final now = DateTime.now();
    final pending = <List<dynamic>>[]; // [vaccine, stage, dueDate]
    for (final stage in EpiScheduleHelper.generateEpiSchedule(dob)) {
      final due = stage['dueDate'] as DateTime;
      for (final v in List<String>.from(stage['vaccines'] as List)) {
        final t = _norm(v);
        final isGiven = given.any((g) => g == t || g.contains(t) || t.contains(g));
        if (isGiven) continue;
        if (now.isAfter(due.add(const Duration(days: 14)))) continue; // missed
        pending.add([v, stage['stage'].toString(), due]);
      }
    }
    if (pending.isEmpty) return null;
    pending.sort((a, b) => (a[2] as DateTime).compareTo(b[2] as DateTime));
    final first = pending.first;
    final others = pending
        .skip(1)
        .where((p) => p[1] == first[1])
        .map((p) => _pretty(p[0] as String))
        .toList();
    return _Due(doc, _pretty(first[0] as String), first[2] as DateTime, others);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconSquare(Icons.calendar_month_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Upcoming Vaccinations',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _C.text)),
              ),
              _ViewAll(widget.onViewAll),
            ],
          ),
          const SizedBox(height: 10),
          _body(context),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (widget.loading) return const _Loader();
    if (widget.docs.isEmpty || _stream == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text('No children registered yet.',
              style: TextStyle(color: _C.grey, fontWeight: FontWeight.w500)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
                child: Text('Could not load vaccination records.',
                    style: TextStyle(color: _C.grey))),
          );
        }
        if (!snap.hasData) return const _Loader();

        final byChild = <String, List<Map<String, dynamic>>>{};
        for (final d in snap.data!.docs) {
          final m = d.data();
          byChild.putIfAbsent((m['childId'] ?? '').toString(), () => []).add(m);
        }

        final items = <_Due>[];
        for (final d in widget.docs) {
          final n = _nextFor(d, byChild[d.id] ?? []);
          if (n != null) items.add(n);
        }
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text('No upcoming vaccinations due.',
                  style: TextStyle(color: _C.grey, fontWeight: FontWeight.w500)),
            ),
          );
        }
        items.sort((a, b) => a.due.compareTo(b.due));

        final visible = _expanded ? items : items.take(_limit).toList();
        final hiddenChildren = items.length > _limit ? items.length - _limit : 0;
        final extra =
            hiddenChildren + items.fold<int>(0, (s, i) => s + i.others.length);
        final showToggle = extra > 0 || _expanded;

        return Column(
          children: [
            for (int i = 0; i < visible.length; i++) ...[
              _tile(context, visible[i]),
              if (i != visible.length - 1)
                const Divider(height: 1, color: _C.border),
            ],
            if (showToggle) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  decoration: BoxDecoration(
                    color: _C.mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          color: _C.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _expanded ? 'Show less' : '+$extra more vaccine due',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _C.accent),
                        ),
                      ),
                      Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _C.accent),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _tile(BuildContext context, _Due it) {
    final data = it.doc.data();
    final name = _childName(data);
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChildDetailScreen(
            childId: it.doc.id,
            childName: name,
            childAge: _ageText(data['dob'] ?? data['dateOfBirth']),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: _C.mint,
              child: Text(_isMale(data) ? '👦' : '👧',
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _C.text)),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: _C.mint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB9DFC9)),
                    ),
                    child: Text(it.vaccine,
                        style: const TextStyle(
                            fontSize: 10,
                            color: _C.accent,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: _C.grey),
                      const SizedBox(width: 5),
                      Text('Due on ${_fmt(it.due)}',
                          style: const TextStyle(fontSize: 11, color: _C.grey)),
                    ],
                  ),
                  if (_expanded && it.others.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Also due: ${it.others.join(', ')}',
                        style: const TextStyle(
                            fontSize: 10, color: _C.accent, height: 1.3)),
                  ],
                ],
              ),
            ),
            _Chip(it.label, it.color, it.bg),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, color: _C.grey, size: 22),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Health education videos (2 cards per page + page dots)
// =====================================================================
class _VideosSection extends StatefulWidget {
  final VoidCallback onViewAll;
  const _VideosSection({required this.onViewAll});

  @override
  State<_VideosSection> createState() => _VideosSectionState();
}

class _VideosSectionState extends State<_VideosSection> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final ScrollController _sc = ScrollController();
  double _step = 1;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _stream =
        FirebaseFirestore.instance.collection('education_videos').snapshots();
    _sc.addListener(() {
      final p = (_sc.offset / _step).round();
      if (p != _page && mounted) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cw = (MediaQuery.of(context).size.width - 44) / 2;
    _step = (cw + 12) * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _IconSquare(Icons.play_arrow_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Health Education Videos',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _C.text)),
              ),
              _ViewAll(widget.onViewAll),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snap) {
            if (!snap.hasData) return const _Loader();
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _EmptyCard('No health videos uploaded yet.'),
              );
            }
            final pages = (docs.length / 2).ceil();
            return Column(
              children: [
                SizedBox(
                  height: 184,
                  child: ListView.builder(
                    controller: _sc,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) =>
                        _videoCard(context, _Video.fromMap(docs[i].data()), cw),
                  ),
                ),
                if (pages > 1) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages, (i) {
                      final on = i == _page.clamp(0, pages - 1);
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? _C.accent : const Color(0xFFCBD5D0),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _videoCard(BuildContext context, _Video v, double w) {
    final badge = v.duration.contains(':');
    return GestureDetector(
      onTap: () => _playVideo(context, v),
      child: Container(
        width: w,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 96,
                  decoration: BoxDecoration(
                    color: _C.mint,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    image: v.thumb.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(v.thumb), fit: BoxFit.cover)
                        : null,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: _C.primary, size: 26),
                    ),
                  ),
                ),
                if (badge)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(v.duration,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Text(v.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      height: 1.25,
                      color: _C.text)),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 6, 8),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 11, color: _C.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(v.duration,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: _C.grey)),
                  ),
                  const Icon(Icons.more_vert, size: 16, color: _C.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// Recent notifications card (latest 3)
// =====================================================================
class _RecentNotificationsCard extends StatefulWidget {
  final String cnic;
  final VoidCallback onViewAll;
  const _RecentNotificationsCard({required this.cnic, required this.onViewAll});

  @override
  State<_RecentNotificationsCard> createState() =>
      _RecentNotificationsCardState();
}

class _RecentNotificationsCardState extends State<_RecentNotificationsCard> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('parentCNIC', isEqualTo: widget.cnic)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconSquare(Icons.notifications_none_rounded),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Recent Notifications',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _C.text)),
              ),
              _ViewAll(widget.onViewAll),
            ],
          ),
          const SizedBox(height: 6),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snap) {
              if (!snap.hasData) return const _Loader();
              final list = snap.data!.docs.map((d) => d.data()).toList()
                ..sort((a, b) {
                  final x = _notifDate(a);
                  final y = _notifDate(b);
                  if (x == null || y == null) return 0;
                  return y.compareTo(x);
                });
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text('No recent notifications.',
                        style: TextStyle(
                            color: _C.grey, fontWeight: FontWeight.w500)),
                  ),
                );
              }
              final top = list.take(3).toList();
              return Column(
                children: [
                  for (int i = 0; i < top.length; i++) ...[
                    _row(top[i]),
                    if (i != top.length - 1)
                      const Divider(height: 1, color: _C.border),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> n) {
    final cat = _notifCategory(n);
    late IconData icon;
    late Color c;
    late Color bg;
    if (cat == 'Campaign') {
      icon = Icons.campaign_rounded;
      c = _C.warning;
      bg = _C.warningBg;
    } else if (cat == 'Education') {
      icon = Icons.play_circle_outline_rounded;
      c = _C.accent;
      bg = _C.mint;
    } else {
      icon = Icons.medical_services_outlined;
      c = _C.upcoming;
      bg = _C.upcomingBg;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: bg,
            child: Icon(icon, color: c, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text((n['message'] ?? n['title'] ?? '').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: _C.text, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(_timeAgo(n),
              style: const TextStyle(fontSize: 10, color: _C.grey)),
        ],
      ),
    );
  }
}

// =====================================================================
// In-app YouTube dialog
// =====================================================================
class _InAppVideoDialog extends StatefulWidget {
  final String videoId;
  final String title;
  const _InAppVideoDialog({required this.videoId, required this.title});

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
            title: Text(widget.title,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
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
              child: YoutubePlayer(controller: _controller),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Kept for compatibility: standalone screens that used to live in this
// file (same class names, restyled to the green theme)
// =====================================================================
class EducationVideosScreen extends StatelessWidget {
  const EducationVideosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Health Education Videos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection('education_videos').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const _Loader();
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No health education videos available.',
                    style: TextStyle(color: _C.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final v = _Video.fromMap(docs[i].data());
              return GestureDetector(
                onTap: () => _playVideo(context, v),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _C.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: _C.mint,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          image: v.thumb.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(v.thumb),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: const Center(
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.play_arrow,
                                color: Colors.white, size: 30),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            if (v.duration.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(v.duration,
                                  style: const TextStyle(
                                      fontSize: 12, color: _C.grey)),
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

class NotificationsListScreen extends StatelessWidget {
  final String parentCnic;
  const NotificationsListScreen({Key? key, required this.parentCnic})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('parentCNIC', isEqualTo: _cleanCnic(parentCnic))
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const _Loader();
          final list = snap.data!.docs.map((d) => d.data()).toList()
            ..sort((a, b) {
              final x = _notifDate(a);
              final y = _notifDate(b);
              if (x == null || y == null) return 0;
              return y.compareTo(x);
            });
          if (list.isEmpty) {
            return const Center(
                child: Text('No notifications found.',
                    style: TextStyle(color: _C.grey)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = list[i];
              final cat = _notifCategory(n);
              final icon = cat == 'Campaign'
                  ? Icons.campaign_rounded
                  : cat == 'Education'
                      ? Icons.menu_book_rounded
                      : Icons.medical_services_outlined;
              return _Card(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _C.mint,
                      child: Icon(icon, color: _C.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((n['title'] ?? 'Alert').toString(),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text((n['message'] ?? '').toString(),
                              style: const TextStyle(
                                  fontSize: 12, color: _C.grey, height: 1.3)),
                          const SizedBox(height: 6),
                          Text(_timeAgo(n),
                              style: const TextStyle(
                                  fontSize: 10, color: _C.grey)),
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
} */