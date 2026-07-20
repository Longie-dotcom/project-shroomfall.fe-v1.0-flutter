import 'package:flutter/material.dart';
import 'package:blue_cat_studio/core/network/dio_client.dart';
import 'package:blue_cat_studio/core/services/storage_service.dart';
import 'package:blue_cat_studio/features/admin/data/admin_api_service.dart';
import 'package:blue_cat_studio/models/dtos/admin_dtos.dart';

class AdminDetailScreen extends StatefulWidget {
  final String roomSpatialId;
  final String roomTitle;

  const AdminDetailScreen({
    super.key,
    required this.roomSpatialId,
    required this.roomTitle,
  });

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  late final AdminApiService _adminApiService;
  late Future<RoomInstanceDTO> _roomInstanceFuture;

  @override
  void initState() {
    super.initState();
    final storageService = StorageService();
    final dioClient = DioClient(storageService);
    _adminApiService = AdminApiService(dioClient);
    _roomInstanceFuture = _adminApiService.getRoomInstance(widget.roomSpatialId);
  }

  void _retryFetch() {
    setState(() {
      _roomInstanceFuture = _adminApiService.getRoomInstance(widget.roomSpatialId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomTitle.isNotEmpty ? widget.roomTitle : 'Room Details'),
      ),
      body: FutureBuilder<RoomInstanceDTO>(
        future: _roomInstanceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load room instance:\n${snapshot.error}'.replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _retryFetch,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No room instance data found.'));
          }

          final roomInstance = snapshot.data!;
          final spatial = roomInstance.room;
          final entities = roomInstance.entities;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Room Spatial Information Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.spatial_audio_off, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            'Room Spatial Info',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Room ID', spatial.id),
                      const SizedBox(height: 12),
                      _buildDetailRow('Definition ID', spatial.definitionID),
                      const SizedBox(height: 12),
                      _buildDetailRow('Owner ID', spatial.ownerID ?? 'Unassigned / System'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Entities Section Header
              Row(
                children: [
                  Text(
                    'Active Entities (${entities.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Entity List View
              if (entities.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No entities currently active in this room.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                ...entities.map((entity) => Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.widgets_outlined),
                    title: Text('Entity: ${entity.definitionID}'),
                    subtitle: Text('ID: ${entity.id}\nComponents: ${entity.components.length} attached'),
                    isThreeLine: true,
                  ),
                )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}