import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:talk24loves/app_theme_controller.dart';
import 'package:talk24loves/components/app_colors.dart';
import 'package:talk24loves/firebase_options.dart';
import 'package:talk24loves/screens/phone_login_screen.dart';

void main() async {
  Get.put(ThemeController());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return GetMaterialApp(
      title: 'Amour - Private Audio & Video Talk',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBgMid,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPink,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBgTop,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPink,
          brightness: Brightness.dark,
          surface: AppColors.darkCard,
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
