import 'package:aurganize_lyf/core/theme/app_colors.dart';
import 'package:aurganize_lyf/core/theme/app_typography.dart';
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
      home: const _TypeScaleStream(),
    );
  }
}

class _TypeScaleStream extends StatelessWidget {
  const _TypeScaleStream();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text('Aurganize Lyf', style: AppTypography.display,),
              const SizedBox(height: 24,),
              Text('Title - 22/28/500', style: AppTypography.title,),
              const SizedBox(height: 16,),
              Text('Heading - 17/24/500', style: AppTypography.heading,),
              const SizedBox(height: 16,),
              Text(
                'Body - 14/20/400. This is the workhorse text style used for'
                'plan item titles, conversation bubbles, and primary body.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 16,),
              Text(
                'Body 2 - 13/18/400. Used for notification body and settings rows.',
                style: AppTypography.body2,
              ),
              const SizedBox(height: 16,),
              Text(
                'Caption - 11/15/400. Sub-labels and helper text.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 16,),
              Text(
                'EYEBROW - 10/14/500 +0.5 SP',
                style: AppTypography.eyebrow,
              ),
              const SizedBox(height: 24,),
              const Divider(),
              const SizedBox(height: 24,),
              Text(
                'bodyMuted variant - used for brand-colored action labels.',
                style: AppTypography.bodyMuted,
              ),
              const SizedBox(height: 8,),
              Text(
                'bodyBrand variant - used for brand-colored action labels.',
                style: AppTypography.bodyBrand,
              ),
              const SizedBox(height: 8,),
              Container(
                color: AppColors.brandPrimary,
                padding: const EdgeInsets.all(8),
                child: Text(
                  'bodyOnBrand - used on brand-filled surfaces like the floating island.',
                  style: AppTypography.bodyOnBrand,
                ),
              ),
              const SizedBox(height: 8,),
              Text(
                'bodyStrikethrough - used on completed children in the project view',
                style: AppTypography.bodyStrikethrough,
              ),
            ],
          ),
      ),
    );
  }
}



//
// class _ColorPaletteScreen extends StatelessWidget {
//   const _ColorPaletteScreen();
//
//   @override
//   Widget build(BuildContext context) {
//     final List<_Swatch> swatches = <_Swatch>[
//       const _Swatch('brand.primary', AppColors.brandPrimary, AppColors.surfacePrimary),
//       const _Swatch('brand.dark', AppColors.brandDark, AppColors.surfacePrimary),
//       const _Swatch('brand.light', AppColors.brandLight, AppColors.textPrimary),
//       const _Swatch('surface.primary', AppColors.surfacePrimary, AppColors.textPrimary),
//       const _Swatch('surface.secondary', AppColors.surfaceSecondary, AppColors.textPrimary),
//       const _Swatch('surface.tertiary', AppColors.surfaceTertiary, AppColors.textPrimary),
//       const _Swatch('text.primary', AppColors.textPrimary, AppColors.surfacePrimary),
//       const _Swatch('text.secondary', AppColors.textSecondary, AppColors.surfacePrimary),
//       const _Swatch('text.tertiary', AppColors.textTertiary, AppColors.surfacePrimary),
//       const _Swatch('border.default', AppColors.borderDefault, AppColors.textPrimary),
//       const _Swatch('border.strong', AppColors.borderStrong, AppColors.textPrimary),
//       const _Swatch('temp.hot', AppColors.tempHot, AppColors.surfacePrimary),
//       const _Swatch('temp.warm', AppColors.tempWarm, AppColors.surfacePrimary),
//       const _Swatch('temp.cool', AppColors.tempCool, AppColors.surfacePrimary),
//       const _Swatch('attention.coral.bg', AppColors.attentionCoralBackground, AppColors.attentionCoralForeground),
//       const _Swatch('attention.amber.bg', AppColors.attentionAmberBackground, AppColors.attentionAmberForeground)
//     ];
//
//     return Scaffold(
//       backgroundColor: AppColors.surfacePrimary,
//       appBar: AppBar(
//         title: const Text('Color tokens'),
//         backgroundColor: AppColors.surfacePrimary,
//         foregroundColor: AppColors.textPrimary,
//         elevation: 0,
//       ),
//       body: ListView.separated(
//         padding: const EdgeInsets.all(16),
//         itemCount: swatches.length,
//         separatorBuilder: (_,__) => const SizedBox(height: 8,),
//         itemBuilder: (BuildContext context, int index) {
//           final _Swatch s =swatches[index];
//           return Container(
//             height: 56,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: s.color,
//               borderRadius:  BorderRadius.circular(10),
//               border: Border.all(color: AppColors.borderDefault, width: 0.5),
//             ),
//             alignment: Alignment.centerLeft,
//             child: Text(
//               s.label,
//               style: TextStyle(
//                 color: s.textOn,
//                 fontWeight: FontWeight.w500
//               ),
//             ),
//           );
//         },
//     ),
//     );
//   }
// }
//
//
//
//
//
// class _Swatch {
//   const _Swatch(this.label, this.color, this.textOn);
//   final String label;
//   final Color color;
//   final Color textOn;
// }

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