import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/slave_registration_screen.dart';
import 'screens/content_display_screen.dart';
import 'services/slave_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDvOcDbamaIzVDt6rb6h2LyKPZ2Qxm_zJw",
      appId: "1:590835420327:android:8b766b006471561bdc9f82",
      messagingSenderId: "590835420327",
      projectId: "digital-standee-8653f",
      storageBucket: "digital-standee-8653f.appspot.com",
    ),
  );

  // Set landscape orientation


  // Set full screen
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(SlaveApp());
}

class SlaveApp extends StatelessWidget {
  final SlaveService _slaveService = SlaveService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Signage Slave',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<String>(
        future: _slaveService.getOrCreateSlaveId(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return ContentDisplayScreen(slaveId: snapshot.data!);
          }

          return Center(
            child: Text('Error initializing slave device'),
          );
        },
      ),
    );
  }
}