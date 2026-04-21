import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

class VerificationService {
  // URL backend Railway ou a
  static const String _backendUrl =
      'https://lesbie-backend.railway.app';

  static Future<Map<String, dynamic>> createVerificationSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Pa gen itilizatè konekte');

    final dio = Dio();
    final response = await dio.post(
      '$_backendUrl/create-verification-session',
      data: {'userId': user.uid},
    );

    return response.data;
  }

  static Future<bool> checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['isVerified'] == true;
  }
}