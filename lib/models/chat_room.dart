/// Represents a chat room definition that can be created or joined.
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.endpoint,
  });

  final String id;
  final String name;
  final String endpoint;

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: (json['id'] ?? json['roomId'] ?? json['uuid'])?.toString() ?? '',
      name: (json['name'] ?? json['roomName'])?.toString() ?? '',
      endpoint: (json['endpoint'] ?? json['wsUrl'] ?? json['url'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'endpoint': endpoint,
    };
  }
}
