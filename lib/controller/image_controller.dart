import 'dart:developer';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../apis/apis.dart';
import '../helper/global.dart';
import '../helper/my_dialog.dart';

enum Status { none, loading, complete, error }

class ImageController extends GetxController {
  final textC = TextEditingController();

  final status = Status.none.obs;

  final url = ''.obs;

  final imageList = <String>[].obs;

  Future<void> createAIImage() async {
    if (textC.text.trim().isNotEmpty) {
      OpenAI.apiKey = apiKey;
      status.value = Status.loading;

      OpenAIImageModel image = await OpenAI.instance.image.create(
        prompt: textC.text,
        n: 1,
        size: OpenAIImageSize.size512,
        responseFormat: OpenAIImageResponseFormat.url,
      );
      url.value = image.data[0].url.toString();

      status.value = Status.complete;
    } else {
      MyDialog.info('Provide some beautiful image description!');
    }
  }

  void downloadImage() async {
    try {
      //To show loading
      MyDialog.showLoadingDialog();

      log('url: $url');

      final bytes = (await get(Uri.parse(url.value))).bodyBytes;
      final dir = await getTemporaryDirectory();

      final file = await File('${dir.path}/ai_image.png').writeAsBytes(bytes);

      log('filePath: ${file.path}');
      //save image to gallery
      await GallerySaver.saveImage(file.path, albumName: appName)
          .then((success) {
        //hide loading
        Get.back();

        MyDialog.success('Image Downloaded to Gallery!');
      });
    } catch (e) {
      //hide loading
      Get.back();
      MyDialog.error('Something Went Wrong (Try again in sometime)!');
      log('downloadImageE: $e');
    }
  }

  void shareImage() async {
    try {
      //To show loading
      MyDialog.showLoadingDialog();

      log('url: $url');

      final bytes = (await get(Uri.parse(url.value))).bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/ai_image.png').writeAsBytes(bytes);

      log('filePath: ${file.path}');

      //hide loading
      Get.back();

      await Share.shareXFiles([XFile(file.path)],
          text:
              'Check out this Amazing Image created by Ai Assistant App by Harsh H. Rajpurohit');
    } catch (e) {
      //hide loading
      Get.back();
      MyDialog.error('Something Went Wrong (Try again in sometime)!');
      log('downloadImageE: $e');
    }
  }

  // Future<void> searchAiImage() async {
  //   //if prompt is not empty
  //   if (textC.text.trim().isNotEmpty) {
  //     status.value = Status.loading;

  //     imageList.value = await APIs.searchAiImages(textC.text);

  //     if (imageList.isEmpty) {
  //       MyDialog.error('Something went wrong (Try again in sometime)');

  //       return;
  //     }

  //     url.value = imageList.first;

  //     status.value = Status.complete;
  //   } else {
  //     MyDialog.info('Provide some beautiful image description!');
  //   }
  // }

  Future<void> generateAiImage() async {
    // Check if the prompt is not empty
    if (textC.text.trim().isNotEmpty) {
      status.value = Status.loading;

      // Call the generateAiImages function
      final generatedImages = await APIs.generateAiImages(textC.text);

      if (generatedImages.isEmpty) {
        // Show an error dialog if no images are generated
        MyDialog.error('Something went wrong (Try again in sometime)');
        status.value = Status.error; // Update status to error
        return;
      }

      // Update the image list and set the first image URL
      imageList.value = generatedImages;
      url.value = generatedImages.first;

      status.value = Status.complete; // Update status to complete
    } else {
      // Show a message if the prompt is empty
      MyDialog.info('Provide some beautiful image description!');
    }
  }
}
