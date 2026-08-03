import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt sl = GetIt.instance;

/// Registers app-wide singletons. Feature-specific dependencies (data
/// sources, repositories, use cases, blocs) should be registered from each
/// `features/<name>/di/*.dart` and called from here.
Future<void> initDependencies() async {
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
}
