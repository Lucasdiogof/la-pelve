import 'package:supabase_flutter/supabase_flutter.dart';

String? currentUserName() {
  try {
    final nome =
        Supabase.instance.client.auth.currentUser?.userMetadata?['nome']
            as String?;
    if (nome == null || nome.trim().isEmpty) return null;
    return nome.trim();
  } on Object {
    return null;
  }
}
