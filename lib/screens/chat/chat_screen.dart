import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import '../../core/theme.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {

  final _messageController = TextEditingController();
  final _scrollController  = ScrollController();
  final _currentUser       = FirebaseAuth.instance.currentUser;
  final _picker            = ImagePicker();
  final _recorder          = AudioRecorder();
  final _audioPlayer       = AudioPlayer();

  bool    _hasText        = false;
  bool    _isSendingPhoto = false;
  bool    _isSendingVoice = false;
  String? _playingUrl;
  Map<String, dynamic>? _otherUserData;
  bool    _isOnline       = false;

  bool    _isRecording    = false;
  bool    _recordLocked   = false;
  int     _recordSeconds  = 0;
  Timer?  _recordTimer;
  Timer?  _presenceTimer;
  String? _recordedPath;

  final Map<String, Duration> _audioPositions = {};

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;
  late AnimationController _waveCtrl;
  late AnimationController _slideCtrl;
  late Animation<double>   _slideAnim;

  final _rng = math.Random();
  late List<double> _waveHeights;

  static const _backendUrl = 'https://lesbie-backend.vercel.app';

  String get _chatId {
    final uid = _currentUser?.uid;
    if (uid == null || uid.isEmpty || widget.otherUserId.isEmpty) {
      return widget.matchId;
    }
    return buildMatchId(uid, widget.otherUserId);
  }

  static String buildMatchId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }


  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0C0A14),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
    _loadOtherUserData();
    _markChatAsRead();
    _startPresenceUpdates();
    _waveHeights = List.generate(28, (_) => 4 + _rng.nextDouble() * 18);

    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _waveCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 350));

    _slideCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _slideAnim = Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInOut));

    _messageController.addListener(() {
      final has = _messageController.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (_playingUrl != null && mounted) {
        setState(() => _audioPositions[_playingUrl!] = pos);
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingUrl = null);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    _presenceTimer?.cancel();
    _updateMyLastSeen();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(widget.otherUserId).get();
    if (mounted && doc.exists) {
      final data = doc.data()!;
      final lastSeen = data['lastSeen'] as Timestamp?;
      final isOnline = _isUserOnline(lastSeen);
      setState(() {
        _otherUserData = data;
        _isOnline = isOnline;
      });
    }
  }

  void _startPresenceUpdates() {
    _updateMyLastSeen();
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMyLastSeen();
    });
  }

  Future<void> _updateMyLastSeen() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  bool _isUserOnline(Timestamp? lastSeen) {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen.toDate()).inMinutes < 5;
  }

  String _lastSeenText(dynamic lastSeen) {
    if (lastSeen == null || lastSeen is! Timestamp) {
      return 'last seen recently';
    }

    final date = lastSeen.toDate();
    final now = DateTime.now();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $ampm';

    final isToday =
        date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;

    if (isToday) return 'last seen today at $time';
    if (isYesterday) return 'last seen yesterday at $time';

    return 'last seen ${date.month}/${date.day}/${date.year} at $time';
  }


  Future<void> _ensureChatDoc() async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;
    await FirebaseFirestore.instance.collection('matches').doc(_chatId).set({
      // ✅ IMPORTANT: nou sove toude non chan yo.
      // Gen kèk ekran ki chèche "users", lòt yo chèche "participants".
      // Konsa Discover, Chat List, Notifications ap wè menm chat room lan.
      'participants': [myUid, widget.otherUserId],
      'users': [myUid, widget.otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _markChatAsRead() async {
    final myUid = _currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance.collection('matches').doc(_chatId).set({
      'unread_$myUid': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _ensureChatDoc();
    await FirebaseFirestore.instance
        .collection('matches').doc(_chatId)
        .collection('messages').add({
      'text': text, 'type': 'text',
      'senderId': _currentUser?.uid,
      'readBy': [if (_currentUser?.uid != null) _currentUser!.uid],
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _updateLastMessage(text);
    await _sendPush(text);
    _scrollToBottom();
  }

  Future<void> _sendPhoto() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1080, imageQuality: 80);
    if (picked == null) return;
    setState(() => _isSendingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref()
          .child('chat_photos')
          .child('${_chatId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _ensureChatDoc();
      await FirebaseFirestore.instance
          .collection('matches').doc(_chatId)
          .collection('messages').add({
        'photoUrl': url, 'type': 'photo',
        'senderId': _currentUser?.uid,
        'readBy': [if (_currentUser?.uid != null) _currentUser!.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _updateLastMessage('📷 Photo');
      await _sendPush('📷 Photo');
      _scrollToBottom();
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isSendingPhoto = false);
    }
  }

  Future<void> _updateLastMessage(String text) async {
    final myUid = _currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('matches').doc(_chatId)
        .set({
      // ✅ Mete toude pou tout ekran yo mache menm jan.
      'participants': [if (myUid != null) myUid, widget.otherUserId],
      'users': [if (myUid != null) myUid, widget.otherUserId],
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),

      // ✅ Lè mwen voye mesaj, lòt moun nan gen unread +1.
      if (myUid != null) 'unread_$myUid': 0,
      'unread_${widget.otherUserId}': FieldValue.increment(1),
    }, SetOptions(merge: true));
    final myDoc = await FirebaseFirestore.instance
        .collection('users').doc(_currentUser?.uid).get();
    final myName = myDoc.data()?['username'] ?? 'Someone';
    await FirebaseFirestore.instance.collection('notifications').add({
      'toUid': widget.otherUserId,
      'fromUid': _currentUser?.uid,
      'fromName': myName,

      // ✅ Sa ki fè notification lan ouvri bon chat la.
      'matchId': _chatId,
      'message': text,

      'type': 'message',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendPush(String text) async {
    try {
      final token = _otherUserData?['fcmToken'];
      if (token == null) return;
      final myDoc = await FirebaseFirestore.instance
          .collection('users').doc(_currentUser?.uid).get();
      final myName = myDoc.data()?['username'] ?? 'Someone';
      await http.post(Uri.parse('$_backendUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token, 'title': '💬 $myName', 'body': text,
          'data': {'type': 'message', 'matchId': _chatId,
            'fromUid': _currentUser?.uid ?? ''},
        }),
      );
    } catch (_) {}
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ── Voice ─────────────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) _showError('Mikwofòn pèmisyon obligatwa.');
      return;
    }
    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: path);
      _recordedPath = path;
      HapticFeedback.mediumImpact();
      _pulseCtrl.repeat(reverse: true);
      _waveCtrl.repeat(reverse: true);
      _recordSeconds = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {
          _recordSeconds++;
          if (_recordSeconds % 2 == 0) {
            _waveHeights = List.generate(28, (_) => 4 + _rng.nextDouble() * 18);
          }
        });
      });
      if (mounted) setState(() { _isRecording = true; _recordLocked = false; });
    } catch (e) {
      if (mounted) _showError('Erè: $e');
    }
  }

  Future<void> _stopAndSend() async {
    String? path;
    if (_isRecording) {
      _recordTimer?.cancel();
      _pulseCtrl.stop();
      _waveCtrl.stop();
      path = await _recorder.stop();
      _isRecording = false;
    } else {
      path = _recordedPath;
    }
    if (mounted) setState(() {
      _isRecording    = false;
      _recordLocked   = false;
      _isSendingVoice = path != null && _recordSeconds >= 1;
    });
    if (path == null || _recordSeconds < 1) {
      if (mounted) setState(() => _isSendingVoice = false);
      return;
    }
    try {
      final file = File(path);
      if (!await file.exists()) return;
      final ref = FirebaseStorage.instance.ref()
          .child('voice_notes')
          .child('${_chatId}_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _ensureChatDoc();
      await FirebaseFirestore.instance
          .collection('matches').doc(_chatId)
          .collection('messages').add({
        'audioUrl': url, 'type': 'voice',
        'duration': _recordSeconds,
        'senderId': _currentUser?.uid,
        'readBy': [if (_currentUser?.uid != null) _currentUser!.uid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _updateLastMessage('🎤 Voice note');
      await _sendPush('🎤 Voice note');
      _scrollToBottom();
      await file.delete();
      _recordedPath = null;
    } catch (e) {
      if (mounted) _showError('$e');
    } finally {
      if (mounted) setState(() => _isSendingVoice = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _pulseCtrl.stop();
    _waveCtrl.stop();
    await _recorder.stop();
    _recordedPath = null;
    HapticFeedback.lightImpact();
    if (mounted) setState(() { _isRecording = false; _recordLocked = false; });
  }

  void _lockRecording() {
    HapticFeedback.mediumImpact();
    if (mounted) setState(() => _recordLocked = true);
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _playAudio(String url) async {
    if (_playingUrl == url) {
      await _audioPlayer.pause();
      if (mounted) setState(() => _playingUrl = null);
    } else {
      await _audioPlayer.play(UrlSource(url));
      if (mounted) setState(() => _playingUrl = url);
    }
  }

  void _showProfile() {
    if (_otherUserData == null) return;
    final d          = _otherUserData!;
    final name       = d['username'] ?? d['name'] ?? widget.otherUserName;
    final city       = d['city']  ?? '';
    final bio        = d['bio']   ?? '';
    final photoUrl   = d['photoUrl'] ?? widget.otherUserPhoto;
    final isVerified = d['isVerified'] == true;
    final interests  = List<String>.from(d['interests'] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95,
        expand: false,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: Padding(padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.gray3,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Container(width: 100, height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: AppTheme.pinkGrad, boxShadow: AppTheme.pinkShadow,
                      image: photoUrl != null ? DecorationImage(
                          image: NetworkImage(photoUrl), fit: BoxFit.cover) : null),
                  child: photoUrl == null ? Center(child: Text(name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800,
                          color: Colors.white))) : null),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(name, style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w700, color: AppTheme.white)),
                if (isVerified) ...[const SizedBox(width: 6),
                  const Icon(Icons.verified, color: AppTheme.pink, size: 20)],
              ]),
              if (city.isNotEmpty) ...[const SizedBox(height: 4),
                Text('📍 $city', style: const TextStyle(color: AppTheme.gray, fontSize: 14))],
              if (bio.isNotEmpty) ...[const SizedBox(height: 12),
                Text(bio, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.gray, fontSize: 14, height: 1.5))],
              if (interests.isNotEmpty) ...[const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: interests.map((i) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.pink.withValues(alpha: 0.1),
                            border: Border.all(color: AppTheme.pink.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(i, style: const TextStyle(
                            color: AppTheme.pinkSoft, fontSize: 12)))).toList())],
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 52,
                  child: OutlinedButton(onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.pink.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radius))),
                      child: const Text('Close', style: TextStyle(
                          color: AppTheme.white, fontWeight: FontWeight.w600)))),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomPad = math.max(MediaQuery.of(context).padding.bottom, 12.0);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      resizeToAvoidBottomInset: true,

      // ✅ FIX 5 â€” AppBar pi gwo ak online status
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        toolbarHeight: 64,
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
        ),
        title: GestureDetector(
          onTap: _showProfile,
          child: Row(children: [
            // ✅ Avatar pi gwo â€” 46x46
            Stack(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.pinkGrad,
                  boxShadow: [BoxShadow(
                    color: AppTheme.pink.withValues(alpha: 0.3),
                    blurRadius: 8,
                  )],
                  image: widget.otherUserPhoto != null
                      ? DecorationImage(image: NetworkImage(widget.otherUserPhoto!),
                      fit: BoxFit.cover)
                      : null,
                ),
                child: widget.otherUserPhoto == null
                    ? Center(child: Text(widget.otherUserName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 18)))
                    : null,
              ),
              // Online indicator live
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUserId)
                    .snapshots(),
                builder: (context, userSnap) {
                  final data = userSnap.data?.data() as Map<String, dynamic>?;
                  final lastSeen = data?['lastSeen'] as Timestamp?;
                  final isOnline = _isUserOnline(lastSeen);

                  if (!isOnline) return const SizedBox.shrink();

                  return Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.bg, width: 2),
                      ),
                    ),
                  );
                },
              ),
            ]),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ✅ Username pi bold
              Text(widget.otherUserName, style: const TextStyle(
                  color: AppTheme.white, fontSize: 16,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              // ✅ WhatsApp style: online oswa last seen andan chat la
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.otherUserId)
                    .snapshots(),
                builder: (context, userSnap) {
                  final data = userSnap.data?.data() as Map<String, dynamic>?;
                  final lastSeen = data?['lastSeen'] as Timestamp?;
                  final isOnline = _isUserOnline(lastSeen);

                  return Text(
                    isOnline ? 'online' : _lastSeenText(lastSeen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isOnline ? AppTheme.green : AppTheme.gray,
                      fontSize: 11,
                      fontWeight: isOnline ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ]),
          ]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.gray),
            onPressed: _showProfile,
          ),
        ],
      ),

      body: Column(children: [
        Expanded(child: _buildMessageList()),
        _isRecording ? _buildRecordingBar() : _buildInputBar(bottomPad),
      ]),
    );
  }

  // ── Message list ak gradient background ──────────────────────────────────────
  Widget _buildMessageList() {
    return Container(
      // ✅ FIX 4 â€” gradient subtle background
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.bg,
            const Color(0xFF0C0A14),
            AppTheme.bg,
          ],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches').doc(_chatId)
            .collection('messages')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.pink));
          }
          final msgs = snap.data?.docs ?? [];
          if (msgs.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pink.withValues(alpha: 0.1),
                    border: Border.all(color: AppTheme.pink.withValues(alpha: 0.2)),
                  ),
                  child: Center(child: Text('👋',
                      style: const TextStyle(fontSize: 30))),
                ),
                const SizedBox(height: 16),
                Text('Di ${widget.otherUserName} bonjou!',
                    style: const TextStyle(color: AppTheme.white,
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text('Kòmanse yon konvèsasyon bèl 💬',
                    style: TextStyle(color: AppTheme.gray, fontSize: 13)),
              ],
            ));
          }
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: msgs.length,
            itemBuilder: (_, i) {
              final msg  = msgs[i].data() as Map<String, dynamic>;
              final isMe = msg['senderId'] == _currentUser?.uid;
              final type = msg['type'] ?? 'text';

              // Show date separator
              Widget? dateSep;
              if (i == 0) {
                final ts = msg['createdAt'] as Timestamp?;
                if (ts != null) dateSep = _buildDateSep(ts.toDate());
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (dateSep != null) dateSep,
                  Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe)
                            GestureDetector(
                              onTap: _showProfile,
                              child: Container(
                                width: 32, height: 32,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.pinkGrad,
                                    image: widget.otherUserPhoto != null
                                        ? DecorationImage(
                                        image: NetworkImage(widget.otherUserPhoto!),
                                        fit: BoxFit.cover) : null),
                                child: widget.otherUserPhoto == null
                                    ? Center(child: Text(
                                    widget.otherUserName[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 12, fontWeight: FontWeight.bold)))
                                    : null,
                              ),
                            ),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.72),
                            child: _buildBubble(msg, isMe, type),
                          ),
                        ],
                      ),
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

  Widget _buildDateSep(DateTime date) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Container(height: 1,
            color: AppTheme.gray3.withValues(alpha: 0.5))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: const TextStyle(
                color: AppTheme.gray2, fontSize: 11))),
        Expanded(child: Container(height: 1,
            color: AppTheme.gray3.withValues(alpha: 0.5))),
      ]),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────────
  // ✅ FIX 1 â€” Safe area + padding kÃ²rÃ¨k
  Widget _buildInputBar(double bottomPad) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 14 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A14),
        border: Border(top: BorderSide(
            color: AppTheme.pink.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Photo
        GestureDetector(
          onTap: _isSendingPhoto ? null : _sendPhoto,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppTheme.card2, shape: BoxShape.circle,
              border: Border.all(color: AppTheme.pink.withValues(alpha: 0.25)),
            ),
            child: _isSendingPhoto
                ? const Padding(padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(color: AppTheme.pink, strokeWidth: 2))
                : const Icon(Icons.image_outlined, color: AppTheme.pink, size: 22),
          ),
        ),
        const SizedBox(width: 10),

        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: AppTheme.card2,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.pink.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: null,
              style: const TextStyle(color: AppTheme.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: AppTheme.gray2),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Send / Mic
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _hasText ? _buildSendBtn() : _buildMicBtn(),
        ),
      ]),
    );
  }

  Widget _buildSendBtn() {
    return GestureDetector(
      key: const ValueKey('send'),
      onTap: _sendMessage,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.pinkGrad,
          shape: BoxShape.circle,
          boxShadow: AppTheme.pinkShadow,
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMicBtn() {
    return GestureDetector(
      key: const ValueKey('mic'),
      onLongPressStart: (_) => _startRecording(),
      // Swipe left cancels. Nou retire auto-lock paske li te bloke bouton send la.
      onLongPressMoveUpdate: (d) {
        if (d.offsetFromOrigin.dx < -95) _cancelRecording();
      },
      // Si user lage dwèt li, voye voice note la otomatikman.
      onLongPressEnd: (_) => _stopAndSend(),
      onLongPressCancel: _cancelRecording,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.pinkGrad,
          shape: BoxShape.circle,
          boxShadow: AppTheme.pinkShadow,
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // ✅ FIX 2 — Recording bar pi pwòp: gen Cancel + Send toujou vizib.
  Widget _buildRecordingBar() {
    final bottomPad = math.max(MediaQuery.of(context).padding.bottom, 12.0);
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0A14),
        border: Border(top: BorderSide(color: AppTheme.pink.withValues(alpha: 0.15))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _slideAnim,
          builder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Transform.translate(
                offset: Offset(_slideAnim.value, 0),
                child: Icon(
                  Icons.keyboard_double_arrow_left,
                  color: AppTheme.pink.withValues(alpha: 0.8),
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Swipe left to cancel',
                style: TextStyle(
                  color: AppTheme.gray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Text(
                'Tap send when ready',
                style: TextStyle(color: AppTheme.gray2, fontSize: 11),
              ),
            ]),
          ),
        ),

        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          GestureDetector(
            onTap: _cancelRecording,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.red.withValues(alpha: 0.35)),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.red, size: 20),
            ),
          ),

          const SizedBox(width: 12),

          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.red.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          Text(
            _fmt(_recordSeconds),
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(child: _buildLiveWaveform()),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: _isSendingVoice ? null : _stopAndSend,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.pinkGrad,
                shape: BoxShape.circle,
                boxShadow: AppTheme.pinkShadow,
              ),
              child: _isSendingVoice
                  ? const Padding(
                padding: EdgeInsets.all(13),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildLiveWaveform() {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (_, __) => SizedBox(
        height: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(_waveHeights.length, (i) {
            final wave = math.sin(
                _waveCtrl.value * 2 * math.pi + i * 0.45) * 0.45 + 0.55;
            final h = (_waveHeights[i] * wave).clamp(3.0, 26.0);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 3,
              height: h,
              decoration: BoxDecoration(
                color: i % 4 == 0
                    ? AppTheme.pink
                    : i % 4 == 2
                    ? AppTheme.pinkSoft.withValues(alpha: 0.6)
                    : AppTheme.pink.withValues(alpha: 0.35 + wave * 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Bubbles ───────────────────────────────────────────────────────────────────
  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, String type) {
    if (type == 'photo') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(msg['photoUrl'],
            width: 210, height: 270, fit: BoxFit.cover,
            loadingBuilder: (_, child, p) {
              if (p == null) return child;
              return Container(width: 210, height: 270, color: AppTheme.card2,
                  child: const Center(child: CircularProgressIndicator(color: AppTheme.pink)));
            }),
      );
    }
    if (type == 'voice') return _buildVoiceBubble(msg, isMe);
    return _buildTextBubble(msg, isMe);
  }

  // ✅ FIX 3 â€” Text bubble pi bÃ¨l, plis rounded, plis padding, shadow
  Widget _buildTextBubble(Map<String, dynamic> msg, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: isMe ? AppTheme.pinkGrad : null,
        color: isMe ? null : const Color(0xFF1C1928),
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(20),
          topRight:    const Radius.circular(20),
          bottomLeft:  Radius.circular(isMe ? 20 : 5),
          bottomRight: Radius.circular(isMe ? 5 : 20),
        ),
        border: isMe ? null : Border.all(
            color: AppTheme.pink.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? AppTheme.pink.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(msg['text'] ?? '',
          style: TextStyle(
              color: isMe ? AppTheme.white : AppTheme.white.withValues(alpha: 0.9),
              fontSize: 15, height: 1.4)),
    );
  }

  // ✅ Voice bubble
  Widget _buildVoiceBubble(Map<String, dynamic> msg, bool isMe) {
    final audioUrl  = msg['audioUrl'] as String? ?? '';
    final totalSec  = (msg['duration'] as int?) ?? 0;
    final isPlaying = _playingUrl == audioUrl;
    final position  = _audioPositions[audioUrl] ?? Duration.zero;
    final totalMs   = (totalSec > 0 ? totalSec : 1) * 1000;
    final progress  = isPlaying
        ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: 235,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe ? AppTheme.pinkGrad : null,
        color: isMe ? null : const Color(0xFF1C1928),
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(20),
          topRight:    const Radius.circular(20),
          bottomLeft:  Radius.circular(isMe ? 20 : 5),
          bottomRight: Radius.circular(isMe ? 5 : 20),
        ),
        border: isMe ? null : Border.all(
            color: AppTheme.pink.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(
            color: isMe
                ? AppTheme.pink.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => _playAudio(audioUrl),
          child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppTheme.pink.withValues(alpha: 0.12),
                  shape: BoxShape.circle),
              child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isMe ? Colors.white : AppTheme.pink, size: 22)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(24, (i) {
                  const pat = [
                    0.3, 0.6, 0.9, 0.5, 0.8, 0.4, 0.7, 1.0,
                    0.6, 0.8, 0.5, 0.9, 0.7, 0.4, 0.8, 0.6,
                    0.5, 0.9, 0.7, 0.4, 0.6, 0.8, 0.5, 0.7,
                  ];
                  final isPassed = (i / 24) < progress;
                  final h = (pat[i] * 14 + 3).clamp(3.0, 16.0);
                  return Container(
                      width: 2.5, height: h,
                      decoration: BoxDecoration(
                          color: isPassed
                              ? (isMe ? Colors.white : AppTheme.pink)
                              : (isMe
                              ? Colors.white.withValues(alpha: 0.3)
                              : AppTheme.gray3),
                          borderRadius: BorderRadius.circular(1.5)));
                }),
              ),
            ),
            const SizedBox(height: 4),
            Text(isPlaying ? _fmt(position.inSeconds) : _fmt(totalSec),
                style: TextStyle(
                    color: isMe ? Colors.white.withValues(alpha: 0.75) : AppTheme.gray,
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        )),
      ]),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}


