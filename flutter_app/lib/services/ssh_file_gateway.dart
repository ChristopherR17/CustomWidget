/// Gateway de gestión de conexiones SSH y operaciones con archivos.
/// Proporciona funcionalidades para conectarse a servidores SSH, explorar archivos y gestionar permisos.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/remote_node.dart';
import '../state/remote_session_state.dart';
import '../utils/remote_file_utils.dart';
import 'app_logger.dart';

/// Clase que gestiona conexiones SSH y operaciones de archivos.
/// Proporciona métodos para conectar, explorar y manipular archivos en servidores remotos.
class SshFileGateway {
  SSHClient? _client;
  SftpClient? _sftp;

  bool shouldReconnect = true;

  /// Abre una conexión SSH con el servidor especificado.
  /// Retorna true si la conexión es exitosa, false en caso contrario.
  Future<bool> openConnection(String username, String ip, int port, String key) async {
    try {
      logger.i("Attempting to connect to $ip:$port");
      final socket = await SSHSocket.connect(ip, port);

      _client = SSHClient(
        socket,
        username: username,
        keepAliveInterval: const Duration(seconds: 30),
        identities: [...SSHKeyPair.fromPem(await loadPrivateKey(key))],
      );

      logger.i("Connected to $ip:$port");
      sshSessionActive = true;
      return true;
    } catch (e) {
      logger.e("Connection error: $e");
      return false;
    }
  }

  /// Establece o elimina un bit de permiso para un archivo remoto.
  /// Los permisos se especifican en formato 'NX' donde N es el grupo (1-3) y X es el tipo (r/w/x).
  Future<void> setPermissionFlag(
    String filePath,
    String permission,
    bool add,
  ) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();

      final attrs = await _sftp!.stat(filePath);
      int mode = attrs.mode?.value ?? 0;

      int permBit = 0;

      switch (permission) {
        case '1r':
          permBit = 0x100;
          break;
        case '1w':
          permBit = 0x80;
          break;
        case '1x':
          permBit = 0x40;
          break;
        case '2r':
          permBit = 0x20;
          break;
        case '2w':
          permBit = 0x10;
          break;
        case '2x':
          permBit = 0x8;
          break;
        case '3r':
          permBit = 0x4;
          break;
        case '3w':
          permBit = 0x2;
          break;
        case '3x':
          permBit = 0x1;
          break;
      }

      if (add) {
        mode |= permBit;
      } else {
        mode &= ~permBit;
      }

      await _sftp!.setStat(
        filePath,
        SftpFileAttrs(mode: SftpFileMode.value(mode)),
      );

