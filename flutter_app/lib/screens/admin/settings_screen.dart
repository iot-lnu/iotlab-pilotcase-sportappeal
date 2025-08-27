import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  double _dataRefreshRate = 5.0; // in seconds

  void _toggleTheme(bool value) {
    setState(() {
      _darkModeEnabled = value;
    });
    // Simple implementation of theme change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Theme changed to ${value ? "dark" : "light"} mode. This will be applied in a future update.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    // Simple implementation of notification toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifications ${value ? "enabled" : "disabled"}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeRefreshRate(double value) {
    setState(() {
      _dataRefreshRate = value;
    });
    // Simple implementation of refresh rate change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Refresh rate set to ${value.toStringAsFixed(1)} seconds',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToSensorConfig() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sensor configuration will be available in a future update',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToDataCollection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data collection settings will be available in a future update',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _logout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('LOGOUT'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF007340),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Application Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            value: _darkModeEnabled,
            onChanged: _toggleTheme,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
          const Divider(),
          ListTile(
            title: const Text('Data Refresh Rate'),
            subtitle: Text('${_dataRefreshRate.toStringAsFixed(1)} seconds'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: _dataRefreshRate,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: '${_dataRefreshRate.toStringAsFixed(1)} sec',
                onChanged: _changeRefreshRate,
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Sensor Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Sensor Configuration'),
            subtitle: const Text('Configure sensor parameters'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _navigateToSensorConfig,
          ),
          ListTile(
            leading: const Icon(Icons.data_usage),
            title: const Text('Data Collection'),
            subtitle: const Text('Manage data collection settings'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _navigateToDataCollection,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _logout,
              child: const Text('LOG OUT'),
            ),
          ),
        ],
      ),
    );
  }
}
