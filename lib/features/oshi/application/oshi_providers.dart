import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/oshi.dart';

final oshiGroupsProvider = StreamProvider<List<OshiGroupWithMembers>>(
  (ref) => ref.watch(oshiRepositoryProvider).watchAll(),
);
