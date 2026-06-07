import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const IRegApp());
}

class IRegApp extends StatelessWidget {
  const IRegApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iReg',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
