import 'package:signalr_netcore/signalr_client.dart';
import '../services/storage_service.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final StorageService _storageService;

  SignalRService(this._storageService) {
    // Configured with your direct Railway backend base URL + hub route
    _hubConnection = HubConnectionBuilder()
        .withUrl(
      'https://gamems-apirailwayinternal-production.up.railway.app/hubs/admin',
      options: HttpConnectionOptions(
        accessTokenFactory: () async {
          final token = await _storageService.getToken();
          return token ?? '';
        },
      ),
    )
        .withAutomaticReconnect()
        .build();
  }

  bool get isConnected => _hubConnection.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_hubConnection.state == HubConnectionState.Disconnected) {
      await _hubConnection.start();
    }
  }

  void on(String methodName, void Function(List<Object?>? arguments) method) {
    _hubConnection.on(methodName, method);
  }

  void off(String methodName) {
    _hubConnection.off(methodName);
  }

  Future<void> disconnect() async {
    if (_hubConnection.state == HubConnectionState.Connected) {
      await _hubConnection.stop();
    }
  }
}