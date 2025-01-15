import 'package:flutter/material.dart';
import '../services/slave_service.dart';
import 'content_display_screen.dart';

class SlaveRegistrationScreen extends StatefulWidget {
  @override
  _SlaveRegistrationScreenState createState() => _SlaveRegistrationScreenState();
}

class _SlaveRegistrationScreenState extends State<SlaveRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final SlaveService _slaveService = SlaveService();
  String _slaveId = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _slaveService.registerSlave(_slaveId);
        await _slaveService.updateStatus(_slaveId, true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ContentDisplayScreen(slaveId: _slaveId),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error registering: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RotatedBox(
        quarterTurns: 1,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Digital Signage Slave Registration',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 30),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Enter Slave ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter the Slave ID' : null,
                  onChanged: (value) => _slaveId = value,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Register Slave'),
                ),
              ],
            ),
          ),
        ),
      ),
      ));
  }
}