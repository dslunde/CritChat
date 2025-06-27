import 'dart:io';
import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final String filePath;

  const PreviewPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Stack(
        children: [
          Image.file(File(filePath), fit: BoxFit.cover, width: double.infinity, height: double.infinity,),
          _buildControlButtons(context),
        ],
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Go back to camera
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () {
              // Send logic here
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
} 