import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants/app_colors.dart';
import 'screens/calc_screen.dart';
//wassup
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const QuickCalcApp());
}

class QuickCalcApp extends StatelessWidget {
  const QuickCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickCalc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      home: const CalcScreen(),
    );
  }
}