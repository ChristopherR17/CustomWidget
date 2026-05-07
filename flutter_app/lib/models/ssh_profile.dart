class SshProfile {
  final int id;
  final String alias;
  final String host;
  final int port;
  final String username;
  final String privateKeyName;

  const SshProfile({
    required this.id,
    required this.alias,
    required this.host,
    required this.port,
    required this.username,
    required this.privateKeyName,
  });

  SshProfile copyWith({
    int? id,
    String? alias,
    String? host,
    int? port,
    String? username,
    String? privateKeyName,
  }) {
    return SshProfile(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      privateKeyName: privateKeyName ?? this.privateKeyName,
    );
  }

  factory SshProfile.fromJson(Map<String, dynamic> json) {
    return SshProfile(
      id: json['id'] as int,
      alias: json['alias'] as String? ?? json['name'] as String? ?? 'Servidor',
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      privateKeyName: json['privateKeyName'] as String? ?? json['key'] as String? ?? 'id_rsa',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'host': host,
        'port': port,
        'username': username,
        'privateKeyName': privateKeyName,
      };
}
