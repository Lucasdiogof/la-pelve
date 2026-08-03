import 'package:fisioterapia_pelvica/core/error/result.dart';

/// Contract every domain use case implements.
///
/// [Output] is the returned data on success, [Params] is the input the
/// use case needs. Use [NoParams] when a use case takes no arguments.
abstract class UseCase<Output, Params> {
  Future<Result<Output>> call(Params params);
}

class NoParams {
  const NoParams();
}
