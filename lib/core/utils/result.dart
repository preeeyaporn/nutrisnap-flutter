/// Functional Result pattern for type-safe error and success management.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(String message, [Exception? exception]) =
      Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };

  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(message: final m) => m,
  };

  String? get errorMessage => errorOrNull;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(message: final m, exception: final e) => failure(m, e),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;
}

class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;
  const Failure(this.message, [this.exception]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> &&
          other.message == message &&
          other.exception == exception);

  @override
  int get hashCode => Object.hash(message, exception);
}
