import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error initializing camera: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras[_selectedCameraIndex],
      ResolutionPreset.high,
    );
    await _controller!.initialize();
    setState(() {});
  }

  void _switchCamera() {
    if (cameras.length < 2) return; // ป้องกันข้อผิดพลาดหากมีกล้องเดียว
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
      _initializeCamera();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile imageFile = await _controller!.takePicture();
      await Gal.putImage(imageFile.path);
      setState(() {
        _pickedImage = imageFile;
      });
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

  Widget polaroidImage(String imagePath) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.file(File(imagePath), fit: BoxFit.cover),
          ),
          SizedBox(height: 8),
          Text("Captured Image", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter Camera")),
      body: Column(
        children: [
          Expanded(
            child:
                _controller == null || !_controller!.value.isInitialized
                    ? Center(child: CircularProgressIndicator())
                    : CameraPreview(_controller!),
          ),
          if (_pickedImage != null) polaroidImage(_pickedImage!.path),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                child: Icon(Icons.switch_camera),
                onPressed: _switchCamera,
              ),
              SizedBox(width: 20),
              FloatingActionButton(
                child: Icon(Icons.camera),
                onPressed: _captureImage,
              ),
              SizedBox(width: 20),
              FloatingActionButton(
                child: Icon(Icons.image),
                onPressed: _pickImage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
