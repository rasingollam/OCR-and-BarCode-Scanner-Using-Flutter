import 'package:flutter/material.dart';

class OcrScannerScreen extends StatelessWidget {
  const OcrScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scanner'),
      ),
      body: const Center(
        child: Text('OCR Scanner Screen'),
      ),
    );
  }
}
