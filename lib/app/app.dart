import 'package:aurganize_lyf/core/theme/app_colors.dart';
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
        scaffoldBackgroundColor: AppColors.surfacePrimary,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F6E56),
            brightness: Brightness.light,
        ),
      ),
      home: const _ColorPaletteScreen(),
    );
  }
}

class _ColorPaletteScreen extends StatelessWidget {
  const _ColorPaletteScreen();

  @override
  Widget build(BuildContext context) {
    final List<_Swatch> swatches = <_Swatch>[
      const _Swatch('brand.primary', AppColors.brandPrimary, AppColors.surfacePrimary),
      const _Swatch('brand.dark', AppColors.brandDark, AppColors.surfacePrimary),
      const _Swatch('brand.light', AppColors.brandLight, AppColors.textPrimary),
      const _Swatch('surface.primary', AppColors.surfacePrimary, AppColors.textPrimary),
      const _Swatch('surface.secondary', AppColors.surfaceSecondary, AppColors.textPrimary),
      const _Swatch('surface.tertiary', AppColors.surfaceTertiary, AppColors.textPrimary),
      const _Swatch('text.primary', AppColors.textPrimary, AppColors.surfacePrimary),
      const _Swatch('text.secondary', AppColors.textSecondary, AppColors.surfacePrimary),
      const _Swatch('text.tertiary', AppColors.textTertiary, AppColors.surfacePrimary),
      const _Swatch('border.default', AppColors.borderDefault, AppColors.textPrimary),
      const _Swatch('border.strong', AppColors.borderStrong, AppColors.textPrimary),
      const _Swatch('temp.hot', AppColors.tempHot, AppColors.surfacePrimary),
      const _Swatch('temp.warm', AppColors.tempWarm, AppColors.surfacePrimary),
      const _Swatch('temp.cool', AppColors.tempCool, AppColors.surfacePrimary),
      const _Swatch('attention.coral.bg', AppColors.attentionCoralBackground, AppColors.attentionCoralForeground),
      const _Swatch('attention.amber.bg', AppColors.attentionAmberBackground, AppColors.attentionAmberForeground)
    ];

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('Color tokens'),
        backgroundColor: AppColors.surfacePrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: swatches.length,
        separatorBuilder: (_,__) => const SizedBox(height: 8,),
        itemBuilder: (BuildContext context, int index) {
          final _Swatch s =swatches[index];
          return Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: s.color,
              borderRadius:  BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderDefault, width: 0.5),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              s.label,
              style: TextStyle(
                color: s.textOn,
                fontWeight: FontWeight.w500
              ),
            ),
          );
        },
    ),
    );
  }
}





class _Swatch {
  const _Swatch(this.label, this.color, this.textOn);
  final String label;
  final Color color;
  final Color textOn;
}

// class _BootStrapScreen extends StatelessWidget {
//   const _BootStrapScreen();
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Text(
//                   'Aurganize Lyf',
//                   style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Bootstrap Ok.',
//                   style: TextStyle(fontSize: 14, color: Color(0xFF6B6B6B)),
//                 ),
//               ],
//             ),
//           ),
//       ),
//     );
//   }
// }