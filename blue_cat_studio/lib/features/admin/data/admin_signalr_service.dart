import 'dart:async';
import '../../../core/network/signalr_service.dart';
import 'package:blue_cat_studio/models/dtos/admin_dtos.dart';

class AdminSignalRService {
  final SignalRService _signalRService;

  // Stream controllers to broadcast real-time events to your UI / BLoC / Riverpod
  final _telemetryController = StreamController<TelemetryEventDTO>.broadcast();
  final _roomStateController = StreamController<RoomStateChangedDTO>.broadcast();
  final _roomSyncController = StreamController<RoomSyncChangedDTO>.broadcast();
  final _userConnectionController = StreamController<UserConnectionChangedDTO>.broadcast();
  final _userSessionController = StreamController<UserSessionChangedDTO>.broadcast();

  Stream<TelemetryEventDTO> get onTelemetryAlert => _telemetryController.stream;
  Stream<RoomStateChangedDTO> get onRoomStateChanged => _roomStateController.stream;
  Stream<RoomSyncChangedDTO> get onRoomSyncChanged => _roomSyncController.stream;
  Stream<UserConnectionChangedDTO> get onUserConnectionChanged => _userConnectionController.stream;
  Stream<UserSessionChangedDTO> get onUserSessionChanged => _userSessionController.stream;

  AdminSignalRService(this._signalRService);

  Future<void> initHub() async {
    await _signalRService.connect();
    _registerListeners();
  }

  void _registerListeners() {
    // 1. Telemetry Alert
    _signalRService.on('OnTelemetrySended', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _telemetryController.add(TelemetryEventDTO.fromJson(data));
      }
    });

    // 2. Room State Changed
    _signalRService.on('OnRoomStateChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _roomStateController.add(RoomStateChangedDTO.fromJson(data));
      }
    });

    // 3. Room Sync Changed
    _signalRService.on('OnRoomSyncChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _roomSyncController.add(RoomSyncChangedDTO.fromJson(data));
      }
    });

    // 4. User Connection Changed
    _signalRService.on('OnUserConnectionChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _userConnectionController.add(UserConnectionChangedDTO.fromJson(data));
      }
    });

    // 5. User Session Changed
    _signalRService.on('OnUserSessionChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _userSessionController.add(UserSessionChangedDTO.fromJson(data));
      }
    });
  }

  void dispose() {
    _telemetryController.close();
    _roomStateController.close();
    _roomSyncController.close();
    _userConnectionController.close();
    _userSessionController.close();
    _signalRService.disconnect();
  }
}