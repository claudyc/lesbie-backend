import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BlockReportScreen extends StatefulWidget {
  final Map<String, dynamic> reportedUser;

  const BlockReportScreen({
    super.key,
    required this.reportedUser,
  });

  @override
  State<BlockReportScreen> createState() => _BlockReportScreenState();
}

class _BlockReportScreenState extends State<BlockReportScreen> {
  String? _selectedReason;
  bool _isLoading = false;

  final List<Map<String, String>> _reasons = [
    {'key': 'fake', 'label': 'Fo pwofil / Fake account'},
    {'key': 'harassment', 'label': 'Abizan / Harassment'},
    {'key': 'spam', 'label': 'Spam'},
    {'key': 'inappropriate', 'label': 'Foto/Mesaj endesan'},
    {'key': 'underage', 'label': 'Moun mwens pase 18 an'},
    {'key': 'other', 'label': 'Lòt rezon'},
  ];

  Future<void> _blockUser() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance
          .collection('blocks')
          .doc('${currentUser.uid}_${widget.reportedUser['uid']}')
          .set({
        'blockedBy': currentUser.uid,
        'blockedUid': widget.reportedUser['uid'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSuccess('Itilizatè bloke ✅');
        Navigator.pop(context, 'blocked');
      }
    } catch (e) {
      _showError('Erè — eseye ankò');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reportUser() async {
    if (_selectedReason == null) {
      _showError('Chwazi yon rezon anvan!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
          .collection('reports')
          .add({
        'reportedBy': currentUser.uid,
        'reportedUid': widget.reportedUser['uid'],
        'reportedName': widget.reportedUser['name'],
        'reason': _selectedReason,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      await FirebaseFirestore.instance
          .collection('blocks')
          .doc('${currentUser.uid}_${widget.reportedUser['uid']}')
          .set({
        'blockedBy': currentUser.uid,
        'blockedUid': widget.reportedUser['uid'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccess('Rapò voye epi itilizatè bloke ✅');
        Navigator.pop(context, 'reported');
      }
    } catch (e) {
      _showError('Erè — eseye ankò');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D1B4E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D1B4E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bloke / Rapò',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pwofil moun nan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4537E),
                      image: widget.reportedUser['photoUrl'] != null
                          ? DecorationImage(
                        image: NetworkImage(
                          widget.reportedUser['photoUrl'],
                        ),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: widget.reportedUser['photoUrl'] == null
                        ? Center(
                      child: Text(
                        widget.reportedUser['name'] != null
                            ? widget.reportedUser['name'][0]
                            .toUpperCase()
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reportedUser['name'] ?? 'Anonim',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.reportedUser['city'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Bloke sèlman
            const Text(
              'Bloke itilizatè',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Li pa pral wè pwofil ou ankò epi ou pa pral wè pa li.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _blockUser,
                icon: const Icon(Icons.block, color: Colors.orange),
                label: const Text(
                  'Bloke sèlman',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Rapò
            const Text(
              'Rapò itilizatè',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chwazi rezon rapò a — nou pral revize li.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // Rezon yo
            ...(_reasons.map((reason) {
              final isSelected = _selectedReason == reason['key'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedReason = reason['key']),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.red.withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.red
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                        isSelected ? Colors.red : Colors.white38,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        reason['label']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.8),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()),

            const SizedBox(height: 16),

            // Bouton rapò
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _reportUser,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.flag, color: Colors.white),
                label: const Text(
                  'Rapò epi Bloke',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}