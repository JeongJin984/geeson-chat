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
}
