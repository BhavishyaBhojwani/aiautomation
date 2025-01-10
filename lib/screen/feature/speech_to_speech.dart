import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';

class SpeechToSpeechTranslation extends StatefulWidget {
  const SpeechToSpeechTranslation({super.key});

  @override
  State<SpeechToSpeechTranslation> createState() =>
      _SpeechToSpeechTranslationState();
}

class _SpeechToSpeechTranslationState extends State<SpeechToSpeechTranslation> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxList<Map<String, String>> _messages = <Map<String, String>>[].obs;
  bool _isListening = false;
  String _transcription = '';

  Future<void> _respondToQuery(String query) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      const apiKey =
          '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';

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': query}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];

        log('Answer: $answer');

        // Add the response to the message list
        _messages.add({'role': 'assistant', 'content': answer});

        // Use Text-to-Speech to speak the response
        await _tts
            .setLanguage("en-US"); // Adjust as needed for the response language
        await _tts.speak(answer);
      } else {
        log('Error: ${response.body}');
        _messages.add({
          'role': 'assistant',
          'content': 'Error: Unable to retrieve the answer.'
        });
      }
    } catch (e) {
      log('Error: $e');
      _messages.add({
        'role': 'assistant',
        'content': 'Something went wrong. Please try again later.'
      });
    }
  }

  //Live Typing Code
  // Future<void> _respondToQuery(String query) async {
  //   try {
  //     final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  //     final apiKey =
  //         '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';
  //     ;

  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $apiKey',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         'model': 'gpt-4',
  //         'messages': [
  //           {'role': 'user', 'content': query}
  //         ],
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       final fullAnswer = data['choices'][0]['message']['content'];

  //       log('Answer: $fullAnswer');

  //       // Add a placeholder for the assistant's response
  //       _messages.add({'role': 'assistant', 'content': ''});

  //       // Typing effect: show one character at a time
  //       int index = _messages.length - 1; // Index of the assistant's response
  //       String currentText = '';

  //       for (int i = 0; i < fullAnswer.length; i++) {
  //         await Future.delayed(
  //             const Duration(milliseconds: 50)); // Adjust typing speed
  //         currentText += fullAnswer[i];
  //         _messages[index] = {'role': 'assistant', 'content': currentText};
  //       }

  //       // Use Text-to-Speech to speak the final response
  //       await _tts
  //           .setLanguage("en-US"); // Adjust as needed for the response language
  //       await _tts.speak(fullAnswer);
  //     } else {
  //       log('Error: ${response.body}');
  //       _messages.add({
  //         'role': 'assistant',
  //         'content': 'Error: Unable to retrieve the answer.'
  //       });
  //     }
  //   } catch (e) {
  //     log('Error: $e');
  //     _messages.add({
  //       'role': 'assistant',
  //       'content': 'Something went wrong. Please try again later.'
  //     });
  //   }
  // }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => log('Speech Status: $status'),
      onError: (error) => log('Speech Error: $error'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _transcription = result.recognizedWords;
          _textController.text = _transcription;
        });
      });
    } else {
      log('The user has denied the use of speech recognition.');
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);

    if (_transcription.isNotEmpty) {
      _messages.add({'role': 'user', 'content': _transcription});
      _respondToQuery(_transcription);
      _transcription = '';
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Speech Translator'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _isListening ? Colors.red : Colors.blue,
            child: IconButton(
              icon: Icon(
                _isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chat messages
          Obx(
            () => ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
                    child: Text(
                      message['content']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Lottie animation when mic is on
          if (_isListening)
            Center(
              child: Lottie.asset(
                'assets/lottie/lottie_simple.json',
                width: 150,
                height: 150,
              ),
            ),
        ],
      ),
    );
  }
}
