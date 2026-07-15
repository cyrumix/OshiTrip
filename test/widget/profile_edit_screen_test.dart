import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/social/application/social_providers.dart';
import 'package:oshi_trip/features/social/domain/profile.dart';
import 'package:oshi_trip/features/social/presentation/profile_edit_screen.dart';

import '../helpers/pump_screen.dart';

class _FakeProfileRepo implements ProfileRepository {
  _FakeProfileRepo({this.initial});
  final Profile? initial;
  int upsertCount = 0;
  String? lastDisplayName;
  bool? lastSearchable;

  @override
  Future<Result<Profile?>> fetchMyProfile() async => Ok(initial);

  @override
  Future<Result<Profile>> upsertMyProfile({
    required String displayName,
    String? bio,
    String? favoriteName,
    required bool acceptsFriendRequests,
    required bool searchable,
  }) async {
    upsertCount++;
    lastDisplayName = displayName;
    lastSearchable = searchable;
    return Ok(
      Profile(
        userId: 'me',
        displayName: displayName,
        bio: bio,
        favoriteName: favoriteName,
        acceptsFriendRequests: acceptsFriendRequests,
        searchable: searchable,
        createdAt: DateTime.utc(2026, 7, 11),
        updatedAt: DateTime.utc(2026, 7, 11),
      ),
    );
  }

  @override
  Future<Result<Profile?>> fetchProfile(String userId) async => const Ok(null);

  @override
  Future<Result<Map<String, Profile>>> fetchProfiles(
    List<String> userIds,
  ) async =>
      const Ok({});
}

Profile _profile(String name) => Profile(
      userId: 'me',
      displayName: name,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));

  Future<_FakeProfileRepo> pump(
    WidgetTester tester, {
    Profile? initial,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _FakeProfileRepo(initial: initial);
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const ProfileEditScreen(),
      extraOverrides: [
        profileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    return repo;
  }

  testWidgets('既存プロフィールが入力欄へ反映される', (tester) async {
    await pump(tester, initial: _profile('あさい'));
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, 'あさい');
  });

  testWidgets('表示名が空だと保存せず理由を表示する', (tester) async {
    final repo = await pump(tester, initial: _profile('あさい'));

    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.upsertCount, 0);
    expect(find.text('表示名を入力してください'), findsOneWidget);
  });

  testWidgets('有効な入力で保存すると upsert が呼ばれる', (tester) async {
    final repo = await pump(tester, initial: _profile('あさい'));

    await tester.enterText(find.byType(TextField).first, 'わたなべ');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.upsertCount, 1);
    expect(repo.lastDisplayName, 'わたなべ');
  });
}
