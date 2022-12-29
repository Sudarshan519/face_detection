import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late CameraController cameraController;
  bool cameraInitialized = false;
  var running = false;
  var element;
  bool modelReady = false;
  loadModel() async {
    String? res = await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            true // defaults to false, set to true to use GPU delegate
        );
    modelReady = true;
  }

  loadCamera() async {
    String? res = await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );
    print(res! + "SUCCED");
    modelReady = true;
    var cameras = await availableCameras();
    cameraController = CameraController(cameras[1], ResolutionPreset.low);
    await cameraController.initialize().then((value) {
      cameraInitialized = true;
      setState(() {});
      cameraController.startImageStream(runModel);
    });
  }

  runModel(CameraImage img) async {
    if (running) return;
    running = true;
    var recognitions = await Tflite.runModelOnFrame(
        bytesList: img.planes.map((plane) {
          return plane.bytes;
        }).toList(), // required
        imageHeight: img.height,
        imageWidth: img.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true // defaults to true
        );
    element = recognitions;
    running = false;
    setState(() {});
    // for (var element in recognitions!) {
    //   print(element);
    // }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  close() async {
    await Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    loadCamera();
  }

  @override
  void dispose() {
    close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: <Widget>[
            if (cameraInitialized)
              Center(child: CameraPreview(cameraController)),
            Text(element.toString()),
            Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  element[0]["index"] == 0
                      ? "assets/camera_button_active.webp"
                      : "assets/camera_button_inactive.webp",
                  height: 80,
                  width: 80,
                  fit: BoxFit.fill,
                ))
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
