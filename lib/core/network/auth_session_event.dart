import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSessionEventService {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get onUnauthorized => _controller.stream;

  void notifyUnauthorized(String message) {
    if (!_controller.isClosed) {
      _controller.add(message);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final authSessionEventServiceProvider = Provider<AuthSessionEventService>((
  ref,
) {
  final service = AuthSessionEventService();
  ref.onDispose(service.dispose);
  return service;
});
