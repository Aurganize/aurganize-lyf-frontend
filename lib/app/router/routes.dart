/// Path constants for the app's routes.
///
/// Always reference paths via this class; never hand-write `/plan/...`
/// at a call site. The string-literal approach has burnt every
/// codebase that's tried it.
abstract final class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String onboarding = '/onboarding';
  static const String confirm = '/confirm';     // base, parameterized at use
  static const String plan = '/plan';            // base, parameterized at use
  static const String leftover = '/leftover';   // base, parameterized at use
  static const String settings = '/settings';
}