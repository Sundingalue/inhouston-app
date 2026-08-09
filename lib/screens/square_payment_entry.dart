/// Este archivo exporta automáticamente la versión correcta del sistema de pago.
/// - En dispositivos móviles: usa `square_payment_platform.dart`
/// - En otras plataformas o durante pruebas: usa `square_payment_stub.dart`

export 'square_payment_stub.dart'
    if (dart.library.io) 'square_payment_platform.dart';
