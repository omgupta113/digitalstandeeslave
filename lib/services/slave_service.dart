import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';
import 'device_service.dart';

class SlaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register slave ID locally and on Firebase
  Future<void> registerSlave(String slaveId) async {
    final deviceId = await DeviceService.getDeviceId();

    // Update Firebase
    await _firestore.collection('slaves').doc(slaveId).set({
      'deviceId': deviceId,
      'slaveId': slaveId,
      'isActive': true,
      'lastSeen': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('slave_id', slaveId);
  }

  // Get or create slave ID
  Future<String> getOrCreateSlaveId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedSlaveId = prefs.getString('slave_id');

    if (storedSlaveId != null) {
      // Verify if slave ID exists in Firebase
      final slaveDoc = await _firestore.collection('slaves').doc(storedSlaveId).get();
      if (slaveDoc.exists) {
        return storedSlaveId;
      }
    }

    // Generate new slave ID based on device ID
    final deviceId = await DeviceService.getDeviceId();
    final newSlaveId = DeviceService.generateSlaveId(deviceId);

    // Register the new slave
    await registerSlave(newSlaveId);
    return newSlaveId;
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