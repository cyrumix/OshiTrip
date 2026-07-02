import 'dart:async';

import 'failure.dart';

/// 成功 [Ok] / 失敗 [Err] を型で表す結果型。
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  T? get valueOrNull =>
      switch (this) { Ok(:final value) => value, Err() => null };

  Failure? get failureOrNull =>
      switch (this) { Ok() => null, Err(:final failure) => failure };

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) =>
      switch (this) {
        Ok(:final value) => ok(value),
        Err(:final failure) => err(failure),
      };

  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value) => Ok(transform(value)),
        Err(:final failure) => Err(failure),
      };
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// 例外を [Failure] に変換しながら非同期処理を実行するヘルパ。
Future<Result<T>> guardResult<T>(
  Future<T> Function() body, {
  Failure Function(Object error, StackTrace stackTrace)? onError,
}) async {
  try {
    return Ok(await body());
  } on Failure catch (f) {
    return Err(f);
  } catch (e, st) {
    if (onError != null) return Err(onError(e, st));
    if (e is TimeoutException) {
      return Err(NetworkFailure(cause: e));
    }
    return Err(UnknownFailure(cause: e));
  }
}
