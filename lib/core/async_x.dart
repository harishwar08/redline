import 'package:flutter_riverpod/flutter_riverpod.dart';

extension AsyncValueData<T> on AsyncValue<T> {
  /// The latest value if one is available (data, or stale data during a
  /// refresh/error), else null. Never throws — unlike `value` in an error
  /// state. (`valueOrNull` isn't present in this Riverpod version.)
  T? get dataOrNull => hasValue ? value : null;
}
