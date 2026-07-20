import 'package:flutter/material.dart';
import 'package:blue_cat_studio/core/network/dio_client.dart';
import 'package:blue_cat_studio/core/network/signalr_service.dart';
import 'package:blue_cat_studio/core/services/storage_service.dart';
import 'package:blue_cat_studio/features/admin/data/admin_api_service.dart';
import 'package:blue_cat_studio/features/admin/data/admin_signalr_service.dart';
import 'package:blue_cat_studio/models/dtos/admin_dtos.dart';
import 'package:blue_cat_studio/features/auth/presentation/login_screen.dart';
import 'package:blue_cat_studio/features/admin/presentation/admin_detail_screen.dart';
import 'package:blue_cat_studio/features/admin/presentation/telemetry_toast.dart';

class UserSessionStateItem {
  final String userID;
  String? connectionID;
  String? playerInstanceID;

  UserSessionStateItem({
    required this.userID,
    this.connectionID,
    this.playerInstanceID,
  });
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final StorageService _storageService;
  late final DioClient _dioClient;
  late final AdminApiService _adminApiService;
  late final SignalRService _signalRService;
  late final AdminSignalRService _adminSignalRService;

  List<RoomSpatialDTO> _rooms = [];
  final Map<String, String> _roomStates = {};
  final Map<String, UserSessionStateItem> _usersMap = {};

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSignalRConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeServicesAndFetchData();
  }

  void _initializeServicesAndFetchData() {
    _storageService = StorageService();
    _dioClient = DioClient(_storageService);
    _adminApiService = AdminApiService(_dioClient);
    _signalRService = SignalRService(_storageService);
    _adminSignalRService = AdminSignalRService(_signalRService);

    _initRealtimeHub();
    _fetchRoomSpatials();
  }

  Future<void> _initRealtimeHub() async {
    try {
      await _adminSignalRService.initHub();
      if (mounted) {
        setState(() {
          _isSignalRConnected = _signalRService.isConnected;
        });
      }

      _adminSignalRService.onTelemetryAlert.listen((telemetry) {
        debugPrint('🔔 [SignalR] Telemetry received: code=${telemetry.code}, severity=${telemetry.severity}, message=${telemetry.message}');

        if (!mounted) {
          debugPrint('⚠️ [SignalR] Widget is NOT mounted. Dropping telemetry alert.');
          return;
        }

        debugPrint('✅ [SignalR] Showing TelemetryToast now...');

        TelemetryToast.show(
          context,
          severity: telemetry.severity,
          code: telemetry.code,
          message: telemetry.message,
        );
      });

      _adminSignalRService.onRoomStateChanged.listen((event) {
        if (!mounted) return;
        setState(() {
          _roomStates[event.roomSpatialID] = event.newState;
        });
      });

      _adminSignalRService.onUserConnectionChanged.listen((event) {
        if (!mounted) return;
        setState(() {
          final userItem = _usersMap.putIfAbsent(
            event.userID,
                () => UserSessionStateItem(userID: event.userID),
          );
          userItem.connectionID = event.connectionID;
        });
      });

      _adminSignalRService.onUserSessionChanged.listen((event) {
        if (!mounted) return;
        setState(() {
          final userItem = _usersMap.putIfAbsent(
            event.userID,
                () => UserSessionStateItem(userID: event.userID),
          );
          userItem.playerInstanceID = event.playerInstanceID;
        });
      });

      _adminSignalRService.onRoomSyncChanged.listen((event) {
        if (!mounted) return;
        setState(() {
          final index = _rooms.indexWhere((r) => r.id == event.roomSpatial.id);
          if (index >= 0) {
            _rooms[index] = event.roomSpatial;
          } else if (event.isLoaded) {
            _rooms.insert(0, event.roomSpatial);
          }
        });
      });
    } catch (e) {
      debugPrint('SignalR Connection Error: $e');
    }
  }

  Future<void> _fetchRoomSpatials() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final rooms = await _adminApiService.getRoomSpatials();

      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _storageService.clearToken();
    _adminSignalRService.dispose();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _adminSignalRService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersList = _usersMap.values.toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/logo-3.png',
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF0369A1),
            unselectedLabelColor: Colors.lightBlue.shade300,
            indicatorColor: const Color(0xFF0284C7),
            tabs: const [
              Tab(icon: Icon(Icons.meeting_room), text: 'Rooms'),
              Tab(icon: Icon(Icons.people_outline), text: 'Users & Sessions'),
            ],
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Chip(
                  avatar: CircleAvatar(
                    backgroundColor: _isSignalRConnected ? Colors.green : Colors.orange,
                    radius: 4,
                  ),
                  backgroundColor: Colors.lightBlue.shade50,
                  label: Text(
                    _isSignalRConnected ? 'Live' : 'Connecting',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF0369A1)),
              onPressed: _fetchRoomSpatials,
              tooltip: 'Refresh Rooms',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF0369A1)),
              onPressed: _handleLogout,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
            : _errorMessage != null
            ? _buildErrorView()
            : TabBarView(
          children: [
            _buildRoomsTab(),
            _buildUsersTab(usersList),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text('Error: $_errorMessage', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF0369A1))),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
              onPressed: _fetchRoomSpatials,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    if (_rooms.isEmpty) {
      return const Center(
        child: Text('No room spatials found.', style: TextStyle(color: Color(0xFF0284C7))),
      );
    }

    return ListView.builder(
      itemCount: _rooms.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final room = _rooms[index];
        final runtimeState = _roomStates[room.id] ?? 'Unknown';

        return Card(
          elevation: 2,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDetailScreen(
                    roomSpatialId: room.id,
                    roomTitle: room.definitionID,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          room.definitionID,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'State: $runtimeState',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.lightBlue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Room ID: ${room.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.lightBlue.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Owner ID: ${room.ownerID ?? "None"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.lightBlue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(List<UserSessionStateItem> usersList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            elevation: 2,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Users',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total: ${usersList.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: usersList.isEmpty
              ? const Center(
            child: Text(
              'No active user connections or sessions tracked yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF0284C7), fontSize: 12),
            ),
          )
              : ListView.builder(
            itemCount: usersList.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final user = usersList[index];
              final isOnline = user.connectionID != null && user.connectionID!.isNotEmpty;

              return Card(
                elevation: 2,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.userID,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? Colors.green : Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Connection: ${user.connectionID ?? "-"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.lightBlue.shade800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Player: ${user.playerInstanceID ?? "-"}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.lightBlue.shade800),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}