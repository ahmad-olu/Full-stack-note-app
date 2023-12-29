import 'dart:convert';

class ApiKey {
  final String id;
  final String name;
  final String? apiKey;
  final List<String> scope;
  final String prefix;

  ApiKey({
    required this.id,
    required this.name,
    required this.scope,
    required this.apiKey,
    required this.prefix,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'api_key': apiKey,
      'scope': scope,
      'prefix': prefix,
    };
  }

  factory ApiKey.fromMap(Map<String, dynamic> map) {
    return ApiKey(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      apiKey: map['api_key'],
      scope: List<String>.from(map['scope']),
      prefix: map['prefix'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ApiKey.fromJson(String source) => ApiKey.fromMap(json.decode(source));
}
