import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechToTextFeature extends StatefulWidget {
  const SpeechToTextFeature({super.key});

  @override
  State<SpeechToTextFeature> createState() => _SpeechToTextFeatureState();
}

class _SpeechToTextFeatureState extends State<SpeechToTextFeature> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxList<Map<String, String>> _messages = <Map<String, String>>[].obs;
  bool _isListening = false;
  String _transcription = '';

  Future<void> _sendToChatGPT(String text) async {
    try {
      // Replace with your ChatGPT API endpoint and key
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final apiKey =
          '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';
      ;

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo',
          'messages': [
            {'role': 'user', 'content': text}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];

        log('ChatGPT Response: $reply');

        _messages.add({'role': 'assistant', 'content': reply});
      } else {
        log('Error: ${response.body}');
        _messages.add(
            {'role': 'assistant', 'content': 'Error: Unable to get response.'});
      }
    } catch (e) {
      log('Error: $e');
      _messages.add({
        'role': 'assistant',
        'content': 'Something went wrong. Please try again later.'
      });
    }
  }

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
      _sendToChatGPT(_transcription);
      _transcription = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text AI Assistant'),
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
      body: Obx(
        () => ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            final isUser = message['role'] == 'user';

            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}
