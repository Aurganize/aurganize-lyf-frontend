import 'package:flutter/material.dart';

class AurganizeLyfApp extends StatelessWidget {
  const AurganizeLyfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurganize Lyf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F6E56),
            brightness: Brightness.light,
        )
      ),
      home: const _BootStrapScreen(),
    );
  }
}

class _BootStrapScreen extends StatelessWidget {
  const _BootStrapScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Aurganize Lyf',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Bootstrap Ok.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
                ),
              ],
            ),
          )
      ),
    );
  }
}