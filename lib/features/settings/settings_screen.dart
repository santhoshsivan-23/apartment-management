import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../authentication/screens/pin_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change PIN'),
            subtitle: const Text('Update the local PIN that protects this app'),
            onTap: () async {
              await AuthService().resetPin();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                );
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Storage'),
            subtitle: Text('All data is stored locally on this device in SQLite. Nothing is sent to any server.'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            subtitle: Text('Apartment Management System — fully offline edition, v1.0.0'),
          ),
        ],
      ),
    );
  }
}
