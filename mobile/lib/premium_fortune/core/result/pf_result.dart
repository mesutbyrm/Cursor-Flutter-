import '../errors/pf_failure.dart';

sealed class PfResult<T> {
  const PfResult();

  bool get isSuccess => this is PfSuccess<T>;
  bool get isFailure => this is PfError<T>;

  T? get valueOrNull => switch (this) {
        PfSuccess<T>(:final value) => value,
        _ => null,
      };

  PfFailure? get failureOrNull => switch (this) {
        PfError<T>(:final failure) => failure,
        _ => null,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(PfFailure failure) onFailure,
  }) {
    return switch (this) {
      PfSuccess<T>(:final value) => onSuccess(value),
      PfError<T>(:final failure) => onFailure(failure),
    };
  }
}

final class PfSuccess<T> extends PfResult<T> {
  const PfSuccess(this.value);
  final T value;
}

final class PfError<T> extends PfResult<T> {
  const PfError(this.failure);
  final PfFailure failure;
}
