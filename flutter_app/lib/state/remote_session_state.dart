/// Estado global de la sesión remota.
/// Almacena el estado compartido de la sesión SSH, perfiles de host y nodos remotos.

import '../models/host_profile.dart';
import '../models/remote_node.dart';
import '../services/ssh_file_gateway.dart';

/// Instancia única del gateway SSH para la gestión de conexiones.
final SshFileGateway sshFileGateway = SshFileGateway();

/// Indicador del estado de la sesión SSH.
bool sshSessionActive = false;

/// Lista de perfiles de hosts disponibles.
List<HostProfile> hostProfiles = [];

/// Lista de nodos remotos (archivos/directorios) en la ruta actual.
List<RemoteNode> remoteNodes = [];

/// Ruta actual seleccionada en el servidor remoto.
String selectedRemotePath = '/';
