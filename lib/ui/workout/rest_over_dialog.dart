import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

/// SPEC §5.4: full-screen "Rest over" popup; vibrates on repeat until dismissed.
Future<void> showRestOver(BuildContext context, String nextText) async {
  // 0.8 s on, 0.4 s off, looping from index 0 until cancelled.
  Vibration.vibrate(pattern: [0, 800, 400], repeat: 0).ignore();
  try {
    await _show(context, nextText);
  } finally {
    Vibration.cancel().ignore();
  }
}

Future<void> _show(BuildContext context, String nextText) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Rest over 💪',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(nextText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 48),
              SizedBox(
                height: 72,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
