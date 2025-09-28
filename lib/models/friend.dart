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

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      code: (json['code'] ?? json['friendCode'])?.toString() ?? '',
      name: (json['name'] ?? json['friendName'])?.toString() ?? '',
      statusMessage: (json['statusMessage'] ?? json['status'])?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'name': name,
      'statusMessage': statusMessage,
    };
  }
}
