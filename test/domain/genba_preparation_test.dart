import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/genba/domain/genba_preparation.dart';

import '../helpers/fixtures.dart';

void main() {
  final eventDate = DateTime(2026, 7, 10);
  final now = DateTime(2026, 7, 2);

  group('「不要」と「未登録」の区別（§7.4/§7.5）', () {
    test('交通・宿泊が「不要」なら未完了数に含めない', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.notRequired,
          lodgingRequirement: RequirementStatus.notRequired,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
      );
      final prep = GenbaPreparation.of(aggregate);
      expect(prep.transport, CategoryPrepState.notRequired);
      expect(prep.lodging, CategoryPrepState.notRequired);
      expect(prep.attentionCount, 0);
    });

    test('「必要」かつ未登録なら未完了数に含める', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.required,
          lodgingRequirement: RequirementStatus.required,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
      );
      final prep = GenbaPreparation.of(aggregate);
      expect(prep.transport, CategoryPrepState.notRegistered);
      expect(prep.lodging, CategoryPrepState.notRegistered);
      expect(prep.attentionCount, 2);
    });

    test('未完了Todoは件数に含まれ、完了済みは含まれない', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.notRequired,
          lodgingRequirement: RequirementStatus.notRequired,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
        todos: [
          makeTodo(id: 't1', isDone: false),
          makeTodo(id: 't2', isDone: true),
        ],
      );
      expect(GenbaPreparation.of(aggregate).incompleteTodoCount, 1);
      expect(GenbaPreparation.of(aggregate).attentionCount, 1);
    });

    test('Todo残数と持ち物残数は種別ごとに独立して数える（持ち物を誤って含めない）', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(eventDate: eventDate),
        todos: [
          makeTodo(id: 't1', type: TodoItemType.todo, isDone: false),
          makeTodo(id: 't2', type: TodoItemType.todo, isDone: true),
          makeTodo(id: 'b1', type: TodoItemType.belonging, isDone: false),
          makeTodo(id: 'b2', type: TodoItemType.belonging, isDone: false),
          makeTodo(id: 'b3', type: TodoItemType.belonging, isDone: true),
        ],
      );
      expect(aggregate.incompleteTodoCount, 1);
      expect(aggregate.incompleteBelongingCount, 2);
      // 準備サマリの「Todo残り」相当の値にも持ち物を含めない。
      expect(GenbaPreparation.of(aggregate).incompleteTodoCount, 1);
    });

    test('持ち物0件なら未登録', () {
      final aggregate = GenbaAggregate(genba: makeGenba(eventDate: eventDate));
      expect(
        GenbaPreparation.of(aggregate).belonging,
        BelongingPrepState.notRegistered,
      );
    });

    test('未チェックの持ち物が1件でもあれば未対応', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(eventDate: eventDate),
        todos: [
          makeTodo(id: 'b1', type: TodoItemType.belonging, isDone: true),
          makeTodo(id: 'b2', type: TodoItemType.belonging, isDone: false),
        ],
      );
      expect(
        GenbaPreparation.of(aggregate).belonging,
        BelongingPrepState.pending,
      );
    });

    test('登録された持ち物がすべてチェック済みなら準備OK', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(eventDate: eventDate),
        todos: [
          makeTodo(id: 'b1', type: TodoItemType.belonging, isDone: true),
          makeTodo(id: 'b2', type: TodoItemType.belonging, isDone: true),
        ],
      );
      expect(
        GenbaPreparation.of(aggregate).belonging,
        BelongingPrepState.ready,
      );
    });

    test('往復が揃うと交通は準備OK', () {
      final base = makeGenba(
        eventDate: eventDate,
        transportRequirement: RequirementStatus.required,
      );
      Transport transport(String id, TransportDirection direction) => Transport(
            id: id,
            genbaId: base.id,
            ownerId: base.ownerId,
            direction: direction,
            createdAt: fixedCreatedAt,
            updatedAt: fixedCreatedAt,
          );
      final onlyOutbound = GenbaAggregate(
        genba: base,
        transports: [transport('tr1', TransportDirection.outbound)],
      );
      expect(
        GenbaPreparation.of(onlyOutbound).transport,
        CategoryPrepState.inProgress,
      );
      final both = GenbaAggregate(
        genba: base,
        transports: [
          transport('tr1', TransportDirection.outbound),
          transport('tr2', TransportDirection.inbound),
        ],
      );
      expect(
        GenbaPreparation.of(both).transport,
        CategoryPrepState.ready,
      );
    });
  });

  group('次アクションの優先順位', () {
    test('チケット未登録が最優先', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.required,
        ),
        todos: [makeTodo(priority: TodoPriority.high)],
      );
      expect(
        deriveNextAction(aggregate, now)?.kind,
        NextActionKind.ticket,
      );
    });

    test('チケットありなら重要Todoが優先', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(eventDate: eventDate),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
        todos: [makeTodo(name: 'うちわを作る', priority: TodoPriority.high)],
      );
      final action = deriveNextAction(aggregate, now);
      expect(action?.kind, NextActionKind.todo);
      expect(action?.label, contains('うちわを作る'));
    });

    test('持ち物は重要度が付いていても「次にやる」の対象に含めない', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.notRequired,
          lodgingRequirement: RequirementStatus.notRequired,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
        todos: [
          // 通常UIでは持ち物にpriorityは付かないが、防御的に混入していても
          // 種別で除外されることを確認する。
          makeTodo(
            id: 'b1',
            name: 'ペンライト',
            type: TodoItemType.belonging,
            priority: TodoPriority.high,
          ),
        ],
      );
      // 持ち物しか無いので「次にやる」は出ない（独立した準備ステータスで示す）。
      expect(deriveNextAction(aggregate, now), isNull);
    });

    test('交通必要・未登録なら交通登録を促す', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          transportRequirement: RequirementStatus.required,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
      );
      expect(
        deriveNextAction(aggregate, now)?.kind,
        NextActionKind.transport,
      );
    });

    test('不要と回答済みの項目は促さない', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(
          eventDate: eventDate,
          isExpedition: false,
          transportRequirement: RequirementStatus.notRequired,
          lodgingRequirement: RequirementStatus.notRequired,
        ),
        tickets: [makeTicket(acquisition: TicketAcquisition.acquired)],
      );
      expect(deriveNextAction(aggregate, now), isNull);
    });

    test('中止した現場にはアクションを出さない', () {
      final aggregate = GenbaAggregate(
        genba: makeGenba(eventDate: eventDate, isCanceled: true),
      );
      expect(deriveNextAction(aggregate, now), isNull);
    });
  });
}
