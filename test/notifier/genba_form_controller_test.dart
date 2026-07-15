import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/auth/local_data_scope.dart';
import 'package:oshi_trip/core/db/app_database.dart';
import 'package:oshi_trip/core/providers.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/application/genba_form_controller.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/oshi/data/oshi_repository_impl.dart';
import 'package:oshi_trip/features/oshi/domain/oshi.dart';

import '../helpers/fake_oshi_repository.dart';
import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  final clock = FixedClock(DateTime(2026, 7, 2, 12));

  ProviderContainer createContainer({bool signedIn = true}) {
    final db = createTestDb();
    final container = ProviderContainer(
      overrides: [
        envProvider.overrideWithValue(demoEnv),
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);
    if (signedIn) {
      // デモモードのローカル認証でログインしておく
      container.read(authRepositoryProvider);
    }
    return container;
  }

  Future<void> signInDemo(ProviderContainer container) async {
    final result = await container
        .read(authRepositoryProvider)
        .signIn(email: 'demo@example.com', password: 'demo-pass');
    expect(result.isOk, isTrue);
  }

  test('必須項目が欠けている間は submit がバリデーション失敗を返す', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    final result = await notifier.submit();
    expect(result.failureOrNull?.message, contains('日付'));
  });

  test('入力途中の内容が下書き保存され、再オープンで復元される', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(artistName: '推しグループ', title: '夏ライブ'),
    );
    // 自動保存の書き込みを待つ
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // 画面を離れて再度開いた想定（provider を破棄して再構築）
    container.invalidate(genbaFormControllerProvider(null));
    final restored =
        await container.read(genbaFormControllerProvider(null).future);
    expect(restored.artistName, '推しグループ');
    expect(restored.title, '夏ライブ');
    expect(restored.restoredFromDraft, isTrue);
  });

  test('遠征する→交通・宿泊が「必要」になる。しない→「不要」', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.setExpedition(true);
    var state = container.read(genbaFormControllerProvider(null)).value!;
    expect(state.transportRequirement, RequirementStatus.required);
    expect(state.lodgingRequirement, RequirementStatus.required);

    notifier.setExpedition(false);
    state = container.read(genbaFormControllerProvider(null)).value!;
    expect(state.transportRequirement, RequirementStatus.notRequired);
    expect(state.lodgingRequirement, RequirementStatus.notRequired);
  });

  test('submit 成功で現場が保存され、下書きが消える', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(
        artistName: '推しグループ',
        title: '夏ライブ',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final all = await container.read(genbaRepositoryProvider).watchAll().first;
    expect(all.single.genba.title, '夏ライブ');

    // 下書きが消えている（再構築しても空のフォーム）
    container.invalidate(genbaFormControllerProvider(null));
    final fresh =
        await container.read(genbaFormControllerProvider(null).future);
    expect(fresh.title, isEmpty);
    expect(fresh.restoredFromDraft, isFalse);
  });

  test(
      '日程（公演日）を変更すると手動終演(manualEndedAt)は解除される'
      '（古い日程を前提にした値を持ち越さない, H-07）', () async {
    final container = createContainer();
    await signInDemo(container);
    // currentUserProvider（Stream由来）が実際に認証済みへ遷移するまで待つ。
    // authRepositoryProvider.signIn 自体は同期的に _current を更新するが、
    // それを watch している localDataScopeProvider 等はストリーム経由で
    // 1マイクロタスク遅れて反映されるため、直接 Repository を呼ぶこの
    // テストでは明示的に待つ必要がある（フォーム経由のテストは
    // GenbaFormController.build 内の await が暗黙にこれを行っている）。
    final user = await container.read(currentUserProvider.future);
    final ownerId = user!.id;

    // 手動終演済みの既存現場を用意する。
    final original = makeGenba(
      id: 'g-reschedule',
      ownerId: ownerId,
      eventDate: DateTime(2026, 6, 1),
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 21 * 60,
      manualEndedAt: DateTime(2026, 6, 1, 20, 30).toUtc(),
    );
    final upsert =
        await container.read(genbaRepositoryProvider).upsertGenba(original);
    expect(upsert.isOk, isTrue);

    final notifier =
        container.read(genbaFormControllerProvider('g-reschedule').notifier);
    await container.read(genbaFormControllerProvider('g-reschedule').future);

    // 日程を未来へ変更して保存する。
    notifier.mutate((s) => s.copyWith(eventDate: DateTime(2026, 9, 1)));
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final saved = await container
        .read(genbaRepositoryProvider)
        .watchById('g-reschedule')
        .first;
    expect(saved!.genba.eventDate, DateTime(2026, 9, 1));
    // 古い日程の手動終演を持ち越さない。再導出できる状態に戻る。
    expect(saved.genba.manualEndedAt, isNull);
  });

  test('日程を変更しない編集では手動終演(manualEndedAt)は保持される', () async {
    final container = createContainer();
    await signInDemo(container);
    final user = await container.read(currentUserProvider.future);
    final ownerId = user!.id;

    final manualEndedAt = DateTime(2026, 6, 1, 20, 30).toUtc();
    final original = makeGenba(
      id: 'g-keep',
      ownerId: ownerId,
      eventDate: DateTime(2026, 6, 1),
      startTimeMinutes: 18 * 60,
      endTimeMinutes: 21 * 60,
      manualEndedAt: manualEndedAt,
    );
    final upsert =
        await container.read(genbaRepositoryProvider).upsertGenba(original);
    expect(upsert.isOk, isTrue);

    final notifier =
        container.read(genbaFormControllerProvider('g-keep').notifier);
    await container.read(genbaFormControllerProvider('g-keep').future);

    // 会場だけ変更（日程は変えない）。
    notifier.mutate((s) => s.copyWith(venue: '新しい会場'));
    final result = await notifier.submit();
    expect(result.isOk, isTrue);

    final saved =
        await container.read(genbaRepositoryProvider).watchById('g-keep').first;
    expect(saved!.genba.venue, '新しい会場');
    expect(saved.genba.manualEndedAt, manualEndedAt);
  });

  test('会場のGoogle候補選択で会場名・住所・Place IDを保存する（item 7）', () async {
    final container = createContainer();
    await signInDemo(container);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier
      ..mutate((s) => s.copyWith(artistName: 'A', title: 'T'))
      ..mutate((s) => s.copyWith(eventDate: DateTime(2026, 8, 1)))
      // 会場の候補選択に相当（会場名＋住所＋Place ID）。
      ..mutate(
        (s) => s.copyWith(
          venue: '東京ドーム',
          venueAddress: '東京都文京区後楽1-3-61',
          venueGooglePlaceId: 'ChIJ_venue',
        ),
      );
    final result = await notifier.submit();
    expect(result.isOk, isTrue);
    final saved =
        (await container.read(genbaRepositoryProvider).watchAll().first).single;
    expect(saved.genba.venue, '東京ドーム');
    expect(saved.genba.venueAddress, '東京都文京区後楽1-3-61');
    expect(saved.genba.venueGooglePlaceId, 'ChIJ_venue');
  });

  test('会場名を手入力で変えると Place ID の対応が外れる（item 7）', () {
    const s0 = GenbaFormState(
      venue: '東京ドーム',
      venueAddress: '東京都文京区',
      venueGooglePlaceId: 'ChIJ_venue',
    );
    // 手入力で名前を変えると placeId・住所はクリアされる。
    final s1 = s0.copyWith(
      venue: '東京ドー',
      clearVenueGooglePlaceId: true,
      venueAddress: '',
    );
    expect(s1.venueGooglePlaceId, isNull);
    expect(s1.venueAddress, '');
  });

  test('未ログインでは submit が AuthFailure', () async {
    final container = createContainer(signedIn: false);
    final notifier = container.read(genbaFormControllerProvider(null).notifier);
    await container.read(genbaFormControllerProvider(null).future);

    notifier.mutate(
      (s) => s.copyWith(
        artistName: 'a',
        title: 't',
        eventDate: DateTime(2026, 8, 1),
      ),
    );
    final result = await notifier.submit();
    expect(result.failureOrNull?.message, contains('ログイン'));
  });

  group('推しグループ・推しメンの選択（R5独立レビュー #3）', () {
    Future<
        ({
          ProviderContainer container,
          String ownerId,
          OshiGroup group1,
          OshiMember m1,
          OshiMember m2,
          OshiGroup group2,
          OshiMember m3,
        })> setUpWithOshi() async {
      final container = createContainer();
      await signInDemo(container);
      final user = await container.read(currentUserProvider.future);
      final ownerId = user!.id;
      final now = clock.now().toUtc();

      final group1 = OshiGroup(
        id: 'grp-1',
        ownerId: ownerId,
        name: 'グループ1',
        createdAt: now,
        updatedAt: now,
      );
      final group2 = OshiGroup(
        id: 'grp-2',
        ownerId: ownerId,
        name: 'グループ2',
        createdAt: now,
        updatedAt: now,
      );
      final m1 = OshiMember(
        id: 'mem-1',
        groupId: 'grp-1',
        ownerId: ownerId,
        name: 'メンバーA',
        createdAt: now,
        updatedAt: now,
      );
      final m2 = OshiMember(
        id: 'mem-2',
        groupId: 'grp-1',
        ownerId: ownerId,
        name: 'メンバーB',
        createdAt: now,
        updatedAt: now,
      );
      final m3 = OshiMember(
        id: 'mem-3',
        groupId: 'grp-2',
        ownerId: ownerId,
        name: 'メンバーC',
        createdAt: now,
        updatedAt: now,
      );
      final oshi = container.read(oshiRepositoryProvider);
      for (final g in [group1, group2]) {
        expect((await oshi.upsertGroup(g)).isOk, isTrue);
      }
      for (final m in [m1, m2, m3]) {
        expect((await oshi.upsertMember(m)).isOk, isTrue);
      }
      return (
        container: container,
        ownerId: ownerId,
        group1: group1,
        m1: m1,
        m2: m2,
        group2: group2,
        m3: m3,
      );
    }

    test('グループとメンバーを選択して submit すると Genba に保存される', () async {
      final s = await setUpWithOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      notifier.toggleOshiMember(s.m2.id, true);
      notifier.mutate(
        (st) => st.copyWith(title: '夏ライブ', eventDate: DateTime(2026, 8, 1)),
      );

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      expect(saved!.genba.oshiGroupId, s.group1.id);
      expect(saved.genba.artistName, s.group1.name);
      expect(saved.genba.oshiMemberIds, containsAll([s.m1.id, s.m2.id]));
    });

    test('下書き経由で再オープンしてもグループ・メンバー選択が復元される', () async {
      final s = await setUpWithOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      // 自動保存（下書き）の書き込みを待つ。
      await Future<void>.delayed(const Duration(milliseconds: 50));

      s.container.invalidate(genbaFormControllerProvider(null));
      final restored =
          await s.container.read(genbaFormControllerProvider(null).future);
      expect(restored.oshiGroupId, s.group1.id);
      expect(restored.oshiMemberIds, [s.m1.id]);
    });

    test('グループを別グループへ変更すると前グループのメンバー選択はクリアされる', () async {
      final s = await setUpWithOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      notifier.toggleOshiMember(s.m2.id, true);
      var state = s.container.read(genbaFormControllerProvider(null)).value!;
      expect(state.oshiMemberIds, containsAll([s.m1.id, s.m2.id]));

      // 別グループへ切替 → 前グループのメンバーIDは不正になるので消える。
      notifier.selectOshiGroup(s.group2.id, artistName: s.group2.name);
      state = s.container.read(genbaFormControllerProvider(null)).value!;
      expect(state.oshiGroupId, s.group2.id);
      expect(state.oshiMemberIds, isEmpty);
    });

    test('グループを解除するとメンバー選択もクリアされる', () async {
      final s = await setUpWithOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      notifier.selectOshiGroup(null);

      final state = s.container.read(genbaFormControllerProvider(null)).value!;
      expect(state.oshiGroupId, isNull);
      expect(state.oshiMemberIds, isEmpty);
    });

    test('同じグループを選び直してもメンバー選択は保持される', () async {
      final s = await setUpWithOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      // 同じグループを再選択（idが変わらない）→ クリアしない。
      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);

      final state = s.container.read(genbaFormControllerProvider(null)).value!;
      expect(state.oshiMemberIds, [s.m1.id]);
    });
  });

  group('保存時の推しグループ・推しメン整合性検証（R5再レビュー #1）', () {
    Future<
        ({
          ProviderContainer container,
          String ownerId,
          OshiGroup group1,
          OshiMember m1,
          OshiMember m2,
          OshiGroup group2,
          OshiMember m3,
        })> setUpWithOshi() async {
      final container = createContainer();
      await signInDemo(container);
      final user = await container.read(currentUserProvider.future);
      final ownerId = user!.id;
      final now = clock.now().toUtc();

      final group1 = OshiGroup(
        id: 'grp-1',
        ownerId: ownerId,
        name: 'グループ1',
        createdAt: now,
        updatedAt: now,
      );
      final group2 = OshiGroup(
        id: 'grp-2',
        ownerId: ownerId,
        name: 'グループ2',
        createdAt: now,
        updatedAt: now,
      );
      final m1 = OshiMember(
        id: 'mem-1',
        groupId: 'grp-1',
        ownerId: ownerId,
        name: 'メンバーA',
        createdAt: now,
        updatedAt: now,
      );
      final m2 = OshiMember(
        id: 'mem-2',
        groupId: 'grp-1',
        ownerId: ownerId,
        name: 'メンバーB',
        createdAt: now,
        updatedAt: now,
      );
      final m3 = OshiMember(
        id: 'mem-3',
        groupId: 'grp-2',
        ownerId: ownerId,
        name: 'メンバーC',
        createdAt: now,
        updatedAt: now,
      );
      final oshi = container.read(oshiRepositoryProvider);
      for (final g in [group1, group2]) {
        expect((await oshi.upsertGroup(g)).isOk, isTrue);
      }
      for (final m in [m1, m2, m3]) {
        expect((await oshi.upsertMember(m)).isOk, isTrue);
      }
      return (
        container: container,
        ownerId: ownerId,
        group1: group1,
        m1: m1,
        m2: m2,
        group2: group2,
        m3: m3,
      );
    }

    Future<GenbaFormController> openNewForm(ProviderContainer container) async {
      final notifier =
          container.read(genbaFormControllerProvider(null).notifier);
      await container.read(genbaFormControllerProvider(null).future);
      return notifier;
    }

    test('正常系: 選択中グループに実在するメンバーはそのまま保存され、補正メッセージは無い', () async {
      final s = await setUpWithOshi();
      final notifier = await openNewForm(s.container);
      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      notifier.mutate(
        (st) => st.copyWith(title: '夏ライブ', eventDate: DateTime(2026, 8, 1)),
      );

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      expect(saved!.genba.oshiGroupId, s.group1.id);
      expect(saved.genba.oshiMemberIds, [s.m1.id]);
    });

    test('削除済み: 選択後に外部でメンバーが削除されていたら黙って保存せず除外し、補正を知らせる', () async {
      final s = await setUpWithOshi();
      final notifier = await openNewForm(s.container);
      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      notifier.toggleOshiMember(s.m2.id, true);
      notifier.mutate(
        (st) => st.copyWith(title: '夏ライブ', eventDate: DateTime(2026, 8, 1)),
      );

      // フォームが選択を保持したまま、外部（別画面・別端末の同期など）で
      // m1 が削除されたことを模す。フォーム状態は自動では追随しない。
      final delResult =
          await s.container.read(oshiRepositoryProvider).deleteMember(s.m1.id);
      expect(delResult.isOk, isTrue);

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNotNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      // 削除済みの m1 は保存されず、実在する m2 のみ残る。
      expect(saved!.genba.oshiMemberIds, [s.m2.id]);
    });

    test('別グループ: 選択中グループに属さないメンバーIDは黙って保存せず除外する', () async {
      final s = await setUpWithOshi();
      final notifier = await openNewForm(s.container);
      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      // 通常のUI操作では起こらないが、下書き破損等でグループ2のメンバーIDが
      // 紛れ込んだ状態を模す（selectOshiGroup を経由しない直接注入）。
      notifier.mutate(
        (st) => st.copyWith(oshiMemberIds: [...st.oshiMemberIds, s.m3.id]),
      );
      notifier.mutate(
        (st) => st.copyWith(title: '夏ライブ', eventDate: DateTime(2026, 8, 1)),
      );

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNotNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      // group2 所属の m3 は除外され、group1 所属の m1 のみ残る。
      expect(saved!.genba.oshiMemberIds, [s.m1.id]);
    });

    test('別owner: 他ユーザーのグループIDが紛れ込んでも黙って保存せず解除する（owner分離）', () async {
      final s = await setUpWithOshi();
      final db = s.container.read(databaseProvider);
      const otherOwnerGroupId = 'grp-other-owner';
      // 別ownerのグループを直接DBへ投入する（watchAll は owner 分離により
      // このグループを絶対に返さない, C-01）。
      await db.into(db.oshiGroups).insert(
            OshiGroupsCompanion.insert(
              id: otherOwnerGroupId,
              ownerId: 'other-owner-999',
              name: '別ユーザーのグループ',
              createdAt: clock.now().toUtc().toIso8601String(),
              updatedAt: clock.now().toUtc().toIso8601String(),
            ),
          );

      final notifier = await openNewForm(s.container);
      // 通常のUIでは他ownerのIDを選択できないが、破損した下書き等で
      // 紛れ込んだ状態を模して直接注入する。
      notifier.mutate(
        (st) => st.copyWith(
          artistName: '推しグループ',
          title: '夏ライブ',
          eventDate: DateTime(2026, 8, 1),
          oshiGroupId: otherOwnerGroupId,
        ),
      );

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNotNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      // 他ownerのグループIDは保存されず、選択は解除される。
      expect(saved!.genba.oshiGroupId, isNull);
      expect(saved.genba.oshiMemberIds, isEmpty);
    });

    test('グループ解除: グループ未選択なのにメンバーIDが残っていても保存前にクリアされる', () async {
      final s = await setUpWithOshi();
      final notifier = await openNewForm(s.container);
      notifier.selectOshiGroup(s.group1.id, artistName: s.group1.name);
      notifier.toggleOshiMember(s.m1.id, true);
      // selectOshiGroup(null) を経由せず、グループだけを直接クリアして
      // メンバーIDが不整合に残った状態を模す。
      notifier.mutate((st) => st.copyWith(clearOshiGroupId: true));
      notifier.mutate(
        (st) => st.copyWith(title: '夏ライブ', eventDate: DateTime(2026, 8, 1)),
      );
      // 直接注入直後の状態はまだ不整合（グループ無しなのにメンバーIDが残る）。
      final beforeSubmit =
          s.container.read(genbaFormControllerProvider(null)).value!;
      expect(beforeSubmit.oshiGroupId, isNull);
      expect(beforeSubmit.oshiMemberIds, [s.m1.id]);

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.oshiCorrectionMessage, isNotNull);

      final saved = await s.container
          .read(genbaRepositoryProvider)
          .watchById(result.valueOrNull!.id)
          .first;
      expect(saved!.genba.oshiGroupId, isNull);
      expect(saved.genba.oshiMemberIds, isEmpty);
    });
  });

  group('推しデータ取得失敗時のsubmit()（R5再々レビュー）', () {
    Future<
        ({
          ProviderContainer container,
          String ownerId,
          FakeOshiRepository fakeOshi,
        })> setUpWithFakeOshi() async {
      final db = createTestDb();
      late FakeOshiRepository fakeOshi;
      final container = ProviderContainer(
        overrides: [
          envProvider.overrideWithValue(demoEnv),
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock),
          oshiRepositoryProvider.overrideWith((ref) {
            final scope = ref.watch(localDataScopeProvider);
            final real = OshiRepositoryImpl(
              db: ref.watch(databaseProvider),
              outbox: ref.watch(outboxStoreProvider),
              syncEngine: ref.watch(syncEngineProvider),
              clock: ref.watch(clockProvider),
              ownerIdResolver: () => scope.ownerIdOrNull,
            );
            fakeOshi = FakeOshiRepository(real);
            return fakeOshi;
          }),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(db.close);
      // oshiRepositoryProvider は localDataScopeProvider を watch しており、
      // ログイン前に読むと未認証scope向けのインスタンスが作られてしまう。
      // ログイン完了（scope確定）を待ってから読み、submit() が実際に使う
      // インスタンスと同じ fakeOshi をキャプチャする。
      await signInDemo(container);
      await container.read(currentUserProvider.future);
      container.read(oshiRepositoryProvider);
      return (
        container: container,
        ownerId: container.read(currentUserProvider).value!.id,
        fakeOshi: fakeOshi,
      );
    }

    test('推しグループ選択時にOshiRepository.watchAll()が失敗してもsubmit()はthrowせずErrを返す',
        () async {
      final s = await setUpWithFakeOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.mutate(
        (st) => st.copyWith(
          artistName: '推しグループ',
          title: '夏ライブ',
          eventDate: DateTime(2026, 8, 1),
          oshiGroupId: 'some-group',
        ),
      );
      s.fakeOshi.watchAllError = Exception('DB読み込みエラー（テスト注入）');

      // submit() が例外を投げず、正常にResultを返すこと自体がここでの検証。
      // （投げていれば await が例外で終了しテストがそのまま失敗する）
      final result = await notifier.submit();

      expect(result.isOk, isFalse);
      expect(result.failureOrNull, isNotNull);
      expect(result.failureOrNull!.message, contains('推しデータの読み込みに失敗しました'));
    });

    test('推しデータ取得失敗時は現場が不完全な状態で保存されない', () async {
      final s = await setUpWithFakeOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      notifier.mutate(
        (st) => st.copyWith(
          artistName: '推しグループ',
          title: '夏ライブ',
          eventDate: DateTime(2026, 8, 1),
          oshiGroupId: 'some-group',
        ),
      );
      s.fakeOshi.watchAllError = Exception('DB読み込みエラー（テスト注入）');

      final result = await notifier.submit();
      expect(result.isOk, isFalse);

      final all =
          await s.container.read(genbaRepositoryProvider).watchAll().first;
      expect(all, isEmpty);
    });

    test('推しグループ未選択の場合はOshiRepositoryを呼ばないため取得失敗の影響を受けない', () async {
      final s = await setUpWithFakeOshi();
      final notifier =
          s.container.read(genbaFormControllerProvider(null).notifier);
      await s.container.read(genbaFormControllerProvider(null).future);

      // グループ未選択（既定値）のまま、日付等だけ入力する。
      notifier.mutate(
        (st) => st.copyWith(
          artistName: '推しグループ',
          title: '夏ライブ',
          eventDate: DateTime(2026, 8, 1),
        ),
      );
      s.fakeOshi.watchAllError = Exception('DB読み込みエラー（テスト注入）');

      final result = await notifier.submit();
      expect(result.isOk, isTrue);
    });
  });
}
