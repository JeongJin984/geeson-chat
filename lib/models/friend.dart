/// Represents a friend entry similar to KakaoTalk's contact list.
class Friend {
  const Friend({
    required this.code,
    required this.name,
    required this.statusMessage,
  });

  final String code;
  final String name;
  final String statusMessage;

  Friend copyWith({String? code, String? name, String? statusMessage}) {
    return Friend(
      code: code ?? this.code,
      name: name ?? this.name,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