      logger.i("Permisos actualizados para $filePath");
    } catch (e) {
      logger.e("Error cambiando permisos: $e");
      _sftp = null;
    }
  }

  /// Renombra un archivo o directorio en el servidor remoto.
  Future<void> renameRemoteNode(String oldPath, String newPath) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();

      await _sftp!.rename(oldPath, newPath);
      logger.i("Archivo renombrado de $oldPath a $newPath");
    } catch (e) {
      logger.e("Error renombrando archivo: $e");
      _sftp = null;
    }
  }

  final _remotePathContext = p.Context(style: p.Style.posix);

  /// Descarga un archivo o directorio remoto.
  /// Los directorios se descargan comprimidos como ZIP.
  Future<void> downloadRemoteNode(String remotePath) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();
      final stat = await _sftp!.stat(remotePath);
      final downloadsDir = await getDownloadsDirectory();

      if (stat.isDirectory) {
        await _downloadFolderAsZip(remotePath, downloadsDir!.path);
      } else {
        await _downloadSingleFile(remotePath, downloadsDir!.path);
      }
    } catch (e) {
      logger.e("Error en descarga: $e");
    }
  }

  /// Sube un archivo local al servidor remoto.
  Future<void> uploadRemoteFile(String localPath, String remotePath) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();

      final localFile = File(localPath);
      final fileName = p.basename(localPath);
      final remoteFilePath = p.posix.join(remotePath, fileName);

      logger.i("Subiendo archivo: $fileName a $remoteFilePath");

      final remoteFile = await _sftp!.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write,
      );

      final stream = localFile.openRead().map(
        (list) => Uint8List.fromList(list),
      );

      await remoteFile.write(stream);

      logger.i("Archivo subido exitosamente: $remoteFilePath");
    } catch (e) {
      logger.e("Error subiendo archivo: $e");
      _sftp = null;
    }
  }

  Future<void> _downloadSingleFile(String remotePath, String localDir) async {
    final fileName = _remotePathContext.basename(remotePath);
    final localPath = p.join(localDir, fileName);

    logger.i("Descargando archivo individual: $fileName");

    final remoteFile = await _sftp!.open(remotePath);
    final localFile = File(localPath);
    final ios = localFile.openWrite();

    await ios.addStream(remoteFile.read());
    await ios.close();

    logger.i("Archivo guardado en: $localPath");
  }

  Future<void> _downloadFolderAsZip(String remotePath, String localDir) async {
    final folderName = p.posix.basename(remotePath);
    final zipName =
        "${folderName}_${DateTime.now().millisecondsSinceEpoch}.zip";

    final remoteZipPath = "~/$zipName";
    final localZipPath = p.join(localDir, zipName);

    try {
      logger.i('Comprimiendo carpeta en el servidor...');

      final parentDir = p.posix.dirname(remotePath);

      await _client!.execute(
        'cd "$parentDir" && zip -r "$remoteZipPath" "$folderName"',
      );

      _sftp ??= await _client!.sftp();

      logger.i('Descargando ZIP...');

      final remoteFile = await _sftp!.open(zipName);
      final localFile = File(localZipPath);

      final ios = localFile.openWrite();
      await ios.addStream(remoteFile.read());
      await ios.close();

      logger.i('Descomprimiendo localmente...');

      final bytes = File(localZipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final String filename = file.name;
        final String destPath = p.join(localDir, filename);

        if (file.isFile) {
          final data = file.content as List<int>;

          File(destPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory(destPath).createSync(recursive: true);
        }
      }

      logger.i('Limpiando archivos temporales...');

      await _client!.execute('rm "$remoteZipPath"');

      if (await File(localZipPath).exists()) {
        await File(localZipPath).delete();
      }

      logger.i('¡Carpeta descargada y descomprimida con éxito!');
    } catch (e) {
      logger.e('Fallo en proceso ZIP: $e');
      rethrow;
    }
  }

  /// Elimina un archivo o directorio remoto.
  Future<void> deleteRemoteNode(String filePath) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();

      await _sftp!.remove(filePath);

      logger.i("Archivo eliminado: $filePath");
    } catch (e) {
      logger.e("Error eliminando archivo: $e");
      _sftp = null;
    }
  }

  /// Descarga una carpeta remota como archivo ZIP.
  Future<void> downloadFolderArchive(String remotePath) async {
    if (_client == null) return;

    final String baseName = p.basename(remotePath);
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String zipName = "${baseName}_$timeStamp.zip";

    _sftp ??= await _client!.sftp();

    final downloadsDir = await getDownloadsDirectory();
    final localZipPath = p.join(downloadsDir!.path, zipName);

    try {
      logger.i('Comprimiendo en el servidor...');

      final parentDir = p.dirname(remotePath);
      final folderName = p.basename(remotePath);

      final safeParent = parentDir.replaceAll('"', '\\"');
      final safeFolder = folderName.replaceAll('"', '\\"');
      final safeZipName = zipName.replaceAll('"', '\\"');

      final zipCommand =
          'cd "$safeParent" && zip -r "$safeZipName" "$safeFolder" && pwd';

      logger.i('Ejecutando comando: $zipCommand');

      final result = await _client!.execute(zipCommand);

      logger.i('Resultado del comando: $result');

      final remoteZipPath = p.join(parentDir, zipName);

      logger.i('Intentando abrir ZIP desde: $remoteZipPath');
      logger.i('Descargando ZIP desde el servidor...');

      final remoteFile = await _sftp!.open(remoteZipPath);
      final localFile = File(localZipPath);
      final ios = localFile.openWrite();

      await ios.addStream(remoteFile.read());
      await ios.close();

      final extractDir = Directory(p.join(downloadsDir.path, baseName));

      if (!extractDir.existsSync()) {
        extractDir.createSync(recursive: true);
      }

      logger.i('Descomprimiendo localmente en ${extractDir.path}...');

      final bytes = File(localZipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        final destPath = p.join(extractDir.path, filename);

        if (file.isFile) {
          File(destPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(destPath).createSync(recursive: true);
        }
      }

      await _client!.execute('rm "${remoteZipPath}"').catchError((_) => {});

      if (await File(localZipPath).exists()) {
        await File(localZipPath).delete();
      }

      logger.i('¡Éxito! Archivos guardados en ${extractDir.path}');
    } catch (e) {
      logger.e('Error descargando/comprimiendo: $e');

      final zipPath = p.join(p.dirname(remotePath), "${baseName}_*.zip");
      await _client!.execute('rm $zipPath').catchError((_) => {});
    }
  }

  /// Obtiene el listado de archivos en un directorio remoto.
  /// Actualiza la lista global de nodos remotos.
  Future<void> fetchDirectory(String path) async {
    if (_client == null) return;

    try {
      _sftp ??= await _client!.sftp();

      final items = await _sftp!.listdir(path);

      remoteNodes.clear();

      for (final item in items) {
        remoteNodes.add(
          RemoteNode(
            name: item.filename,
            isDirectory: item.attr.isDirectory,
            isImage: hasImageExtension(item.filename),
            permissions: formatPermissionBits(item.attr.mode?.value),
          ),
        );
      }
    } catch (e) {
      logger.e("Error listando archivos: $e");
      _sftp = null;
    }
  }

  /// Carga la clave privada SSH desde el directorio .ssh del usuario.
  Future<String> loadPrivateKey(String file) async {
    String home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']!;

    String keyPath = p.join(home, '.ssh', file);

    File keyFile = File(keyPath);

    if (await keyFile.exists()) {
      return await keyFile.readAsString();
    } else {
      throw Exception("Private key file not found: $keyPath");
    }
  }

  /// Detecta el tipo de tiempo de ejecución del proyecto (Node, Java, etc.).
  /// Busca archivos típicos como package.json, pom.xml, build.gradle.
  Future<String?> detectProjectRuntime(String path) async {
    if (_client == null) return null;

    try {
      _sftp ??= await _client!.sftp();

      final items = await _sftp!.listdir(path);

      for (final item in items) {
        if (item.filename == 'package.json') return 'node';

        if (item.filename == 'pom.xml' ||
            item.filename == 'build.gradle' ||
            item.filename == 'build.gradle.kts') {
          return 'java';
        }
      }

      return null;
    } catch (e) {
      logger.e("Error checking server type: $e");
      return null;
    }
  }

  /// Ejecuta un comando en el servidor remoto.
  Future<void> runCommand(String command) async {
    if (_client == null) return;

    try {
      final session = await _client!.execute(command);

      if (!command.trim().endsWith('&')) {
        final output = utf8.decode(
          await session.stdout.fold(
            <int>[],
            (previous, element) => previous..addAll(element),
          ),
        );

        logger.i("Command executed: $command, output: $output");
      } else {
        logger.i("Background command executed: $command");
      }
    } catch (e) {
      logger.e("Error executing command: $e");
    }
  }

  /// Verifica si el tiempo de ejecución está escuchando en su puerto predeterminado.
  /// Retorna true si el servidor está activo, false en caso contrario.
  Future<bool> isRuntimeListening(String type, String path) async {
    if (_client == null) return false;

    try {
      String port;

      if (type == 'node') {
        port = '3000';
      } else if (type == 'java') {
        port = '8080';
      } else {
        return false;
      }

      final command = 'ss -tln | grep :$port || netstat -tln | grep :$port';
      final session = await _client!.execute(command);

      final output = utf8.decode(
        await session.stdout.fold(
          <int>[],
          (previous, element) => previous..addAll(element),
        ),
      );

      return output.trim().isNotEmpty;
    } catch (e) {
      logger.e("Error checking server status: $e");
      return false;
    }
  }
}

