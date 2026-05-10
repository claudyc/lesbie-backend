import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import '../../core/theme.dart';
import 'verification_success_screen.dart';

class VideoVerifyScreen extends StatefulWidget {
  const VideoVerifyScreen({super.key});

  @override
  State<VideoVerifyScreen> createState() => _VideoVerifyScreenState();
}

class _VideoVerifyScreenState extends State<VideoVerifyScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;

  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isUploading = false;
  bool _recordingComplete = false;

  bool _isDetectingFace = false;
  bool _faceDetected = false;
  String _faceStatus = 'Mete figi ou nan kadran an';

  int _recordingSeconds = 0;
  XFile? _recordedFile;
  XFile? _selfieFile;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const int _minSeconds = 30;
  static const int _maxSeconds = 40;

  @override
  void initState() {
    super.initState();

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: false,
        enableContours: false,
        enableLandmarks: false,
        minFaceSize: 0.18,
      ),
    );

    _initCamera();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _stopFaceStream();
    _cameraController?.dispose();
    _faceDetector.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) _showError('Pa gen kamera sou telefòn sa.');
        return;
      }

      final frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() => _isCameraReady = true);

      await _startFaceStream();
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) _showError('Erè kamera: $e');
    }
  }

  Future<void> _startFaceStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isStreamingImages) return;

    try {
      await controller.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint('Face stream error: $e');
    }
  }

  Future<void> _stopFaceStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (!controller.value.isStreamingImages) return;

    try {
      await controller.stopImageStream();
    } catch (e) {
      debugPrint('Stop face stream error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetectingFace || _isRecording || _recordingComplete) return;

    _isDetectingFace = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isDetectingFace = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      String status;
      bool ok = false;

      if (faces.isEmpty) {
        status = 'Mete figi ou nan kadran an';
      } else if (faces.length > 1) {
        status = 'Yon sèl figi sèlman';
      } else {
        final face = faces.first;
        final faceWidth = face.boundingBox.width;
        final faceHeight = face.boundingBox.height;

        if (faceWidth < 90 || faceHeight < 120) {
          status = 'Pwoche figi ou yon ti kras';
        } else {
          ok = true;
          status = 'Figi detekte ✅';
        }
      }

      setState(() {
        _faceDetected = ok;
        _faceStatus = status;
      });
    } catch (e) {
      debugPrint('Face detection error: $e');
    } finally {
      _isDetectingFace = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final camera = controller.description;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    ) ??
        InputImageRotation.rotation0deg;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (image.planes.isEmpty) return null;

    final bytes = image.planes.first.bytes;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Future<XFile?> _captureSelfie() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return null;

    try {
      await _stopFaceStream();
      final selfie = await controller.takePicture();
      return selfie;
    } catch (e) {
      debugPrint('Selfie capture error: $e');
      return null;
    }
  }

  Future<void> _startRecording() async {
    if (_cameraController == null || !_isCameraReady) return;

    if (!_faceDetected) {
      _showError('Mete figi ou nan kadran an avan ou kòmanse.');
      return;
    }

    try {
      final selfie = await _captureSelfie();
      if (selfie == null) {
        _showError('Nou pa ka pran selfie a. Eseye ankò.');
        await _startFaceStream();
        return;
      }

      _selfieFile = selfie;

      await _cameraController!.startVideoRecording();
      _pulseCtrl.repeat(reverse: true);

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _runTimer();
    } catch (e) {
      debugPrint('Recording error: $e');
      if (mounted) _showError('Erè anrejistreman: $e');
    }
  }

  void _runTimer() async {
    for (int i = 1; i <= _maxSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return;

      setState(() => _recordingSeconds = i);

      if (i == _maxSeconds) {
        await _stopRecording();
        return;
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_cameraController == null || !_isRecording) return;

    if (_recordingSeconds < _minSeconds) {
      _showError('Tanpri tann omwen $_minSeconds segond.');
      return;
    }

    try {
      final file = await _cameraController!.stopVideoRecording();
      _pulseCtrl.stop();

      setState(() {
        _isRecording = false;
        _recordingComplete = true;
        _recordedFile = file;
      });
    } catch (e) {
      debugPrint('Stop recording error: $e');
      if (mounted) _showError('Erè: $e');
    }
  }

  Future<void> _reRecord() async {
    setState(() {
      _recordingComplete = false;
      _recordingSeconds = 0;
      _recordedFile = null;
      _selfieFile = null;
      _faceDetected = false;
      _faceStatus = 'Mete figi ou nan kadran an';
    });

    await _startFaceStream();
  }

  Future<String> _uploadFile({
    required File file,
    required String path,
    required String contentType,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putFile(
      file,
      SettableMetadata(contentType: contentType),
    );

    return ref.getDownloadURL();
  }

  Future<void> _submitVerification() async {
    if (_recordedFile == null) {
      _showError('Pa gen video. Anrejistre ankò.');
      return;
    }

    if (_selfieFile == null) {
      _showError('Pa gen selfie. Anrejistre ankò.');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('Session ekspire.');
        setState(() => _isUploading = false);
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      final videoUrl = await _uploadFile(
        file: File(_recordedFile!.path),
        path: 'verifications/${user.uid}/video_$now.mp4',
        contentType: 'video/mp4',
      );

      final selfieUrl = await _uploadFile(
        file: File(_selfieFile!.path),
        path: 'verifications/${user.uid}/selfie_$now.jpg',
        contentType: 'image/jpeg',
      );

      await FirebaseFirestore.instance
          .collection('verification_requests')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'status': 'pending_ai',
        'submittedAt': FieldValue.serverTimestamp(),
        'type': 'video_selfie',
        'duration': _recordingSeconds,
        'videoUrl': videoUrl,
        'selfieUrl': selfieUrl,
        'faceDetected': true,
        'faceDetectionProvider': 'google_mlkit_face_detection',
        'allowedGender': 'female',
        'claimedGender': 'female',
        'genderReviewRequired': true,
        'aiProvider': 'facepp',
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'onboardingComplete': true,
        'verificationStatus': 'pending_ai',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'claimedGender': 'female',
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const VerificationSuccessScreen()),
            (route) => false,
      );
    } catch (e) {
      debugPrint('Submit error: $e');
      if (mounted) {
        _showError('Erè upload verification: $e');
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _isCameraReady && _faceDetected && !_isRecording;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildProgress(5, 5)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Video Verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selfie + video pou verification otomatik\nFigi dwe klè avan ou kòmanse.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _recordingComplete
                      ? _buildSuccessPreview()
                      : _isCameraReady
                      ? _buildCameraPreview()
                      : _buildLoadingPreview(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_isRecording && !_recordingComplete)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildInstruction('👤', 'Mete figi ou byen klè nan kadran an'),
                    _buildInstruction('📸', 'App la ap pran yon selfie otomatik'),
                    _buildInstruction('🗣️', 'Di: "Mwen se yon fi reyèl sou Lesbie Chat"'),
                    _buildInstruction('⏱️', 'Anrejistre 30-40 segond'),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildActionButton(canStart),
            ),
            if (_recordingComplete)
              TextButton(
                onPressed: _reRecord,
                child: Text(
                  'Anrejistre Ankò',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 210,
            height: 285,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(140),
              border: Border.all(
                color: _faceDetected
                    ? AppTheme.green
                    : Colors.white.withValues(alpha: 0.65),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_faceDetected ? AppTheme.green : AppTheme.pink)
                      .withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _buildFaceBadge(),
        ),
        if (!_isRecording)
          Positioned(
            bottom: 72,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (_faceDetected ? AppTheme.green : Colors.white)
                        .withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  _faceStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _faceDetected ? AppTheme.green : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_isRecording)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fmt(_recordingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_isRecording)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_recordingSeconds >= _minSeconds)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    color: AppTheme.green.withValues(alpha: 0.85),
                    child: const Text(
                      '✅ Bon — ou ka kontinye jiska 40s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                LinearProgressIndicator(
                  value: _recordingSeconds / _maxSeconds,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _recordingSeconds >= _minSeconds
                        ? AppTheme.green
                        : AppTheme.pink,
                  ),
                  minHeight: 5,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFaceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (_faceDetected ? AppTheme.green : AppTheme.pink)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _faceDetected ? Icons.verified_rounded : Icons.face_rounded,
            color: _faceDetected ? AppTheme.green : AppTheme.pink,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _faceDetected ? 'Face detected' : 'Looking for face',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessPreview() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppTheme.green.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.green.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.green,
              size: 46,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Video + selfie voye! ✅',
            style: TextStyle(
              color: AppTheme.green,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$_recordingSeconds sekond • figi detekte',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'AI verification ap kontinye sou backend la',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPreview() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.pink),
      ),
    );
  }

  Widget _buildActionButton(bool canStart) {
    Color c1;
    Color c2;
    IconData icon;
    String label;
    VoidCallback? onTap;

    if (_isUploading) {
      c1 = c2 = AppTheme.pink;
      icon = Icons.upload;
      label = 'Ap voye...';
      onTap = null;
    } else if (_recordingComplete) {
      c1 = AppTheme.green;
      c2 = const Color(0xFF27AE60);
      icon = Icons.check_circle_outline;
      label = 'Kontinye nan App';
      onTap = _submitVerification;
    } else if (_isRecording) {
      c1 = _recordingSeconds >= _minSeconds
          ? AppTheme.red
          : Colors.white.withValues(alpha: 0.12);
      c2 = _recordingSeconds >= _minSeconds
          ? const Color(0xFFE74C3C)
          : Colors.white.withValues(alpha: 0.12);
      icon = _recordingSeconds >= _minSeconds
          ? Icons.stop_rounded
          : Icons.hourglass_top_rounded;
      label = _recordingSeconds >= _minSeconds
          ? 'Stop Recording'
          : '${_minSeconds - _recordingSeconds}s avan ou ka stop';
      onTap = _recordingSeconds >= _minSeconds ? _stopRecording : null;
    } else {
      c1 = canStart ? AppTheme.pink : Colors.white.withValues(alpha: 0.13);
      c2 = canStart ? const Color(0xFFFF4FAF) : Colors.white.withValues(alpha: 0.13);
      icon = Icons.videocam_rounded;
      label = canStart ? 'Kòmanse Verifikasyon' : 'Mete figi ou nan kadran an';
      onTap = canStart ? _startRecording : null;
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [c1, c2]),
          borderRadius: BorderRadius.circular(AppTheme.radius),
          boxShadow: onTap != null && !_isRecording ? AppTheme.pinkShadow : [],
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
          child: _isUploading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _buildInstruction(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int current, int total) {
    return Row(
      children: List.generate(
        total,
            (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 3,
            decoration: BoxDecoration(
              color: i < current
                  ? AppTheme.pink
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
