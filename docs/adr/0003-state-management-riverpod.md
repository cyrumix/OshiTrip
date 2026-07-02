# ADR-0003: 状態管理に Riverpod を採用

- 状態: 承認済み
- 日付: 2026-07-01
- 関連要件: §2, §6, §15.3

## 背景 / 課題

段階的開示・自動保存・楽観更新・オフライン同期・空/エラー状態の明示的表現を、テスト容易な形で扱う状態管理が必要。

## 選択肢

1. **Riverpod（flutter_riverpod + riverpod_generator）** — コンパイル安全なDI、`AsyncValue`で loading/data/error を型で扱う、`override`でテスト差替が容易。
2. Bloc — 明快だが定型が多く、細粒度の楽観更新でボイラープレート増。
3. Provider(旧) / setState — 大規模状態・DIには不足。

## 決定

**Riverpod** を採用。`AsyncNotifier`/`Notifier` で画面状態を表現し、空状態を明示的に扱う。DIはProviderで統一し、テストは `overrideWith` で差し替える。

## 影響

- `domain` は純Dartを維持し、Riverpodはapplication層に限定。
- 楽観更新の失敗ロールバック＋Outbox退避（`core/sync`）と組み合わせる。

## 検証方法

- Notifierの単体テストで loading→data / error / empty / 楽観更新ロールバックを検証。
- Widgetテストで各状態の描画を検証。
