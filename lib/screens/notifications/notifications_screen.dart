import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../chat/chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text(
            'Please sign in',
            style: TextStyle(color: AppTheme.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final batch = FirebaseFirestore.instance.batch();

                      final docs = await FirebaseFirestore.instance
                          .collection('notifications')
                          .where('toUid', isEqualTo: currentUser.uid)
                          .where('read', isEqualTo: false)
                          .get();

                      for (final doc in docs.docs) {
                        batch.update(doc.reference, {'read': true});
                      }

                      await batch.commit();
                    },
                    child: const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: AppTheme.pinkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('toUid', isEqualTo: currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.pink,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading notifications:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  final notifications = snapshot.data?.docs ?? [];

                  notifications.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final aTime =
                        (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                            0;
                    final bTime =
                        (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                            0;

                    return bTime.compareTo(aTime);
                  });

                  if (notifications.isEmpty) {
                    return _emptyNotifications();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final doc = notifications[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final isRead = data['read'] == true;
                      final type = data['type']?.toString() ?? 'like';
                      final fromUid = data['fromUid']?.toString() ?? '';
                      final fromName =
                      data['fromName']?.toString().trim().isNotEmpty == true
                          ? data['fromName'].toString()
                          : 'Someone';
                      final fromPhoto = data['fromPhoto'];
                      final createdAt = data['createdAt'] as Timestamp?;

                      return GestureDetector(
                        onTap: () async {
                          await doc.reference.update({'read': true});

                          if (fromUid.isEmpty) return;

                          if (type == 'message' || type == 'connection') {
                            await _openChat(
                              context: context,
                              currentUid: currentUser.uid,
                              otherUid: fromUid,
                              fallbackName: fromName,
                              fallbackPhoto: fromPhoto?.toString(),
                            );
                            return;
                          }

                          if (type == 'like') {
                            await _showUserProfile(
                              context: context,
                              otherUid: fromUid,
                            );
                            return;
                          }

                          if (type == 'story_react') {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Story reaction opened'),
                                  backgroundColor: AppTheme.pink,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: _buildNotificationTile(
                          isRead: isRead,
                          type: type,
                          fromName: fromName,
                          fromPhoto: fromPhoto?.toString(),
                          createdAt: createdAt,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildNotificationTile({
    required bool isRead,
    required String type,
    required String fromName,
    required String? fromPhoto,
    required Timestamp? createdAt,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? AppTheme.card : AppTheme.pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
          color: isRead
              ? AppTheme.pink.withValues(alpha: 0.08)
              : AppTheme.pink.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.pinkGrad,
              image: fromPhoto != null && fromPhoto.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(fromPhoto),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: fromPhoto == null || fromPhoto.isEmpty
                ? Center(
              child: Text(
                fromName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: fromName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: _getNotifText(type),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  createdAt != null ? _timeAgo(createdAt.toDate()) : 'Just now',
                  style: const TextStyle(
                    color: AppTheme.gray2,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getNotifColor(type).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getNotifEmoji(type),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (!isRead) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.pink,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _openChat({
    required BuildContext context,
    required String currentUid,
    required String otherUid,
    required String fallbackName,
    String? fallbackPhoto,
  }) async {
    final matchId = currentUid.compareTo(otherUid) < 0
        ? '${currentUid}_$otherUid'
        : '${otherUid}_$currentUid';

    final userDoc =
    await FirebaseFirestore.instance.collection('users').doc(otherUid).get();

    final userData = userDoc.data() ?? {};

    final otherName =
    userData['username']?.toString().trim().isNotEmpty == true
        ? userData['username'].toString()
        : userData['name']?.toString().trim().isNotEmpty == true
        ? userData['name'].toString()
        : fallbackName;

    final otherPhoto = userData['photoUrl']?.toString() ?? fallbackPhoto;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          matchId: matchId,
          otherUserName: otherName,
          otherUserPhoto: otherPhoto,
          otherUserId: otherUid,
        ),
      ),
    );
  }

  static Future<void> _showUserProfile({
    required BuildContext context,
    required String otherUid,
  }) async {
    final doc =
    await FirebaseFirestore.instance.collection('users').doc(otherUid).get();

    if (!context.mounted) return;

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User profile not found'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final data = doc.data() ?? {};
    final name = data['username'] ??
        data['name']?.toString().split(' ').first ??
        'User';
    final city = data['city'] ?? '';
    final country = data['country'] ?? '';
    final photoUrl = data['photoUrl'];
    final isVerified = data['isVerified'] == true;
    final bio = data['bio'] ?? '';
    final lookingFor = data['lookingFor'] ?? '';
    final interests = List<String>.from(data['interests'] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.pinkGrad,
                    boxShadow: AppTheme.pinkShadow,
                    image: photoUrl != null
                        ? DecorationImage(
                      image: NetworkImage(photoUrl.toString()),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: photoUrl == null
                      ? Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.white,
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.pink,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                if (city.toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 $city${country.toString().isNotEmpty ? ', $country' : ''}',
                    style: const TextStyle(
                      color: AppTheme.gray,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (bio.toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    bio.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.gray,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
                if (lookingFor.toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Looking for: $lookingFor',
                      style: const TextStyle(
                        color: AppTheme.pinkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Interests',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.card2,
                          borderRadius:
                          BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(
                            color: AppTheme.pink.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: AppTheme.gray,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _emptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppTheme.gray2,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: AppTheme.gray,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'Likes and connections\nwill appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.gray2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  static String _getNotifText(String type) {
    switch (type) {
      case 'like':
        return ' liked your profile ❤️';
      case 'connection':
        return ' connected with you! 🎉';
      case 'message':
        return ' sent you a message 💬';
      case 'story_react':
        return ' reacted to your story ✨';
      default:
        return ' interacted with you';
    }
  }

  static String _getNotifEmoji(String type) {
    switch (type) {
      case 'like':
        return '❤️';
      case 'connection':
        return '🎉';
      case 'message':
        return '💬';
      case 'story_react':
        return '✨';
      default:
        return '🔔';
    }
  }

  static Color _getNotifColor(String type) {
    switch (type) {
      case 'like':
        return AppTheme.pink;
      case 'connection':
        return AppTheme.green;
      case 'message':
        return AppTheme.gold;
      case 'story_react':
        return AppTheme.pinkSoft;
      default:
        return AppTheme.pink;
    }
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}