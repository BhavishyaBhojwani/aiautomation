import 'dart:convert';

import 'package:ai_assistant/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class TextToSpeech extends StatefulWidget {
  const TextToSpeech({super.key});

  @override
  State<TextToSpeech> createState() => _TextToSpeechState();
}

class _TextToSpeechState extends State<TextToSpeech> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSpeaking = false;
  bool _isLoading = false;

  final List<Map<String, String>> _messages = [];

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Future<void> _speak(String text) async {
  //   if (text.isNotEmpty) {
  //     setState(() => _isSpeaking = true);
  //     await _flutterTts.speak(text);
  //     _flutterTts.setCompletionHandler(() {
  //       setState(() => _isSpeaking = false);
  //     });
  //   }
  // }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      // Preprocess text to minimize long pauses at dots
      final processedText =
          text.replaceAll('. ', '.'); // Shorten pauses at periods

      // Update state to indicate speaking has started
      setState(() => _isSpeaking = true);

      // Set speech settings (optional, adjust as needed)
      await _flutterTts
          .setSpeechRate(0.5); // Adjust speed (0.5 for moderate speed)
      await _flutterTts.setPitch(1.0); // Normal pitch
      await _flutterTts.setVolume(1.0); // Full volume

      // Start speaking the processed text
      await _flutterTts.speak(processedText);

      // Set a completion handler to update the state when speaking ends
      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<String> _getAnswerFromChatGPT(String prompt) async {
    const apiKey =
        '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';
    const apiUrl = 'https://api.openai.com/v1/chat/completions';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'system', 'content': 'You are an AI assistant.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No response';
      } else {
        throw Exception('Failed to fetch answer: ${response.body}');
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  // Future<void> _sendTextForSpeech() async {
  //   final text = _textController.text.trim();
  //   if (text.isNotEmpty) {
  //     _messages.add({'role': 'user', 'content': text});
  //     _textController.clear();
  //     setState(() {});
  //     _scrollToBottom();

  //     // Call API to get answer
  //     setState(() => _isLoading = true);
  //     final response = await _getAnswerFromChatGPT(text);
  //     setState(() => _isLoading = false);

  //     // Add response to messages
  //     _messages.add({'role': 'ai', 'content': response});
  //     setState(() {});
  //     _scrollToBottom();

  //     // Automatically speak AI response
  //     _speak(response);
  //   }
  // }

  Future<void> _sendTextForSpeech() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      // Add user message
      _messages.add({'role': 'user', 'content': text});
      _textController.clear();
      setState(() {});
      _scrollToBottom();

      // Call API to get answer
      setState(() => _isLoading = true);
      final response = await _getAnswerFromChatGPT(text);
      setState(() => _isLoading = false);

      // Automatically speak AI response immediately
      _speak(response);

      // Add response to messages
      _messages.add({'role': 'ai', 'content': response});
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech AI Assistant'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: TextFormField(
                controller: _textController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  filled: true,
                  isDense: true,
                  hintText: 'Type your text here...',
                  hintStyle: const TextStyle(fontSize: 14),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Microphone button
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  _isSpeaking ? Colors.red : Theme.of(context).buttonColor,
              child: IconButton(
                onPressed: _isSpeaking ? _stopSpeaking : _sendTextForSpeech,
                icon: Icon(
                  _isSpeaking ? Icons.mic_off : Icons.send,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Chat messages
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            controller: _scrollController,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Text(
                          message['content']!,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      if (!isUser)
                        IconButton(
                          icon:
                              const Icon(Icons.volume_up, color: Colors.black),
                          onPressed: () => _speak(message['content']!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
