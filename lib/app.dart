import 'package:flutter/material.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Assistant',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      home: const Scaffold(
        body: Center(child: Text('Gym Assistant', style: TextStyle(fontSize: 28))),
      ),
    );
  }
}
