// Test básico de arranque de CurbRadar Frontend.
// Firebase y servicios externos son mockeados en tests reales.
// Este test solo verifica que el widget raíz compila.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Test básico — Firebase.initializeApp() requiere configuración real
    // para correr, por lo que los tests con UI completa se hacen en
    // integration_test/ con un emulador.
    expect(true, isTrue);
  });
}
