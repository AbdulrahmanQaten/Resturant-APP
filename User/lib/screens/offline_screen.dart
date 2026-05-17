// lib/screens/offline_screen.dart
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class OfflineScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineScreen({Key? key, required this.onRetry}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Remix.wifi_off_line, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text('لا يوجد اتصال بالإنترنت',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                  'يرجى التحقق من اتصالك بالشبكة ثم الضغط على زر إعادة المحاولة.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Remix.refresh_line, color: Colors.white),
                label: const Text('إعادة المحاولة'),
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
