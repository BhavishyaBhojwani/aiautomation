import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart';
import 'package:translator_plus/translator_plus.dart';
import 'package:http/http.dart' as http;

import '../helper/global.dart';

class APIs {
  //get answer from google gemini ai
  // static Future<String> getAnswer(String question) async {
  //   try {
  //     log('api key: $apiKey');

  //     final model = GenerativeModel(
  //       model: 'gemini-1.5-flash',
  //       apiKey: apiKey,
  //     );

  //     final content = [Content.text(question)];
  //     final res = await model.generateContent(content, safetySettings: [
  //       SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  //       SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
  //       SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
  //       SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
  //     ]);

  //     log('res: ${res.text}');

  //     return res.text!;
  //   } catch (e) {
  //     log('getAnswerGeminiE: $e');
  //     return 'Something went wrong (Try again in sometime)';
  //   }
  // }

  // get answer from chat gpt
  static Future<String> getAnswer(String question) async {
    try {
      log('api key: $apiKey');

      //
      final res =
          await post(Uri.parse('https://api.openai.com/v1/chat/completions'),

              //headers
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader: 'Bearer $apiKey'
              },

              //body
              body: jsonEncode({
                "model": "gpt-4-turbo",
                "max_tokens": 2000,
                "temperature": 0,
                "messages": [
                  {"role": "user", "content": question},
                ]
              }));

      final data = jsonDecode(res.body);

      log('res: $data');
      return data['choices'][0]['message']['content'];
    } catch (e) {
      log('getAnswerGptE: $e');
      return 'Something went wrong (Try again in sometime)';
    }
  }

  // static Future<List<String>> searchAiImages(String prompt) async {
  //   try {
  //     final res =
  //         await get(Uri.parse('https://lexica.art/api/v1/search?q=$prompt'));

  //     final data = jsonDecode(res.body);

  //     //
  //     return List.from(data['images']).map((e) => e['src'].toString()).toList();
  //   } catch (e) {
  //     log('searchAiImagesE: $e');
  //     return [];
  //   }
  // }

  static Future<List<String>> generateAiImages(String prompt) async {
    try {
      // Make a POST request to OpenAI's image generation endpoint
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
        },
        body: jsonEncode({
          "prompt": prompt, // Description of the image you want to generate
          "n": 4, // Number of images to generate
          "size":
              "1024x1024" // Image resolution (options: 256x256, 512x512, 1024x1024)
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract the image URLs from the response
        return List<String>.from(data['data'].map((e) => e['url'].toString()));
      } else {
        log('Error generating images: ${response.body}');
        return [];
      }
    } catch (e) {
      log('generateAiImagesE: $e');
      return [];
    }
  }

  static Future<String> speechToText(File audioFile) async {
    try {
      // API Endpoint for Whisper
      final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

      // Prepare the request
      final request = http.MultipartRequest('POST', url)
        ..headers[HttpHeaders.authorizationHeader] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-1'
        ..fields['language'] =
            'en' // Optional: Specify language (e.g., 'en' for English)
        ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

      // Send the request
      final response = await request.send();

      // Handle the response
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        log('Whisper response: $data');
        return data['text']; // Extract transcribed text
      } else {
        final errorResponse = await response.stream.bytesToString();
        log('Whisper Error: $errorResponse');
        return 'Error: Unable to transcribe audio.';
      }
    } catch (e) {
      log('speechToTextE: $e');
      return 'Something went wrong (Try again in sometime).';
    }
  }

  static Future<String> googleTranslate(
      {required String from, required String to, required String text}) async {
    try {
      final res = await GoogleTranslator().translate(text, from: from, to: to);

      return res.text;
    } catch (e) {
      log('googleTranslateE: $e ');
      return 'Something went wrong!';
    }
  }
}
