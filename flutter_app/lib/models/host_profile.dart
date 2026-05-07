class HostProfile {
  int id;
  String name;
  String ip;
  int port;
  String username;
  String key;

  HostProfile({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.username,
    required this.key,
  });

  factory HostProfile.fromJson(Map<String, dynamic> json) {
    return HostProfile(
      id: json['id'],
      name: json['name'],
      ip: json['host'] ?? json['ip'],
      port: json['port'],
      username: json['username'],
      key: json['key'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': ip,
      'port': port,
      'username': username,
      'key': key,
    };
  }
}
