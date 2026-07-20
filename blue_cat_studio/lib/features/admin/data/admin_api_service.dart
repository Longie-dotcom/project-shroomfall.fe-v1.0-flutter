import 'package:blue_cat_studio/core/network/dio_client.dart';
import 'package:blue_cat_studio/models/dtos/admin_dtos.dart';

class AdminApiService {
  final DioClient _dioClient;

  AdminApiService(this._dioClient);

  /// Corresponds to: [HttpGet("room-spatials")] in AdminController
  Future<List<RoomSpatialDTO>> getRoomSpatials() async {
    try {
      final response = await _dioClient.dio.get('/Admin/room-spatials');

      final List<dynamic> data = response.data;
      return data.map((json) => RoomSpatialDTO.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch room spatials: $e');
    }
  }

  /// Corresponds to: [HttpGet("room-instance/{roomSpatailId}")] in AdminController
  Future<RoomInstanceDTO> getRoomInstance(String roomSpatialId) async {
    try {
      final response = await _dioClient.dio.get('/Admin/room-instance/$roomSpatialId');

      return RoomInstanceDTO.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch room instance for ID $roomSpatialId: $e');
    }
  }
}