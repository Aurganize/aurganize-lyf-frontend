import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Lock to portrait. The product is a thumb-touch-driver planner; landscape adds
  // zero value for v1.0 and created an extra layout surface to maintain.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Edge-to-edge status bar with transparent background. The status bar
  // icons should be dark over our light surfaces.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
        child: AurganizeLyfApp(),
    ),
  );
}