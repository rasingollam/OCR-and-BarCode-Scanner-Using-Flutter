import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  String _recognizedText = "No text recognized yet.";
  File? _pickedImageFile;
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(); // Simplified for Latin script
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> _processImageFromCamera() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _recognizedText = "Processing...";
      _pickedImageFile = null;
    });

    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        _pickedImageFile = File(pickedFile.path);
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final RecognizedText recognisedText =
            await _textRecognizer.processImage(inputImage);
        
        String originalText = recognisedText.text;
        if (originalText.isEmpty) {
          setState(() {
            _recognizedText = "No text found in the image.";
          });
        } else {
          List<String> lines = originalText.split('\n');
          List<String> formattedLines = [];
          for (int i = 0; i < lines.length; i += 2) {
            if (i + 1 < lines.length) {
              // Check if both lines are not empty before joining, or join as is
              String line1 = lines[i].trim();
              String line2 = lines[i+1].trim();
              if (line1.isNotEmpty && line2.isNotEmpty) {
                formattedLines.add("$line1 $line2");
              } else if (line1.isNotEmpty) {
                formattedLines.add(line1);
              } else if (line2.isNotEmpty) {
                // This case is less likely if line1 was empty, but good to handle
                formattedLines.add(line2);
              } else {
                // Both lines (or the first of the pair) might be empty after trim
                // if original line was just whitespace. Add a blank line or skip.
                // For now, let's add if there was content before trim or if it's an intended blank line.
                if (lines[i].isNotEmpty || (i+1 < lines.length && lines[i+1].isNotEmpty)) {
                   formattedLines.add("${lines[i]} ${lines[i+1]}".trim()); // trim the combined result
                }
              }
            } else {
              // Odd number of lines, add the last line as is
              formattedLines.add(lines[i].trim());
            }
          }
          // Filter out any completely empty strings that might have resulted from processing
          // if two consecutive original lines were empty or only whitespace.
          String finalText = formattedLines.where((line) => line.isNotEmpty).join('\n');

          setState(() {
            _recognizedText = finalText.isEmpty ? "No text found after formatting." : finalText;
          });
        }
      } else {
        setState(() {
          _recognizedText = "No image captured.";
        });
      }
    } catch (e) {
      setState(() {
        _recognizedText = "Error: ${e.toString()}";
      });
      debugPrint("Error processing image: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ML Kit OCR (Camera)')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_pickedImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Image.file(
                    _pickedImageFile!,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                onPressed: _isProcessing ? null : _processImageFromCamera,
                label: const Text('Capture with Camera & Recognize'),
              ),
              const SizedBox(height: 30),
              const Text(
                "Recognized Text:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SelectableText(
                  _recognizedText,
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
