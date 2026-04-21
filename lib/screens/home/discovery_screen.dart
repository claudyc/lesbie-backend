import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import 'block_report_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  final Map<String, dynamic> filters;

  const DiscoveryScreen({
    super.key,
    this.filters = const {},
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<Map<String, dynamic>> _profiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(covariant DiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      setState(() {
        _profiles = [];
        _currentIndex = 0;
        _isLoading = true;
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
      _loadProfiles();
    }
  }

  Future<void> _loadProfiles() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final blocksSnap = await FirebaseFirestore.instance
          .collection('blocks')
          .where('blockedBy', isEqualTo: currentUser.uid)
          .get();

      final blockedUids = blocksSnap.docs
          .map((doc) => doc.data()['blockedUid'] as String)
          .toSet();

      final likesSnap = await FirebaseFirestore.instance
          .collection('likes')
          .where('fromUid', isEqualTo: currentUser.uid)
          .get();

      final likedUids = likesSnap.docs
          .map((doc) => doc.data()['toUid'] as String)
          .toSet();

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('onboardingComplete', isEqualTo: true)
          .limit(50)
          .get();

      List<Map<String, dynamic>> profiles = snapshot.docs
          .map((doc) => doc.data())
          .where(
            (data) =>
        data['uid'] != currentUser.uid &&
            !blockedUids.contains(data['uid']) &&
            !likedUids.contains(data['uid']),
      )
          .toList();

      final identities =
          widget.filters['identities'] as List<String>? ?? const [];
      if (identities.isNotEmpty) {
        profiles = profiles
            .where((p) => identities.contains(p['identity']))
            .toList();
      }

      final ageMin = widget.filters['ageMin'] as double? ?? 18;
      final ageMax = widget.filters['ageMax'] as double? ?? 60;

      profiles = profiles.where((profile) {
        if (profile['birthDate'] == null) return true;

        try {
          final birthDate = DateTime.parse(profile['birthDate']);
          final age = DateTime.now().difference(birthDate).inDays ~/ 365;
          return age >= ageMin && age <= ageMax;
        } catch (_) {
          return true;
        }
      }).toList();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _currentIndex = 0;
        _isLoading = false;
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSwipeRight() async {
    if (_currentIndex >= _profiles.length) return;

    final profile = _profiles[_currentIndex];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('likes')
          .doc('${currentUser.uid}_${profile['uid']}')
          .set({
        'fromUid': currentUser.uid,
        'toUid': profile['uid'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final reverseCheck = await FirebaseFirestore.instance
          .collection('likes')
          .doc('${profile['uid']}_${currentUser.uid}')
          .get();

      if (reverseCheck.exists) {
        await FirebaseFirestore.instance.collection('matches').add({
          'users': [currentUser.uid, profile['uid']],
          'createdAt': FieldValue.serverTimestamp(),
        });

        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final currentUserName = currentUserDoc.data()?['name'] ?? 'Yon moun';

        await NotificationService.sendMatchNotification(
          toUid: profile['uid'],
          fromName: currentUserName,
        );

        if (mounted) {
          _showMatchDialog(profile);
        }
      }

      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _isDragging = false;
      });

      if (_currentIndex >= _profiles.length - 2) {
        _loadProfiles();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _onSwipeLeft() {
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _isDragging = false;
    });

    if (_currentIndex >= _profiles.length - 2) {
      _loadProfiles();
    }
  }

  void _showMatchDialog(Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF2D1B4E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 50)),
              const SizedBox(height: 16),
              const Text(
                'SE YON MATCH!',
                style: TextStyle(
                  color: Color(0xFFD4537E),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ou ak ${profile['name'] ?? 'itilizatè a'} renmen youn lòt!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4537E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Voye yon mesaj 💬',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Kontinye eksplore',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBlockOrReport(Map<String, dynamic> profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockReportScreen(
          reportedUser: profile,
        ),
      ),
    );

    if (result == 'blocked' || result == 'reported') {
      setState(() {
        if (_currentIndex < _profiles.length) {
          _profiles.removeAt(_currentIndex);
        }

        if (_currentIndex >= _profiles.length && _profiles.isNotEmpty) {
          _currentIndex = _profiles.length - 1;
        }

        if (_profiles.isEmpty) {
          _currentIndex = 0;
          _isLoading = true;
        }
      });

      if (_profiles.isEmpty) {
        _loadProfiles();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD4537E),
        ),
      );
    }

    if (_profiles.isEmpty || _currentIndex >= _profiles.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'Pa gen plis pwofil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tounen pita pou wè plis!',
              style: TextStyle(
                color: Color(0xFFED93B1),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _isLoading = true;
                  _profiles = [];
                });
                _loadProfiles();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4537E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Rafraîchi 🔄',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    final profile = _profiles[_currentIndex];

    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onPanStart: (_) => setState(() => _isDragging = true),
            onPanUpdate: (details) {
              setState(() => _dragOffset += details.delta);
            },
            onPanEnd: (_) {
              if (_dragOffset.dx > 100) {
                _onSwipeRight();
              } else if (_dragOffset.dx < -100) {
                _onSwipeLeft();
              } else {
                setState(() {
                  _dragOffset = Offset.zero;
                  _isDragging = false;
                });
              }
            },
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.rotate(
                angle: _dragOffset.dx * 0.001,
                child: _buildProfileCard(profile),
              ),
            ),
          ),
        ),

        if (_isDragging && _dragOffset.dx.abs() > 30)
          Positioned(
            top: 80,
            left: _dragOffset.dx > 0 ? 40 : null,
            right: _dragOffset.dx < 0 ? 40 : null,
            child: Transform.rotate(
              angle: _dragOffset.dx > 0 ? -0.3 : 0.3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _dragOffset.dx > 0 ? Colors.green : Colors.red,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _dragOffset.dx > 0 ? 'LIKE ♥' : 'NOPE ✕',
                  style: TextStyle(
                    color: _dragOffset.dx > 0 ? Colors.green : Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _onSwipeLeft,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: _onSwipeRight,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4537E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4537E).withOpacity(0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.88,
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D2560), Color(0xFF2D1B4E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4537E), Color(0xFF7F77DD)],
                ),
                image: profile['photoUrl'] != null
                    ? DecorationImage(
                  image: NetworkImage(profile['photoUrl']),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: profile['photoUrl'] == null
                  ? Center(
                child: Text(
                  profile['name'] != null
                      ? profile['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 80,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  : null,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile['name'] ?? 'Anonim',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (profile['birthDate'] != null)
                        Text(
                          '${_calculateAge(profile['birthDate'])} an',
                          style: const TextStyle(
                            color: Color(0xFFED93B1),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFED93B1),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          profile['city'] != null && profile['country'] != null
                              ? '${profile['city']}, ${profile['country']}'
                              : 'Lokasyon enkoni',
                          style: const TextStyle(
                            color: Color(0xFFED93B1),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (profile['identity'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F77DD).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile['identity'],
                            style: const TextStyle(
                              color: Color(0xFFEEEDFE),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _handleBlockOrReport(profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                color: Colors.white54,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Rapò',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();

      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 0;
    }
  }
}