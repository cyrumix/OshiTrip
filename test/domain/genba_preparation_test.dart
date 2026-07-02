import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_expedition/features/genba/domain/genba.dart';
import 'package:oshi_expedition/features/genba/domain/genba_preparation.dart';

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
