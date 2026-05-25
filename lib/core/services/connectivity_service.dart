import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityService {
  final _statusController = StreamController<ConnectivityStatus>.broadcast();
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _checkStatus(results.first);
      }
    });
    // Initial check
    Connectivity().checkConnectivity().then((results) {
      if (results.isNotEmpty) {
        _checkStatus(results.first);
      }
    });
  }

  Future<void> _checkStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _statusController.add(ConnectivityStatus.offline);
    } else {
      try {
        final lookup = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
        if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
          _statusController.add(ConnectivityStatus.online);
        } else {
          _statusController.add(ConnectivityStatus.offline);
        }
      } catch (_) {
        _statusController.add(ConnectivityStatus.offline);
      }
    }
  }

  void dispose() {
    _statusController.close();
  }
}
