import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../helper/global.dart';
import '../helper/pref.dart';
import '../model/home_type.dart';
import '../widget/home_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // final _isDarkMode = Pref.isDarkMode.obs;
  final _isDarkMode = Get.isDarkMode.obs; //bug fix

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    Pref.showOnboarding = false;
  }

  @override
  Widget build(BuildContext context) {
    //initializing device size
    mq = MediaQuery.sizeOf(context);

    //sample api call
    // APIs.getAnswer('hii');

    return Scaffold(
      //app bar
      appBar: AppBar(
        title: const Text(appName),

        //
        actions: [
          IconButton(
              padding: const EdgeInsets.only(right: 10),
              onPressed: () {
                Get.changeThemeMode(
                    _isDarkMode.value ? ThemeMode.light : ThemeMode.dark);

                _isDarkMode.value = !_isDarkMode.value;
                Pref.isDarkMode = _isDarkMode.value;
              },
              icon: Obx(() => Icon(
                  _isDarkMode.value
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 26)))
        ],
      ),

      //ad
      // bottomNavigationBar: AdHelper.nativeBannerAd(),

      //body
      body: ListView(
        padding: EdgeInsets.only(
          top: mq.height * .03, // Adjust this value to add space at the top
          left: mq.width * .04,
          right: mq.width * .04,
          bottom: mq.height * .015,
        ),
        children: HomeType.values.map((e) => HomeCard(homeType: e)).toList(),
      ),
    );
  }
}
