import 'package:fisioterapia_pelvica/core/error/result.dart';

abstract class UseCase<Output, Params> {
  Future<Result<Output>> call(Params params);
}

class NoParams {
  const NoParams();
}
