import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static String buildMatchId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bg,
        body: Center(
          child: Text('Pa konekte', style: TextStyle(color: AppTheme.gray)),
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
                    'Messages',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.pink.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.gray,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // ✅ Nou kenbe "users" pou ansyen chats/discover ki te sove konsa.
                stream: FirebaseFirestore.instance
                    .collection('matches')
                    .where('users', arrayContains: currentUser.uid)
                    .snapshots(),
                builder: (context, usersSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    // ✅ Nou ajoute "participants" pou nouvo chats yo.
                    stream: FirebaseFirestore.instance
                        .collection('matches')
                        .where('participants', arrayContains: currentUser.uid)
                        .snapshots(),
                    builder: (context, participantsSnap) {
                      final waiting =
                          usersSnap.connectionState == ConnectionState.waiting &&
                              participantsSnap.connectionState == ConnectionState.waiting &&
                              !usersSnap.hasData &&
                              !participantsSnap.hasData;

                      if (waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: AppTheme.pink),
                        );
                      }

                      if (usersSnap.hasError || participantsSnap.hasError) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, color: AppTheme.gray, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Erè koneksyon',
                                style: TextStyle(color: AppTheme.gray),
                              ),
                            ],
                          ),
                        );
                      }

                      // ✅ Combine 2 query yo pou pa gen chat ki pèdi.
                      final map = <String, QueryDocumentSnapshot>{};

                      for (final d in usersSnap.data?.docs ?? []) {
                        map[d.id] = d;
                      }
                      for (final d in participantsSnap.data?.docs ?? []) {
                        map[d.id] = d;
                      }

                      final matches = map.values.toList();

                      if (matches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppTheme.gray2,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: AppTheme.gray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Connect with someone to\nstart chatting!',
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

                      matches.sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['lastMessageAt'] as Timestamp?;
                        final bTime = bData['lastMessageAt'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final doc = matches[index];
                          final match = doc.data() as Map<String, dynamic>;

                          // ✅ Li sipòte toude: participants ak users.
                          final users = List<String>.from(
                            match['participants'] ?? match['users'] ?? [],
                          );

                          final otherUid = users.firstWhere(
                                (uid) => uid != currentUser.uid,
                            orElse: () => '',
                          );

                          if (otherUid.isEmpty) return const SizedBox();

                          final lastMessage = (match['lastMessage'] ?? '').toString();
                          final lastMessageAt = match['lastMessageAt'] as Timestamp?;
                          final unreadCount = match['unread_${currentUser.uid}'] ?? 0;

                          // ✅ Sa fè matchId toujou menm jan ak ChatScreen.
                          final safeMatchId = buildMatchId(currentUser.uid, otherUid);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(otherUid)
                                .get(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData) return const SizedBox();

                              final userData =
                              userSnap.data!.data() as Map<String, dynamic>?;

                              final name =
                                  userData?['username'] ?? userData?['name'] ?? 'User';
                              final photoUrl = userData?['photoUrl'];
                              final lastSeen = userData?['lastSeen'] as Timestamp?;
                              final isOnline = lastSeen != null &&
                                  DateTime.now()
                                      .difference(lastSeen.toDate())
                                      .inMinutes <
                                      5;

                              return GestureDetector(
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection('matches')
                                      .doc(safeMatchId)
                                      .set({
                                    'users': [currentUser.uid, otherUid],
                                    'participants': [currentUser.uid, otherUid],
                                    'unread_${currentUser.uid}': 0,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  }, SetOptions(merge: true));

                                  if (!context.mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        matchId: safeMatchId,
                                        otherUserName: name,
                                        otherUserPhoto: photoUrl,
                                        otherUserId: otherUid,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.card,
                                    borderRadius:
                                    BorderRadius.circular(AppTheme.radius),
                                    border: Border.all(
                                      color: unreadCount > 0
                                          ? AppTheme.pink.withValues(alpha: 0.3)
                                          : AppTheme.pink.withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: AppTheme.pinkGrad,
                                              image: photoUrl != null
                                                  ? DecorationImage(
                                                image: NetworkImage(photoUrl),
                                                fit: BoxFit.cover,
                                              )
                                                  : null,
                                            ),
                                            child: photoUrl == null
                                                ? Center(
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: AppTheme.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            )
                                                : null,
                                          ),
                                          if (isOnline)
                                            Positioned(
                                              bottom: 1,
                                              right: 1,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.green,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppTheme.card,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    name,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: AppTheme.white,
                                                      fontWeight: unreadCount > 0
                                                          ? FontWeight.w700
                                                          : FontWeight.w600,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                if (lastMessageAt != null)
                                                  Text(
                                                    _timeAgo(
                                                        lastMessageAt.toDate()),
                                                    style: const TextStyle(
                                                      color: AppTheme.gray2,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),

                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    lastMessage.isEmpty
                                                        ? 'Tap to chat 💬'
                                                        : lastMessage,
                                                    style: TextStyle(
                                                      color: unreadCount > 0
                                                          ? AppTheme.white
                                                          : AppTheme.gray2,
                                                      fontSize: 12,
                                                      fontWeight: unreadCount > 0
                                                          ? FontWeight.w500
                                                          : FontWeight.normal,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ),
                                                if (unreadCount > 0)
                                                  Container(
                                                    margin:
                                                    const EdgeInsets.only(left: 6),
                                                    width: 20,
                                                    height: 20,
                                                    decoration:
                                                    const BoxDecoration(
                                                      color: AppTheme.pink,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        unreadCount > 9
                                                            ? '9+'
                                                            : '$unreadCount',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                          FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppTheme.gray2,
                                        size: 14,
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _lastSeenText(Timestamp? ts) {
    if (ts == null) return 'last seen recently';

    final date = ts.toDate();
    final now = DateTime.now();

    final time =
        '${_hour12(date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;

    if (isToday) return 'last seen today at $time';
    if (isYesterday) return 'last seen yesterday at $time';

    return 'last seen ${date.month}/${date.day}/${date.year} at $time';
  }

  static int _hour12(int hour) {
    if (hour == 0) return 12;
    if (hour > 12) return hour - 12;
    return hour;
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}
