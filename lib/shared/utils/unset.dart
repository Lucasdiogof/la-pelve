const Object kUnset = Object();

T? unsetOr<T>(Object? value, T? fallback) =>
    identical(value, kUnset) ? fallback : value as T?;
