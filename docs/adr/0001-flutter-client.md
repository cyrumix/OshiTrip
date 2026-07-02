# ADR-0001: クライアントフレームワークに Flutter を採用

- 状態: 承認済み
- 日付: 2026-07-01
- 関連要件: §16.1, §16.2, §15.1

## 背景 / 課題

主開発環境がWindowsで、iOS／Androidを単一コードベースで開発する必要がある。要件定義書 §16.1 でFlutterが推奨構成として明記されている。

## 選択肢

1. **Flutter / Dart** — 単一コードベース、Windowsで共通＋Android開発可、豊富なUI表現、Supabase/Firebase双方に公式SDK。iOS最終ビルドのみmacOS必要。
2. React Native — JSエコシステム。ネイティブモジュール差異とビルド構成の複雑さ。
3. ネイティブ2実装（Swift/Kotlin） — Windows主開発と両立せず、工数2倍。

## 決定

**Flutter / Dart** を採用する。要件の推奨に合致し、Windows主開発・iOS/Android両対応・オフラインUI・アクセシビリティ・ダークモード要件を満たしやすい。

## 影響

- iOSビルド/署名/提出はmacOS（Mac実機またはmacOS CI）が必須（§16.2）。CIに macOS ジョブを組み込む。
- 状態管理・ルーティング・ローカルDBは別ADRで確定（ADR-0003/0004/0005）。

## 検証方法

- CIでWindows（analyze/test/Android build）とmacOS（iOS build 無署名）が成功すること。
- ツールチェーン未導入のため現時点はビルド未実行。[setup.md](../setup.md) の手順導入後に検証する（Phase 0 ブロッカーとして記録）。
