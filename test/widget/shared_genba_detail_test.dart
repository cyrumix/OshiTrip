import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/error/failure.dart';
import 'package:oshi_trip/core/error/result.dart';
import 'package:oshi_trip/core/time/clock.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/sharing/data/shared_genba_fetcher.dart';
import 'package:oshi_trip/features/sharing/data/shared_mutation_client.dart';
import 'package:oshi_trip/features/sharing/domain/genba_permission.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';
import 'package:oshi_trip/features/social/application/member_providers.dart';
import 'package:oshi_trip/features/social/presentation/shared_genba_detail_screen.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_screen.dart';

class _SpyMutationClient implements SharedMutationClient {
  final List<
          ({String table, String id, String op, Map<String, dynamic> payload})>
      calls = [];

  @override
  Future<Result<void>> apply({
    required String genbaId,
    required String entityTable,
    required String entityId,
    required String opType,
    Map<String, dynamic> payload = const {},
    int? baseVersion,
  }) async {
    calls.add(
      (
        table: entityTable,
        id: entityId,
        op: opType,
        payload: payload,
      ),
    );
    return const Ok(null);
  }
}

/// 常に競合（ConflictFailure）を返すクライアント。
class _ConflictMutationClient implements SharedMutationClient {
  @override
  Future<Result<void>> apply({
    required String genbaId,
    required String entityTable,
    required String entityId,
    required String opType,
    Map<String, dynamic> payload = const {},
    int? baseVersion,
  }) async =>
      const Err(
        ConflictFailure(message: '他のメンバーが先に更新しました。画面を再読み込みしてください'),
      );
}

