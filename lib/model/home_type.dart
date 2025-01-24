import 'package:ai_assistant/screen/feature/image_ulltra.dart';
import 'package:ai_assistant/screen/feature/speech_to_speech.dart';
import 'package:ai_assistant/screen/feature/speech_to_text_feature.dart';
import 'package:ai_assistant/screen/feature/text_to_speech.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../screen/feature/chatbot_feature.dart';
import '../screen/feature/image_feature.dart';
import '../screen/feature/translator_feature.dart';

enum HomeType {
  aiChatBot,
  aiImage,
  aiTranslator,
  aiSpeechToText,
  aiTextToSpeech,
  aiSpeechToSpeech,
  aiImageGenerator,
}

extension MyHomeType on HomeType {
  //title
  String get title => switch (this) {
        HomeType.aiChatBot => 'Text to Text',
        HomeType.aiImage => 'AI Image Creator',
        HomeType.aiTranslator => 'Language Translator',
        HomeType.aiSpeechToText => 'Speech to Text',
        HomeType.aiTextToSpeech => 'Text to Speech',
        HomeType.aiSpeechToSpeech => 'Speech to Speech',
        HomeType.aiImageGenerator => 'Image Generator',
      };

  //lottie
  String get lottie => switch (this) {
        HomeType.aiChatBot => 'ai_hand_waving.json',
        HomeType.aiImage => 'ai_play.json',
        HomeType.aiTranslator => 'ai_ask_me.json',
        HomeType.aiSpeechToText => 'ai_speech_to_text.json',
        HomeType.aiTextToSpeech => 'ai_text_to_speech.json',
        HomeType.aiSpeechToSpeech => 'ai_speech-to_speech.json',
        HomeType.aiImageGenerator => 'ai_play.json',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        HomeType.aiChatBot => true,
        HomeType.aiImage => false,
        HomeType.aiTranslator => true,
        HomeType.aiSpeechToText => false,
        HomeType.aiTextToSpeech => true,
        HomeType.aiSpeechToSpeech => false,
        HomeType.aiImageGenerator => true,
      };

  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.aiChatBot => EdgeInsets.zero,
        HomeType.aiImage => const EdgeInsets.all(20),
        HomeType.aiTranslator => EdgeInsets.zero,
        HomeType.aiSpeechToText => const EdgeInsets.all(20),
        HomeType.aiTextToSpeech => const EdgeInsets.all(20),
        HomeType.aiSpeechToSpeech => const EdgeInsets.all(20),
        HomeType.aiImageGenerator => const EdgeInsets.all(20),
      };

  //for navigation
  VoidCallback get onTap => switch (this) {
        HomeType.aiChatBot => () => Get.to(() => const ChatBotFeature()),
        HomeType.aiImage => () => Get.to(() => const ImageFeature()),
        HomeType.aiTranslator => () => Get.to(() => const TranslatorFeature()),
        HomeType.aiSpeechToText => () =>
            Get.to(() => const SpeechToTextFeature()),
        HomeType.aiTextToSpeech => () => Get.to(() => const TextToSpeech()),
        HomeType.aiSpeechToSpeech => () =>
            Get.to(() => const SpeechToSpeechTranslation()),
        HomeType.aiImageGenerator => () => Get.to(() => const ImageUltra()),
      };
}
