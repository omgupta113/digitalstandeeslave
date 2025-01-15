import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class SlaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register slave ID locally
  Future<void> registerSlaveLocally(String slaveId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slave_id', slaveId);
  }

  // Update slave status
  Future<void> updateStatus(String slaveId, bool isActive) async {
    await _firestore.collection('slaves').doc(slaveId).update({
      'isActive': isActive,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  // Stream content for this slave
  Stream<List<Content>> getContent(String slaveId) {
    return _firestore
        .collection('content')
        .where('slaveId', isEqualTo: slaveId)
        .orderBy('sequence')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Content.fromMap(doc.data()))
        .toList());
  }
}
