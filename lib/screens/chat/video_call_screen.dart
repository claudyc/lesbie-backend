import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String matchUid;
  final String matchName;
  final String? matchPhotoUrl;
  final String channelName;

  const VideoCallScreen({
    super.key,
    required this.matchUid,
    required this.matchName,
    this.matchPhotoUrl,
    required this.channelName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _engine;
  bool _isJoined = false;
  bool _remoteUserJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _agoraAppId;

  static const String _backendUrl = 'https://lesbie-backend.vercel.app';

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  Future<void> _cleanUp() async {
    try {
      await _engine.leaveChannel();
      await _engine.release();
    } catch (_) {}
  }

  Future<void> _initAgora() async {
    // ✅ FIX 1 — mande pèmisyon anvan tout bagay epi verifye yo aksepte
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kamera ak mikwofòn pèmisyon obligatwa pou video call.';
        });
      }
      return;
    }

    try {
      // ✅ FIX 2 — jwenn token Agora ak Firebase Auth token
      final currentUser = FirebaseAuth.instance.currentUser!;
      final idToken = await currentUser.getIdToken();
      final uid = currentUser.uid.hashCode.abs() % 100000;

      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $idToken';

      final response = await dio.post(
        '$_backendUrl/generate-agora-token',
        data: {
          'channelName': widget.channelName,
          'uid': uid,
        },
      );

      final token = response.data['token'] as String;
      _agoraAppId = response.data['appId'] as String;

      // Inisyalize Agora Engine
      _engine = createAgoraRtcEngine();
      await _engine.initialize(RtcEngineContext(
        appId: _agoraAppId!,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      await _engine.enableVideo();
      await _engine.startPreview();

      // Event handlers
      _engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (mounted) setState(() {
              _isJoined = true;
              _isLoading = false;
            });
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (mounted) setState(() {
              _remoteUid = remoteUid;
              _remoteUserJoined = true;
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (mounted) {
              setState(() {
                _remoteUid = null;
                _remoteUserJoined = false;
              });
              _showInfo('${widget.matchName} kite apèl la.');
            }
          },
          onError: (err, msg) {
            if (mounted) _showError('Erè: $msg');
          },
        ),
      );

      // Konekte nan channel
      await _engine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: uid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      await _saveCallRecord();
    } on DioException catch (e) {
      // ✅ FIX 3 — trete erè Dio separeman
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Pa ka konekte ak servè a. Verifye entènèt ou.';
        });
        debugPrint('Dio error: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erè koneksyon: $e';
        });
      }
    }
  }

  Future<void> _saveCallRecord() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('calls').add({
        'callerUid': currentUser.uid,
        'receiverUid': widget.matchUid,
        'channelName': widget.channelName,
        'startedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    } catch (e) {
      debugPrint('Save call record error: $e');
    }
  }

  Future<void> _endCall() async {
    try {
      await _engine.leaveChannel();

      // ✅ FIX 4 — mete ajou konte video call pou peyi gratis
      final currentUser = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final country = userDoc.data()?['country'] ?? '';
      final freeCountries = ['HT', 'DO', 'MX'];

      if (freeCountries.contains(country)) {
        final videoCallsUsed = (userDoc.data()?['videoCallsUsed'] ?? 0) + 1;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'videoCallsUsed': videoCallsUsed});
      }

      // Mete ajou estati apèl la
      await FirebaseFirestore.instance
          .collection('calls')
          .where('callerUid', isEqualTo: currentUser.uid)
          .where('channelName', isEqualTo: widget.channelName)
          .limit(1)
          .get()
          .then((snap) {
        if (snap.docs.isNotEmpty) {
          snap.docs.first.reference.update({
            'status': 'ended',
            'endedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('End call error: $e');
    }

    if (mounted) Navigator.pop(context);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _engine.muteLocalVideoStream(_isCameraOff);
  }

  void _switchCamera() => _engine.switchCamera();

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 5 — montre paj erè si pèmisyon refize
    if (_errorMessage != null && !_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Retounen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video remote
          if (_remoteUserJoined && _remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildWaitingScreen(),

          // Video lokal
          if (_isJoined)
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.pink, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isCameraOff
                      ? Container(
                    color: const Color(0xFF2D1B4E),
                    child: const Center(
                      child: Icon(Icons.videocam_off,
                          color: Colors.white54, size: 32),
                    ),
                  )
                      : AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16, right: 16, bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.pinkGrad,
                      image: widget.matchPhotoUrl != null
                          ? DecorationImage(
                        image: NetworkImage(widget.matchPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: widget.matchPhotoUrl == null
                        ? Center(
                      child: Text(
                        widget.matchName[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.matchName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(
                        _remoteUserJoined ? 'Konekte ✅' : 'Ap tann...',
                        style: TextStyle(
                          color: _remoteUserJoined
                              ? Colors.green
                              : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bouton kontrol
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white.withOpacity(0.2),
                  onTap: _toggleMute,
                ),
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 70, height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 32),
                  ),
                ),
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  color: _isCameraOff
                      ? Colors.red
                      : Colors.white.withOpacity(0.2),
                  onTap: _toggleCamera,
                ),
              ],
            ),
          ),

          // Switch kamera
          if (_isJoined)
            Positioned(
              bottom: 130, right: 24,
              child: _buildControlButton(
                icon: Icons.flip_camera_ios,
                color: Colors.white.withOpacity(0.2),
                onTap: _switchCamera,
              ),
            ),

          // Loading
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.pink),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Container(
      color: const Color(0xFF1A0F30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.pinkGrad,
                image: widget.matchPhotoUrl != null
                    ? DecorationImage(
                  image: NetworkImage(widget.matchPhotoUrl!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: widget.matchPhotoUrl == null
                  ? Center(
                child: Text(
                  widget.matchName[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
                  : null,
            ),
            const SizedBox(height: 20),
            Text(widget.matchName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Ap tann koneksyon...',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.pink),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.pink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}