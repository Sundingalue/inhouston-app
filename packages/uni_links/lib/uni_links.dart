library uni_links;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Simulación básica del método `getInitialUri` del plugin original.
Future<Uri?> getInitialUri() async {
  const MethodChannel _channel = MethodChannel('uni_links/messages');

  try {
    final String? initialLink = await _channel.invokeMethod<String>('getInitialLink');
    if (initialLink == null) return null;
    return Uri.parse(initialLink);
  } on PlatformException {
    return null;
  }
}
