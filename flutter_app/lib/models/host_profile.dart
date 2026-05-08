/// Modelo que representa un perfil de conexión a un servidor remoto.
/// Contiene la información necesaria para establecer una conexión SSH.
class HostProfile {
  /// Identificador único del perfil.
  int id;
  
  /// Nombre descriptivo del servidor.
  String name;
  
  /// Dirección IP o hostname del servidor.
  String ip;
  
  /// Puerto SSH del servidor (por defecto 22).
  int port;
  
  /// Nombre de usuario para la conexión.
  String username;
  
  /// Ruta a la clave privada SSH.
  String key;

  /// Constructor de HostProfile.
  HostProfile({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.username,
    required this.key,
  });

  /// Constructor factory que crea un HostProfile desde un mapa JSON.
  /// Convierte datos JSON a una instancia de HostProfile.
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

  /// Convierte el HostProfile a un mapa JSON.
  /// Utilizado para persistencia y serialización.
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
