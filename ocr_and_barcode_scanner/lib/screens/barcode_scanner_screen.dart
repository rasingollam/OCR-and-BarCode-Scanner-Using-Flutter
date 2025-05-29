import 'package:flutter/material.dart';
import 'package:native_barcode_scanner/barcode_scanner.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _withOverlay = true; // Keep overlay enabled by default for the square
  bool _hasCameraPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasCameraPermission = status.isGranted;
        _isCheckingPermission = false; // Done checking
        if (_hasCameraPermission) {
          // Optional: Automatically start scanner if permission granted
          // BarcodeScanner.startScanner();
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Barcode Scanner')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasCameraPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Barcode Scanner')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Camera permission is required to scan barcodes.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Attempt to open app settings if permission permanently denied or to re-request
                  if (await Permission.camera.isPermanentlyDenied || await Permission.camera.isDenied) {
                    openAppSettings();
                  } else {
                     _requestCameraPermission(); // Re-request if just denied once
                  }
                },
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // If permission is granted, build the scanner UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          PopupMenuButton<CameraActions>(
            icon: const Icon(Icons.more_vert),
            onSelected: (CameraActions result) {
              switch (result) {
                case CameraActions.flipCamera:
                  BarcodeScanner.flipCamera();
                  break;
                case CameraActions.toggleFlashlight:
                  BarcodeScanner.toggleFlashlight();
                  break;
                case CameraActions.stopScanner:
                  BarcodeScanner.stopScanner();
                  break;
                case CameraActions.startScanner:
                  BarcodeScanner.startScanner();
                  break;
                case CameraActions.setOverlay:
                  setState(() => _withOverlay = !_withOverlay);
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CameraActions>>[
              const PopupMenuItem<CameraActions>(
                value: CameraActions.startScanner,
                child: Text('Start scanner'),
              ),
              const PopupMenuItem<CameraActions>(
                value: CameraActions.stopScanner,
                child: Text('Stop scanner'),
              ),
              const PopupMenuItem<CameraActions>(
                value: CameraActions.flipCamera,
                child: Text('Flip camera'),
              ),
              const PopupMenuItem<CameraActions>(
                value: CameraActions.toggleFlashlight,
                child: Text('Toggle flashlight'),
              ),
              PopupMenuItem<CameraActions>(
                value: CameraActions.setOverlay,
                child: Text('${_withOverlay ? 'Remove' : 'Add'} overlay'),
              ),
            ],
          ),
        ],
      ),
      body: Center( // Center the scanner area
        child: SizedBox( // Define the size of the scanner area
          width: 350, // Desired width for the square scanner
          height: 200, // Desired height for the square scanner
          child: Builder(builder: (builderContext) {
            Widget scannerWidget = BarcodeScannerWidget(
              scannerType: ScannerType.barcode,
              onBarcodeDetected: (barcode) async {
                await BarcodeScanner.stopScanner();

                await showDialog(
                  context: builderContext,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Barcode Detected'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Value: ${barcode.value}'),
                          Text('Format: ${barcode.format.name}'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            BarcodeScanner.startScanner();
                          },
                          child: const Text('OK & Scan Again'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext); // Close dialog
                            Navigator.pop(context); // Go back from scanner screen
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    );
                  },
                );
              },
              onError: (dynamic error) {
                debugPrint('Scanner Error: $error');
                ScaffoldMessenger.of(builderContext).showSnackBar(
                  SnackBar(content: Text('Scanner Error: $error')),
                );
              },
            );

            if (_withOverlay) {
              // The scannerWidget itself is now the 300x300 area
              return _buildWithOverlay(scannerWidget);
            }
            return scannerWidget;
          }),
        ),
      ),
    );
  }

  Widget _buildWithOverlay(Widget scannerWidget) {
    // Overlay will now be relative to the sized scannerWidget
    return Stack(
      children: [
        scannerWidget, // The sized scanner widget
        Center( // Center the decorative elements over the scanner
          child: Container(
            width: double.infinity, // Takes the width of the parent SizedBox (300)
            height: double.infinity, // Takes the height of the parent SizedBox (300)
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red[400] ?? Colors.red, width: 2),
              // borderRadius: BorderRadius.circular(15), // Optional: if you want rounded corners for the border
            ),
            // You can add a semi-transparent viewfinder line or other elements here
            // For example, a simple horizontal line:
            // child: Align(
            //   alignment: Alignment.center,
            //   child: Container(
            //     height: 2,
            //     color: Colors.green.withOpacity(0.7),
            //     margin: const EdgeInsets.symmetric(horizontal: 20), // Adjust margin as needed
            //   ),
            // ),
          ),
        ),
      ],
    );
  }
}

enum CameraActions {
  flipCamera,
  toggleFlashlight,
  stopScanner,
  startScanner,
  setOverlay
}
