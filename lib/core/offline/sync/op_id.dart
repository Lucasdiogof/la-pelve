import 'dart:math';

final _random = Random.secure();
int _counter = 0;

/// Id único de operação da fila: tempo + contador + aleatório. Nunca repete,
/// mesmo para duas gravações no mesmo microssegundo (o relógio do aparelho
/// pode ter resolução de milissegundos).
String newOpId() =>
    'op_${DateTime.now().microsecondsSinceEpoch}_${_counter++}_'
    '${_random.nextInt(1 << 32).toRadixString(36)}';
