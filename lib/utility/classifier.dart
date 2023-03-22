import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class Classifier {
  late Interpreter _interpreter;
  late ImageProcessor imageProcessor;
  late TensorImage inputImage;
  late List<Object> inputs;

  Interpreter get interpreter => _interpreter;

  Map<int, Object> outputs = {};
  TensorBuffer outputLocations = TensorBufferFloat([]);

  Stopwatch s = Stopwatch();

  int frameNo = 0;

  Classifier({Interpreter? interpreter}) {
    loadModel(interpreter: interpreter);
  }

  void printDebugData() {
    debugPrint(
        "Frame: $frameNo time: ${s.elapsedMilliseconds} type: ${inputImage.dataType} height: ${inputImage.height} width: ${inputImage.width}");
    printWrapped(parseLandmarkData().toString());
  }

  void printWrapped(String text) {
    final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
    pattern.allMatches(text).forEach((match) => debugPrint(match.group(0)));
  }

  void performOperations(image_lib.Image image) {
    s.start();
    if (Platform.isAndroid) {
      image = image_lib.copyRotate(image, 270);
      image = image_lib.flipHorizontal(image);
    }
    inputImage = TensorImage(TfLiteType.float32);
    inputImage.loadImage(image);
    inputImage = getProcessedImage();
    inputs = [inputImage.buffer];
    s.stop();
    frameNo += 1;
    // printDebugData();
    s.reset();
  }

  TensorImage getProcessedImage() {
    int padSize = max(inputImage.height, inputImage.width);
    imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(192, 192, ResizeMethod.BILINEAR))
        .build();

    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  Future runModel() async {
    Map<int, Object> outputs = {0: outputLocations.buffer};
    interpreter.runForMultipleInputs(inputs, outputs);
  }

  Future loadModel({Interpreter? interpreter}) async {
    try {
      _interpreter = interpreter ??
          await Interpreter.fromAsset(
            "models/movenet.tflite",
            options: InterpreterOptions()..threads = 4,
          );
    } catch (e) {
      debugPrint("Error while creating interpreter: $e");
    }

    // var outputTensors = interpreter.getOutputTensors();
    // var inputTensors = interpreter.getInputTensors();
    // List<List<int>> _outputShapes = [];

    // outputTensors.forEach((tensor) {
    //   print("Output Tensor: " + tensor.toString());
    //   _outputShapes.add(tensor.shape);
    // });
    // inputTensors.forEach((tensor) {
    //   print("Input Tensor: " + tensor.toString());
    // });

    // print("------------------[A}========================\n" +
    //     _outputShapes.toString());

    outputLocations = TensorBufferFloat([1, 1, 17, 3]);
  }

  List parseLandmarkData() {
    List outputParsed = [];
    List<double> data = outputLocations.getDoubleList();
    List result = [];
    int x, y;
    double c;

    for (var i = 0; i < 51; i += 3) {
      y = (data[0 + i] * 640).toInt();
      x = (data[1 + i] * 480).toInt();
      c = (data[2 + i]);
      result.add([x, y, c]);
    }
    outputParsed = result;

    printWrapped(outputParsed.toString());

    return result;
  }
}
