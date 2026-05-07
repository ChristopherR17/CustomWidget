import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ProxmoxDriveApp());
}

class ProxmoxDriveApp extends StatelessWidget {
  const ProxmoxDriveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proxmox Drive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006D77)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
