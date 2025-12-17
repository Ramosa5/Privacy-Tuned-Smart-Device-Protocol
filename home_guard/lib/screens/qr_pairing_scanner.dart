import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrPairingScanner extends StatelessWidget {
  const QrPairingScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan HomeGuard QR')),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.firstOrNull;
          final raw = barcode?.rawValue;
          if (raw == null) return;

          // Return QR string to caller and close scanner
          Navigator.pop(context, raw);
        },
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
