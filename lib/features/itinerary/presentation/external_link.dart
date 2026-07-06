import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/itinerary_validation.dart';

/// 外部URLを開く前に遷移先ドメインを提示して確認する（§4.5「外部遷移前に
/// ドメインを表示する」）。http/https 以外・host 無しは開かない（保存時にも
/// 弾いているが、表示直前にも二重に防御する）。
///
/// 予約URL等をログ・分析へ出さないため、確認ダイアログにはフルURLではなく
/// host（ドメイン）だけを表示する。
Future<void> openExternalUrlWithConfirm(
  BuildContext context, {
  required String url,
  String? label,
}) async {
  if (validateItineraryUrl(url) != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('このURLは開けません（http/httpsのみ対応）')),
    );
    return;
  }
  final uri = Uri.parse(url.trim());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('外部サイトを開きますか？'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null && label.trim().isNotEmpty) ...[
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
          ],
          Text(
            '遷移先: ${uri.host}',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '外部ブラウザ／アプリで開きます。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('開く'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await canLaunchUrl(uri) &&
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('リンクを開けませんでした')),
    );
  }
}
