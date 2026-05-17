// test/features/auth/auth_providers_test.dart
import 'package:aurganize_lyf/features/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Reset the SharedPreferences mock between tests so persistence is
  // observable in isolation.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('mints a UUID on first call and persists it', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final String firstId = await container.read(currentUserIdProvider.future);
    expect(firstId, isNotEmpty);
    expect(firstId.length, 36); // UUIDv4
    expect(firstId.split('-').length, 5);
  });

  test('returns the same id on subsequent reads', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final String firstId = await container.read(currentUserIdProvider.future);
    final String secondId = await container.read(currentUserIdProvider.future);
    expect(firstId, secondId);
  });

  test('persists across container disposals', () async {
    final ProviderContainer first = ProviderContainer();
    final String idA = await first.read(currentUserIdProvider.future);
    first.dispose();

    final ProviderContainer second = ProviderContainer();
    addTearDown(second.dispose);
    final String idB = await second.read(currentUserIdProvider.future);

    expect(idA, idB);
  });

  test('currentUserIdSync throws before the async resolves', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
          () => container.read(currentUserIdSyncProvider),
      throwsA(isA<StateError>()),
    );
  });

  test('currentUserIdSync returns the value after the async resolves',
          () async {
        final ProviderContainer container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(currentUserIdProvider.future);
        final String sync = container.read(currentUserIdSyncProvider);
        expect(sync, isNotEmpty);
        expect(sync.length, 36);
      });
}