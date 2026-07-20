class RoomSpatialDTO {
  final String id;
  final String definitionID;
  final String? ownerID;

  RoomSpatialDTO({
    required this.id,
    required this.definitionID,
    this.ownerID,
  });

  factory RoomSpatialDTO.fromJson(Map<String, dynamic> json) {
    return RoomSpatialDTO(
      id: json['id'] ?? '',
      definitionID: json['definitionID'] ?? '',
      ownerID: json['ownerID'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'definitionID': definitionID,
    'ownerID': ownerID,
  };
}

class ComponentInstanceDTO {
  // Add component properties based on your backend definition if available
  ComponentInstanceDTO();

  factory ComponentInstanceDTO.fromJson(Map<String, dynamic> json) {
    return ComponentInstanceDTO();
  }

  Map<String, dynamic> toJson() => {};
}

class EntityInstanceDTO {
  final String id;
  final String definitionID;
  final List<ComponentInstanceDTO> components;

  EntityInstanceDTO({
    required this.id,
    required this.definitionID,
    required this.components,
  });

  factory EntityInstanceDTO.fromJson(Map<String, dynamic> json) {
    return EntityInstanceDTO(
      id: json['id'] ?? '',
      definitionID: json['definitionID'] ?? '',
      components: (json['components'] as List<dynamic>?)
          ?.map((e) => ComponentInstanceDTO.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'definitionID': definitionID,
    'components': components.map((e) => e.toJson()).toList(),
  };
}

class RoomInstanceDTO {
  final RoomSpatialDTO room;
  final List<EntityInstanceDTO> entities;

  RoomInstanceDTO({
    required this.room,
    required this.entities,
  });

  factory RoomInstanceDTO.fromJson(Map<String, dynamic> json) {
    return RoomInstanceDTO(
      room: RoomSpatialDTO.fromJson(json['room'] ?? {}),
      entities: (json['entities'] as List<dynamic>?)
          ?.map((e) => EntityInstanceDTO.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'room': room.toJson(),
    'entities': entities.map((e) => e.toJson()).toList(),
  };
}

// ─────────────────────────────
// Real-Time SignalR Event DTOs
// ─────────────────────────────

class TelemetryEventDTO {
  final String code;
  final String message;
  final DateTime timestamp;
  final String severity;

  TelemetryEventDTO({
    required this.code,
    required this.message,
    required this.timestamp,
    required this.severity,
  });

  factory TelemetryEventDTO.fromJson(Map<String, dynamic> json) {
    return TelemetryEventDTO(
      code: json['code'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      severity: json['severity'] ?? '',
    );
  }
}

class RoomStateChangedDTO {
  final String roomSpatialID;
  final String previousState;
  final String newState;

  RoomStateChangedDTO({
    required this.roomSpatialID,
    required this.previousState,
    required this.newState,
  });

  factory RoomStateChangedDTO.fromJson(Map<String, dynamic> json) {
    return RoomStateChangedDTO(
      roomSpatialID: json['roomSpatialID'] ?? '',
      previousState: json['previousState'] ?? '',
      newState: json['newState'] ?? '',
    );
  }
}

class RoomSyncChangedDTO {
  final RoomSpatialDTO roomSpatial;
  final bool isLoaded;

  RoomSyncChangedDTO({
    required this.roomSpatial,
    required this.isLoaded,
  });

  factory RoomSyncChangedDTO.fromJson(Map<String, dynamic> json) {
    return RoomSyncChangedDTO(
      roomSpatial: RoomSpatialDTO.fromJson(json['roomSpatial'] ?? {}),
      isLoaded: json['isLoaded'] ?? false,
    );
  }
}

class UserConnectionChangedDTO {
  final String userID;
  final String? connectionID;

  UserConnectionChangedDTO({
    required this.userID,
    this.connectionID,
  });

  factory UserConnectionChangedDTO.fromJson(Map<String, dynamic> json) {
    return UserConnectionChangedDTO(
      userID: json['userID'] ?? '',
      connectionID: json['connectionID'],
    );
  }
}

class UserSessionChangedDTO {
  final String userID;
  final String? playerInstanceID;

  UserSessionChangedDTO({
    required this.userID,
    this.playerInstanceID,
  });

  factory UserSessionChangedDTO.fromJson(Map<String, dynamic> json) {
    return UserSessionChangedDTO(
      userID: json['userID'] ?? '',
      playerInstanceID: json['playerInstanceID'],
    );
  }
}