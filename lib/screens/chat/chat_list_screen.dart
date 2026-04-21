import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('users', arrayContains: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD4537E)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💬', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text(
                  'Pa gen match ankò',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kontinye swipe pou jwenn match!',
                  style: TextStyle(
                    color: Color(0xFFED93B1),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final match = snapshot.data!.docs[index];
            final matchData = match.data() as Map<String, dynamic>;
            final users = List<String>.from(matchData['users']);
            final otherUid =
            users.firstWhere((uid) => uid != currentUser.uid);

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final userData =
                userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) return const SizedBox();

                return _buildChatItem(
                  context,
                  matchId: match.id,
                  userData: userData,
                  otherUid: otherUid,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatItem(
      BuildContext context, {
        required String matchId,
        required Map<String, dynamic> userData,
        required String otherUid,
      }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              matchId: matchId,
              otherUser: userData,
              otherUid: otherUid,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4537E),
                image: userData['photoUrl'] != null
                    ? DecorationImage(
                  image: NetworkImage(userData['photoUrl']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: userData['photoUrl'] == null
                  ? Center(
                child: Text(
                  userData['name'] != null
                      ? userData['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 14),
            // Enfòmasyon
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? 'Anonim',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData['city'] != null
                        ? '📍 ${userData['city']}'
                        : 'Klike pou kòmanse pale',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFD4537E),
            ),
          ],
        ),
      ),
    );
  }
}