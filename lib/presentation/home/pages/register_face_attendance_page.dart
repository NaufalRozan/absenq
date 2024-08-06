import 'dart:typed_data';
import 'package:absenq/presentation/home/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../core/ml/recognition_embedding.dart';
import '../../../core/ml/recognizer.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../bloc/update_user_register_face/update_user_register_face_bloc.dart';
import '../widgets/face_detector_painter.dart';

class RegisterFaceAttendencePage extends StatefulWidget {
  const RegisterFaceAttendencePage({super.key});

  @override
  State<RegisterFaceAttendencePage> createState() =>
      _RegisterFaceAttendencePageState();
}

class _RegisterFaceAttendencePageState
    extends State<RegisterFaceAttendencePage> {
  List<CameraDescription>? _availableCameras;
  late CameraDescription description = _availableCameras![1];
  CameraController? _controller;
  CameraLensDirection camDirec = CameraLensDirection.front;
  bool isBusy = false;
  late Size size;
  late FaceDetector detector;
  late Recognizer recognizer;
  CameraImage? frame;
  img.Image? image;
  late List<RecognitionEmbedding> recognitions = [];
  dynamic _scanResults;

  @override
  void initState() {
    super.initState();
    detector = FaceDetector(
        options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));
    recognizer = Recognizer();
    _initializeCamera();
  }

  _initializeCamera() async {
    _availableCameras = await availableCameras();
    _controller = CameraController(description, ResolutionPreset.high);
    await _controller!.initialize().then((_) {
      if (!mounted) return;
      size = _controller!.value.previewSize!;
      _controller!.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          frame = image;
          Future.delayed(Duration(milliseconds: 500), () {
            doFaceDetectionOnFrame();
          });
        }
      });
    });
  }

  InputImage getInputImage() {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in frame!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize =
        Size(frame!.width.toDouble(), frame!.height.toDouble());
    final camera = description;
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(frame!.format.raw);
    final int bytesPerRow =
        frame?.planes.isNotEmpty == true ? frame!.planes.first.bytesPerRow : 0;

    final inputImageMetaData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation!,
      format: inputImageFormat!,
      bytesPerRow: bytesPerRow,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, metadata: inputImageMetaData);

    return inputImage;
  }

  img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yRowStride = cameraImage.planes[0].bytesPerRow;
    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: width, height: height);

    for (var w = 0; w < width; w++) {
      for (var h = 0; h < height; h++) {
        final uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final index = h * width + w;
        final yIndex = h * yRowStride + w;

        final y = cameraImage.planes[0].bytes[yIndex];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data!.setPixelR(w, h, yuv2rgb(y, u, v));
      }
    }
    return image;
  }

  int yuv2rgb(int y, int u, int v) {
    var r = (y + v * 1436 / 1024 - 179).round();
    var g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    var b = (y + u * 1814 / 1024 - 227).round();
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);
    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }

  doFaceDetectionOnFrame() async {
    InputImage inputImage = getInputImage();
    List<Face> faces = await detector.processImage(inputImage);
    performFaceRecognition(faces);
  }

  performFaceRecognition(List<Face> faces) async {
    recognitions.clear();
    image = convertYUV420ToImage(frame!);
    image = img.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());
      RecognitionEmbedding recognition =
          recognizer.recognize(croppedFace, face.boundingBox);
      recognitions.add(recognition);

      // Show face registration dialogue
      showFaceRegistrationDialogue(croppedFace, recognition);
    }

    setState(() {
      isBusy = false;
      _scanResults = recognitions;
    });
  }

  void showFaceRegistrationDialogue(
      img.Image croppedFace, RecognitionEmbedding recognition) {
    if (!mounted) return; // Ensure widget is still in the widget tree
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.memory(
                Uint8List.fromList(img.encodeBmp(croppedFace)),
                width: 200,
                height: 200,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: BlocConsumer<UpdateUserRegisterFaceBloc,
                    UpdateUserRegisterFaceState>(
                  listener: (context, state) {
                    state.maybeWhen(
                      orElse: () {},
                      error: (message) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      },
                      success: (data) {
                        AuthLocalDatasource().updateAuthData(data);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainPage()));
                      },
                    );
                  },
                  builder: (context, state) {
                    return state.maybeWhen(
                      orElse: () {
                        return ElevatedButton(
                          onPressed: () {
                            context.read<UpdateUserRegisterFaceBloc>().add(
                                UpdateUserRegisterFaceEvent
                                    .updateProfileRegisterFace(
                                        recognition.embedding.join(','), null));
                          },
                          child: const Text('Register'),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _reverseCamera() async {
    camDirec = camDirec == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    description = camDirec == CameraLensDirection.back
        ? _availableCameras![0]
        : _availableCameras![1];
    _initializeCamera();
  }

  Widget buildResult() {
    if (_scanResults == null || !_controller!.value.isInitialized) {
      return const Center(child: Text('Camera is not initialized'));
    }
    final Size imageSize = Size(
      _controller!.value.previewSize!.height,
      _controller!.value.previewSize!.width,
    );
    CustomPainter painter =
        FaceDetectorPainter(imageSize, _scanResults, camDirec);
    return CustomPaint(painter: painter);
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0.0,
              left: 0.0,
              width: size.width,
              height: size.height,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              width: size.width,
              height: size.height,
              child: buildResult(),
            ),
            Positioned(
              bottom: 5.0,
              left: 0.0,
              right: 0.0,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _reverseCamera,
                      icon: Icon(Icons.camera_rear, size: 48.0),
                    ),
                    const Spacer(),
                    // Removed the shutter button
                    const Spacer(),
                    const SizedBox(width: 48.0)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
