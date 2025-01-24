import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ImageUltra extends StatefulWidget {
  const ImageUltra({super.key});

  @override
  State<ImageUltra> createState() => _ImageUltraState();
}

class _ImageUltraState extends State<ImageUltra> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxList<Map<String, dynamic>> _messages = <Map<String, dynamic>>[].obs;
  bool _isLoading = false;

  // Future<void> _generateImage(String prompt) async {
  //   const apiKey =
  //       "sk-oh4WJAqyyZoMIq2BwjNDrxTwswvQxZNaZdKALH0u3gCW9i0s"; // Replace with your API key
  //   const endpoint =
  //       "https://api.stability.ai/v2beta/stable-image/generate/sd3";

  //   try {
  //     setState(() {
  //       _isLoading = true;
  //     });

  //     final response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: {
  //         "Authorization": "Bearer $apiKey",
  //         "Accept": "image/*",
  //       },
  //       body: {
  //         "prompt": prompt,
  //         "output_format": "jpeg",
  //       },
  //     );

  //     if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
  //       // Save the image locally
  //       final directory = await getTemporaryDirectory();
  //       final imagePath =
  //           '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg';
  //       final file = File(imagePath);
  //       await file.writeAsBytes(response.bodyBytes);

  //       // Add the image to the message list
  //       _messages.add({'role': 'assistant', 'content': imagePath});
  //     } else {
  //       final errorMessage = response.body.isNotEmpty
  //           ? jsonDecode(response.body)['message'] ?? 'Unknown error occurred.'
  //           : 'Error generating image. Please try again.';
  //       _messages.add({'role': 'assistant', 'content': errorMessage});
  //     }
  //   } catch (e) {
  //     log('Error: $e');
  //     _messages.add({
  //       'role': 'assistant',
  //       'content': 'Something went wrong. Please try again later.',
  //     });
  //   } finally {
  //     setState(() {
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _generateImage(String prompt) async {
    const apiKey =
        "sk-oh4WJAqyyZoMIq2BwjNDrxTwswvQxZNaZdKALH0u3gCW9i0s"; // Replace with your valid API key
    const endpoint =
        "https://api.stability.ai/v2beta/stable-image/generate/ultra"; // Verify the endpoint

    try {
      setState(() {
        _isLoading = true;
      });

      // Use MultipartRequest for form-data
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest("POST", uri)
        ..headers["Authorization"] = "Bearer $apiKey"
        ..fields["prompt"] = prompt
        ..fields["output_format"] = "jpeg";

      final response = await request.send();

      if (response.statusCode == 200) {
        // Read response as bytes
        final responseBytes = await response.stream.toBytes();

        // Save the image locally
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpeg';
        final file = File(imagePath);
        await file.writeAsBytes(responseBytes);

        // Add the image to the message list
        _messages.add({'role': 'assistant', 'content': imagePath});
      } else {
        // Parse error response
        final responseString = await response.stream.bytesToString();
        final errorMessage = jsonDecode(responseString)['errors']?.join(', ') ??
            'Unknown error occurred.';
        _messages.add({'role': 'assistant', 'content': errorMessage});
      }
    } catch (e) {
      log('Error: $e');
      _messages.add({
        'role': 'assistant',
        'content': 'Something went wrong. Please try again later.',
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Ultra Generator'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isUser
                            ? Text(
                                message['content'],
                                style: const TextStyle(color: Colors.white),
                              )
                            : (message['content'].toString().endsWith('.jpeg')
                                ? Image.file(
                                    File(message['content']),
                                    fit: BoxFit.cover,
                                    width: 300,
                                    height: 300,
                                  )
                                : Text(
                                    message['content'],
                                    style: const TextStyle(color: Colors.black),
                                  )),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Enter image prompt...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () {
                      final prompt = _textController.text.trim();
                      if (prompt.isNotEmpty) {
                        _messages.add({'role': 'user', 'content': prompt});
                        _generateImage(prompt);
                        _textController.clear();
                      }
                    },
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