void main() {
  final clock = FixedClock(DateTime(2026, 7, 11, 12));
  final ts = DateTime.utc(2026, 7, 11);

  SharedGenbaData data({
    List<SharedSpot>? spots,
    bool hasPlan = true,
    List<SharedLeg>? legs,
    List<SharedEntry>? entries,
    List<SharedTicket>? tickets,
    List<SharedTransport>? transports,
    List<SharedLodging>? lodgings,
    List<SharedGoods>? goods,
    List<SharedVisitedPlace>? visitedPlaces,
    List<SharedSetlistItem>? setlist,
    List<SharedPhoto>? photos,
  }) =>
      SharedGenbaData(
        aggregate: GenbaAggregate(
          genba: makeGenba(
            id: 'g1',
            artistName: 'ARASHI',
            title: '共有ドーム',
            eventDate: DateTime(2026, 8, 1),
          ),
          todos: [
            GenbaTodo(
              id: 't1',
              genbaId: 'g1',
              ownerId: 'owner',
              name: 'チケット発券',
              createdAt: ts,
              updatedAt: ts,
            ),
          ],
          memos: [
            GenbaMemo(
              id: 'm1',
              genbaId: 'g1',
              ownerId: 'owner',
              title: '自由メモ',
              body: 'ペンライト持参',
              createdAt: ts,
              updatedAt: ts,
            ),
            GenbaMemo(
              id: 'm2',
              genbaId: 'g1',
              ownerId: 'owner',
              kind: MemoKind.checklist,
              title: 'チェックリスト',
              content: const MemoContent(
                checklist: [
                  MemoChecklistItem(id: 'c1', text: 'チケット確認', checked: true),
                  MemoChecklistItem(id: 'c2', text: 'タオル'),
                ],
              ),
              createdAt: ts,
              updatedAt: ts,
            ),
            GenbaMemo(
              id: 'm3',
              genbaId: 'g1',
              ownerId: 'owner',
              kind: MemoKind.bingo,
              title: 'ビンゴ',
              content: const MemoContent(
                bingo: MemoBingo(
                  size: 3,
                  cells: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
                  selected: [0, 1, 2], // 1行そろってBINGO
                ),
              ),
              createdAt: ts,
              updatedAt: ts,
            ),
            GenbaMemo(
              id: 'm4',
              genbaId: 'g1',
              ownerId: 'owner',
              kind: MemoKind.vote,
              title: '投票メモ',
              content: const MemoContent(
                vote: MemoVote(
                  description: 'どこで集合？',
                  options: [
                    MemoVoteOption(id: 'o1', text: '正面ゲート案'),
                    MemoVoteOption(id: 'o2', text: '駅前案'),
                  ],
                  votes: [MemoVoteRecord(voterId: 'x', optionId: 'o1')],
                ),
              ),
              createdAt: ts,
              updatedAt: ts,
            ),
          ],
        ),
        todoVersions: const {'t1': 3},
        memoVersions: const {'m1': 1, 'm2': 1, 'm3': 1, 'm4': 1},
        hasPlan: hasPlan,
        firstPlanId: hasPlan ? 'plan1' : null,
        spots: spots ??
            const [
              SharedSpot(
                id: 'sp1',
                planId: 'plan1',
                name: '東京タワー',
                category: 'sightseeing',
                version: 4,
              ),
            ],
        entries: entries ??
            const [
              SharedEntry(id: 'e1', label: '出発地点'),
              SharedEntry(id: 'e2', label: '到着地点'),
            ],
        legs: legs ??
            const [
              SharedLeg(
                id: 'leg1',
                planId: 'plan1',
                label: '出発地点 → 到着地点・電車・バス 約30分',
                originEntryId: 'e1',
                destinationEntryId: 'e2',
                travelMode: 'transit',
                durationMinutes: 30,
                version: 2,
              ),
            ],
        tickets: tickets ??
            const [
              SharedTicket(id: 'tk1', version: 3, seat: 'A-1', gate: '3'),
            ],
        transports: transports ??
            const [
              SharedTransport(
                id: 'tr1',
                version: 2,
                direction: 'outbound',
                method: 'shinkansen',
                fromPlace: '東京',
                toPlace: '大阪',
              ),
            ],
        lodgings: lodgings ??
            const [
              SharedLodging(id: 'ld1', version: 2, name: 'ホテルA'),
            ],
        memory: const SharedMemory(
          id: 'mem1',
          version: 7,
          impression: '最高だった',
          bestMoment: 'アンコール',
        ),
        goods: goods ??
            const [
              SharedGoods(
                id: 'gd1',
                version: 2,
                name: 'ペンライト',
                price: 2500,
              ),
            ],
        visitedPlaces: visitedPlaces ??
            const [
              SharedVisitedPlace(id: 'pl1', version: 2, name: 'カフェA'),
              SharedVisitedPlace(
                id: 'pl2',
                version: 2,
                name: 'ラーメンB',
                category: 'food',
              ),
            ],
        setlist: setlist ??
            const [
              SharedSetlistItem(
                id: 'sl1',
                version: 2,
                position: 1,
                songTitle: 'Love so sweet',
              ),
            ],
        photos: photos ??
            const [
              SharedPhoto(
                id: 'ph1',
                version: 2,
                caption: 'ステージ',
                isCover: true,
              ),
            ],
      );

  Future<_SpyMutationClient> pump(
    WidgetTester tester,
    SharedGenbaDetail detail, {
    SharedMutationClient? clientOverride,
  }) async {
    // 共有現場詳細は編集セクションが多く縦に長い。全セクションを一度にレイアウト
    // させ、scrollUntilVisible が対象を画面端に置いてタップが外れる問題を避けるため
    // 十分に高いビューポートにする（論理 540x8000）。
    tester.view.physicalSize = const Size(1080, 16000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final spy = _SpyMutationClient();
    final db = await signedInTestDb();
    addTearDown(db.close);
    await pumpScreen(
      tester,
      db: db,
      clock: clock,
      child: const SharedGenbaDetailScreen(genbaId: 'g1'),
      extraOverrides: [
        sharedGenbaDetailProvider.overrideWith((ref, id) async => detail),
        sharedMutationClientProvider.overrideWithValue(clientOverride ?? spy),
      ],
    );
    return spy;
  }

  SharedGenbaDetail detailFor(ShareRole? role, {SharedGenbaData? d}) =>
      SharedGenbaDetail(
        data: d ?? data(),
        permission: genbaPermissionFor(isOwner: false, memberRole: role),
      );

  testWidgets('viewer は計画・思い出などを含む詳細を閲覧でき、編集導線が無い', (tester) async {
    await pump(tester, detailFor(ShareRole.viewer));

    expect(find.text('共有ドーム'), findsOneWidget);
    expect(find.text('チケット発券'), findsOneWidget);
    expect(find.text('東京タワー'), findsOneWidget); // 計画スポット
    expect(find.text('閲覧のみ'), findsOneWidget);
    expect(find.text('編集可'), findsNothing);
    // 構造化メモを閲覧できる（自由/チェックリスト/BINGO/投票）。
    expect(find.text('自由メモ'), findsOneWidget);
    expect(find.text('チェックリスト'), findsOneWidget);
    expect(find.text('チケット確認'), findsOneWidget); // checklist 項目
    expect(find.text('ビンゴ'), findsOneWidget);
    expect(find.textContaining('BINGO!'), findsOneWidget); // bingo 判定
    expect(find.text('正面ゲート案'), findsOneWidget); // vote 選択肢
    // viewer は編集導線（Todo削除・メモ追加/削除）を持たない。
    expect(find.byTooltip('削除'), findsNothing);
    expect(find.byTooltip('メモを削除'), findsNothing);
    expect(find.text('追加'), findsNothing);

    // 思い出・閲覧専用の注記は下方（縦長のメモ節の下）にあるためスクロールして確認。
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.textContaining('最高だった'),
      300,
      scrollable: scrollable,
    );
    expect(find.textContaining('最高だった'), findsOneWidget); // 思い出
    await tester.scrollUntilVisible(
      find.text('この現場は閲覧専用です'),
      300,
      scrollable: scrollable,
    );
    expect(find.text('この現場は閲覧専用です'), findsOneWidget);
  });

  testWidgets('editor は Todo をタップして apply_shared_mutation で更新できる',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    expect(find.text('編集可'), findsOneWidget);
    await tester.tap(find.text('チケット発券'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'todos');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 't1');
    expect(spy.calls.first.payload['is_done'], true);
  });

  testWidgets('editor は Todo を削除できる（apply_shared_mutation delete）',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.tap(find.byTooltip('削除'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.op, 'delete');
    expect(spy.calls.first.table, 'todos');
  });

  // 既存メモエディタ（種類別UI）を再利用して編集し、保存だけ apply_shared_mutation。
  Future<void> tapMemoSave(WidgetTester tester, String title) async {
    await tester.ensureVisible(find.text(title));
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memo_save')));
    await tester.pumpAndSettle();
  }

  testWidgets('editor は checklist メモを編集できる（kind維持で apply upsert）',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));
    await tapMemoSave(tester, 'チェックリスト');

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'genba_memos');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'm2');
    expect(spy.calls.first.payload['kind'], 'checklist');
  });

  testWidgets('editor は bingo メモを編集できる（kind維持で apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));
    await tapMemoSave(tester, 'ビンゴ');

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.id, 'm3');
    expect(spy.calls.first.payload['kind'], 'bingo');
  });

  testWidgets('editor は vote メモを編集できる（kind維持で apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));
    await tapMemoSave(tester, '投票メモ');

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.id, 'm4');
    expect(spy.calls.first.payload['kind'], 'vote');
  });

  testWidgets('editor は自由メモを追加できる（種類選択→エディタ→apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.byKey(const Key('memo_add_button')));
    await tester.tap(find.byKey(const Key('memo_add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memo_kind_free')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('memo_template_none')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('memo_title')), '新規メモ');
    await tester.tap(find.byKey(const Key('memo_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'genba_memos');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.payload['kind'], 'free');
  });

  testWidgets('editor は共有メモを削除できる（apply_shared_mutation delete）',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.byTooltip('メモを削除').first);
    await tester.tap(find.byTooltip('メモを削除').first);
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'genba_memos');
    expect(spy.calls.first.op, 'delete');
  });

  // ---- 計画スポットの共同編集（D-245）------------------------------------
  testWidgets('editor は計画スポットを追加できる（apply upsert・plan_id 付き）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.byKey(const Key('spot_add_button')));
    await tester.tap(find.byKey(const Key('spot_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('spot_name')), '清水寺');
    await tester.tap(find.byKey(const Key('spot_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_spots');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.payload['plan_id'], 'plan1');
    expect(spy.calls.first.payload['name'], '清水寺');
    // 追加時は baseVersion=null で送る（payload id と entityId は一致）。
    expect(spy.calls.first.payload['id'], spy.calls.first.id);
  });

  testWidgets('editor は計画スポットを編集できる（既存 version で apply upsert）',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.text('東京タワー'));
    await tester.tap(find.text('東京タワー'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('spot_name')), '東京スカイツリー');
    await tester.tap(find.byKey(const Key('spot_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_spots');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'sp1');
    expect(spy.calls.first.payload['name'], '東京スカイツリー');
    expect(spy.calls.first.payload['plan_id'], 'plan1');
  });

  testWidgets('editor は計画スポットを削除できる（apply delete）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.byTooltip('スポットを削除'));
    await tester.tap(find.byTooltip('スポットを削除'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_spots');
    expect(spy.calls.first.op, 'delete');
    expect(spy.calls.first.id, 'sp1');
  });

  testWidgets('スポット編集ダイアログの種別に「聖地」(sacred_place) が含まれる', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.ensureVisible(find.byKey(const Key('spot_add_button')));
    await tester.tap(find.byKey(const Key('spot_add_button')));
    await tester.pumpAndSettle();
    // 種別ドロップダウンを開くと通常計画スポットと同じ全カテゴリが並ぶ。
    await tester.tap(find.byKey(const Key('spot_category')));
    await tester.pumpAndSettle();
    expect(find.text('聖地'), findsWidgets);
    expect(find.text('観光地'), findsWidgets);
    // ダイアログを閉じるだけ（保存しない）。
    expect(spy.calls, isEmpty);
  });

  testWidgets('既存の sacred_place スポットを編集しても other に落ちない', (tester) async {
    final detail = detailFor(
      ShareRole.editor,
      d: data(
        spots: const [
          SharedSpot(
            id: 'sp9',
            planId: 'plan1',
            name: '聖地A',
            category: 'sacred_place',
            version: 2,
          ),
        ],
      ),
    );
    final spy = await pump(tester, detail);

    // カードには聖地ラベルが表示される（wire→label が一致）。
    expect(find.text('聖地'), findsOneWidget);

    await tester.ensureVisible(find.text('聖地A'));
    await tester.tap(find.text('聖地A'));
    await tester.pumpAndSettle();
    // 種別は変えず名前だけ変更して保存する。
    await tester.enterText(find.byKey(const Key('spot_name')), '聖地B');
    await tester.tap(find.byKey(const Key('spot_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_spots');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'sp9');
    expect(spy.calls.first.payload['name'], '聖地B');
    // sacred_place のまま保存される（other に落ちない）。
    expect(spy.calls.first.payload['category'], 'sacred_place');
  });

  testWidgets('計画未作成のとき editor には案内を出し、追加導線を出さない', (tester) async {
    await pump(
      tester,
      detailFor(ShareRole.editor, d: data(hasPlan: false)),
    );

    await tester.ensureVisible(find.textContaining('計画はまだ作成されていません'));
    expect(find.textContaining('計画はまだ作成されていません'), findsOneWidget);
    expect(find.byKey(const Key('spot_add_button')), findsNothing);
  });

  testWidgets('editor は移動区間を削除できる（apply delete）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.byTooltip('移動区間を削除'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('移動区間を削除'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_legs');
    expect(spy.calls.first.op, 'delete');
    expect(spy.calls.first.id, 'leg1');
  });

  // ---- 思い出テキストの共同編集（D-245）----------------------------------
  testWidgets('editor は思い出の感想を編集できる（既存 memory_entries を upsert）',
      (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.byKey(const Key('memory_edit_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('memory_edit_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('memory_impression')),
      'ほんとうに最高',
    );
    await tester.tap(find.byKey(const Key('memory_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'memory_entries');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'mem1');
    expect(spy.calls.first.payload['genba_id'], 'g1');
    expect(spy.calls.first.payload['impression'], 'ほんとうに最高');
  });

  // ---- 移動区間 add/edit・チケット/交通/宿泊・思い出リスト・写真（D-246）------
  Future<void> scrollToKey(WidgetTester tester, Key key) =>
      tester.scrollUntilVisible(
        find.byKey(key),
        300,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('editor は移動区間を追加できる（端点選択→apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('leg_add_button'));
    await tester.tap(find.byKey(const Key('leg_add_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_origin')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('出発地点').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_destination')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('到着地点').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_legs');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.payload['plan_id'], 'plan1');
    expect(spy.calls.first.payload['origin_entry_id'], 'e1');
    expect(spy.calls.first.payload['destination_entry_id'], 'e2');
    expect(spy.calls.first.payload['travel_mode'], 'transit');
  });

  testWidgets('editor は移動区間を編集できる（交通手段変更→apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.textContaining('出発地点 → 到着地点'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.textContaining('出発地点 → 到着地点'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('徒歩').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('leg_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'itinerary_legs');
    expect(spy.calls.first.id, 'leg1');
    expect(spy.calls.first.payload['travel_mode'], 'walking');
  });

  testWidgets('editor はチケットを追加できる（genba_id 付き apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('ticket_add_button'));
    await tester.tap(find.byKey(const Key('ticket_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('ticket_seat')), 'S-9');
    await tester.tap(find.byKey(const Key('ticket_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'tickets');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.payload['genba_id'], 'g1');
    expect(spy.calls.first.payload['seat'], 'S-9');
  });

  testWidgets('editor はチケットを削除できる（apply delete）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.byTooltip('チケットを削除'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('チケットを削除'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'tickets');
    expect(spy.calls.first.op, 'delete');
    expect(spy.calls.first.id, 'tk1');
  });

  testWidgets('editor は交通を追加できる（apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('transport_add_button'));
    await tester.tap(find.byKey(const Key('transport_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transport_from')), '博多');
    await tester.tap(find.byKey(const Key('transport_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'transports');
    expect(spy.calls.first.payload['genba_id'], 'g1');
    expect(spy.calls.first.payload['from_place'], '博多');
    expect(spy.calls.first.payload['direction'], 'outbound');
  });

  testWidgets('editor は宿泊を追加できる（apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('lodging_add_button'));
    await tester.tap(find.byKey(const Key('lodging_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('lodging_name')), '旅館B');
    await tester.tap(find.byKey(const Key('lodging_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'lodgings');
    expect(spy.calls.first.payload['genba_id'], 'g1');
    expect(spy.calls.first.payload['name'], '旅館B');
  });

  testWidgets('editor はグッズを追加できる（apply upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('goods_add_button'));
    await tester.tap(find.byKey(const Key('goods_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goods_name')), 'アクスタ');
    await tester.tap(find.byKey(const Key('goods_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'goods_items');
    expect(spy.calls.first.payload['genba_id'], 'g1');
    expect(spy.calls.first.payload['name'], 'アクスタ');
  });

  testWidgets('editor は行った場所を追加できる（category=spot）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('place_add_button'));
    await tester.tap(find.byKey(const Key('place_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place_name')), '展望台');
    await tester.tap(find.byKey(const Key('place_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'visited_places');
    expect(spy.calls.first.payload['name'], '展望台');
    expect(spy.calls.first.payload['category'], 'spot');
  });

  testWidgets('editor は食べたものを追加できる（category=food）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('food_add_button'));
    await tester.tap(find.byKey(const Key('food_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('place_name')), 'たこ焼き');
    await tester.tap(find.byKey(const Key('place_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'visited_places');
    expect(spy.calls.first.payload['name'], 'たこ焼き');
    expect(spy.calls.first.payload['category'], 'food');
  });

  testWidgets('editor はセットリストを追加できる（position 自動採番）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await scrollToKey(tester, const Key('setlist_add_button'));
    await tester.tap(find.byKey(const Key('setlist_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('setlist_song')), 'A・RA・SHI');
    await tester.tap(find.byKey(const Key('setlist_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'setlist_items');
    expect(spy.calls.first.payload['song_title'], 'A・RA・SHI');
    // 既存 position 最大(1)の次＝2。
    expect(spy.calls.first.payload['position'], 2);
  });

  testWidgets('editor は写真のキャプションを編集できる（メタデータのみ upsert）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.text('ステージ'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('ステージ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('photo_caption')), '神席から');
    await tester.tap(find.byKey(const Key('photo_save')));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'memory_photos');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'ph1');
    expect(spy.calls.first.payload['caption'], '神席から');
  });

  testWidgets('editor は既存カバーがある状態で別写真をカバーにできる（is_cover:true 送信）',
      (tester) async {
    final detail = detailFor(
      ShareRole.editor,
      d: data(
        photos: const [
          SharedPhoto(id: 'ph1', version: 2, caption: 'ステージ', isCover: true),
          SharedPhoto(id: 'ph2', version: 3, caption: '客席から'),
        ],
      ),
    );
    final spy = await pump(tester, detail);

    // ph2（非カバー）を開き、カバーをオンにして保存する。
    await tester.scrollUntilVisible(
      find.text('客席から'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('客席から'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo_cover')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('photo_save')));
    await tester.pumpAndSettle();

    // クライアントは対象写真に is_cover:true を送る（同一現場の他カバー解除は
    // apply_shared_mutation 側で安全に行う, D-247）。
    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'memory_photos');
    expect(spy.calls.first.op, 'upsert');
    expect(spy.calls.first.id, 'ph2');
    expect(spy.calls.first.payload['is_cover'], true);
  });

  testWidgets('editor は写真を削除できる（apply delete）', (tester) async {
    final spy = await pump(tester, detailFor(ShareRole.editor));

    await tester.scrollUntilVisible(
      find.byTooltip('写真を削除'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('写真を削除'));
    await tester.pumpAndSettle();

    expect(spy.calls, hasLength(1));
    expect(spy.calls.first.table, 'memory_photos');
    expect(spy.calls.first.op, 'delete');
    expect(spy.calls.first.id, 'ph1');
  });

  testWidgets('viewer には各セクションの追加・削除導線が出ない', (tester) async {
    await pump(tester, detailFor(ShareRole.viewer));

    for (final k in const [
      'spot_add_button',
      'leg_add_button',
      'ticket_add_button',
      'transport_add_button',
      'lodging_add_button',
      'goods_add_button',
      'place_add_button',
      'food_add_button',
      'setlist_add_button',
      'memory_edit_button',
    ]) {
      expect(find.byKey(Key(k)), findsNothing, reason: '$k は viewer に出ない');
    }
    for (final t in const [
      'スポットを削除',
      '移動区間を削除',
      'チケットを削除',
      '交通を削除',
      '宿泊を削除',
      'グッズを削除',
      '行った場所を削除',
      '食べたものを削除',
      '曲を削除',
      '写真を削除',
    ]) {
      expect(find.byTooltip(t), findsNothing, reason: '$t は viewer に出ない');
    }
  });

  testWidgets('editor のスポット追加が競合したら通知する（成功扱いにしない）', (tester) async {
    await pump(
      tester,
      detailFor(ShareRole.editor),
      clientOverride: _ConflictMutationClient(),
    );

    await tester.ensureVisible(find.byKey(const Key('spot_add_button')));
    await tester.tap(find.byKey(const Key('spot_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('spot_name')), '清水寺');
    await tester.tap(find.byKey(const Key('spot_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('他のメンバーが先に更新しました。画面を再読み込みしてください'),
      findsOneWidget,
    );
  });

  testWidgets('editor の Todo 更新が競合したら分かりやすく通知する', (tester) async {
    await pump(
      tester,
      detailFor(ShareRole.editor),
      clientOverride: _ConflictMutationClient(),
    );

    await tester.tap(find.text('チケット発券'));
    await tester.pump(); // action await
    await tester.pump(const Duration(milliseconds: 300)); // SnackBar 表示

    expect(
      find.text('他のメンバーが先に更新しました。画面を再読み込みしてください'),
      findsOneWidget,
    );
  });

  testWidgets('共有解除・権限なしのときは表示できない案内を出す', (tester) async {
    await pump(
      tester,
      SharedGenbaDetail(
        data: null,
        permission: genbaPermissionFor(isOwner: false),
      ),
    );
    expect(find.text('この現場は表示できません'), findsOneWidget);
    expect(find.text('共有ドーム'), findsNothing);
  });
}
