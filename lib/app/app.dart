import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/capture/providers/parse_worker.dart';
import 'router/app_router.dart';

class AurganizeLyfApp extends ConsumerStatefulWidget {
  const AurganizeLyfApp({super.key});

  @override
  ConsumerState<AurganizeLyfApp> createState() => _AurganizeLyfAppState();
}

class _AurganizeLyfAppState extends ConsumerState<AurganizeLyfApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parseWorkerProvider.notifier).ensureRunning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Aurganize lyf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}