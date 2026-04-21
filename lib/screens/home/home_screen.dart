import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'discovery_screen.dart';
import 'filter_screen.dart';
import '../auth/login_screen.dart';
import '../chat/chat_list_screen.dart';
import '../matching/match_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userData;
  Map<String, dynamic> _filters = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted && doc.exists) {
      setState(() => _userData = doc.data());
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        _userData?['name']?.toString().split(' ').first ?? '';

    final List<Widget> screens = [
      DiscoveryScreen(filters: _filters),
      const ChatListScreen(),
      const MatchScreen(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        elevation: 0,
        title: _currentIndex == 0
            ? Row(
          children: [
            const Text('🌸 ', style: TextStyle(fontSize: 20)),
            Text(
              firstName.isNotEmpty
                  ? 'Bonjou, $firstName!'
                  : 'Lesbie Chat',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        )
            : Text(
          ['Dekouvri', 'Chat', 'Match',
            'Pwofil'][_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.tune, color: Colors.white),
                  if (_filters.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4537E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () async {
                final filters = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FilterScreen(
                      currentFilters: _filters,
                    ),
                  ),
                );
                if (filters != null) {
                  setState(() => _filters = filters);
                }
              },
            ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser != null
            ? FirebaseFirestore.instance
            .collection('notifications')
            .where(
          'toUid',
          isEqualTo:
          FirebaseAuth.instance.currentUser!.uid,
        )
            .where('read', isEqualTo: false)
            .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data?.docs.length ?? 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              if (index == 1) {
                NotificationService.markAllAsRead(
                  FirebaseAuth.instance.currentUser!.uid,
                );
              }
            },
            backgroundColor: const Color(0xFF1A0F30),
            selectedItemColor: const Color(0xFFD4537E),
            unselectedItemColor: Colors.white38,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Dekouvri',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD4537E),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9
                                ? '9+'
                                : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: const Icon(Icons.chat_bubble),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.star_outline),
                activeIcon: Icon(Icons.star),
                label: 'Match',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Pwofil',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFD4537E),
              border: Border.all(
                color: const Color(0xFF7F77DD),
                width: 3,
              ),
              image: _userData?['photoUrl'] != null
                  ? DecorationImage(
                image: NetworkImage(_userData!['photoUrl']),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _userData?['photoUrl'] == null
                ? Center(
              child: Text(
                _userData?['name'] != null
                    ? _userData!['name'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userData?['name'] ?? 'Itilizatè',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData?['city'] != null &&
                _userData?['country'] != null
                ? '📍 ${_userData!['city']}, ${_userData!['state'] ?? ''}, ${_userData!['country']}'
                : '📍 Lokasyon enkoni',
            style: const TextStyle(
              color: Color(0xFFED93B1),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          if (_userData?['identity'] != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF7F77DD).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userData!['identity'],
                style: const TextStyle(
                  color: Color(0xFFEEEDFE),
                  fontSize: 13,
                ),
              ),
            ),
          if (_userData?['bio'] != null &&
              _userData!['bio'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _userData!['bio'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (_userData == null) return;
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      userData: _userData!,
                    ),
                  ),
                );
                if (updated == true) {
                  _loadUserData();
                }
              },
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Modifye pwofil',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7F77DD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Dekonekte',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow('Idantite', _userData?['identity'] ?? '—'),
          _buildInfoRow('Chache', _userData?['lookingFor'] ?? '—'),
          _buildInfoRow('Vil', _userData?['city'] ?? '—'),
          _buildInfoRow(
              'Depatman/State', _userData?['state'] ?? '—'),
          _buildInfoRow('Peyi', _userData?['country'] ?? '—'),
          _buildInfoRow(
              'Relasyon', _userData?['relationshipGoal'] ?? '—'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}