import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/app_enums.dart';
import '../models/disk_node.dart';
import '../models/remote_entry.dart';
import '../models/ssh_profile.dart';

class SshWorkspace {
  SSHClient? _client;
  SftpClient? _sftp;
  SshProfile? _profile;

  bool get isConnected => _client != null;
  SshProfile? get profile => _profile;

  Future<void> connect(SshProfile profile) async {
    await close();
    final socket = await SSHSocket.connect(profile.host, profile.port);
    final key = await _readPrivateKey(profile.privateKeyName);
    _client = SSHClient(
      socket,
      username: profile.username,
      identities: SSHKeyPair.fromPem(key),
    );
    _sftp = await _client!.sftp();
    _profile = profile;
  }

  Future<void> close() async {
    _sftp?.close();
    _client?.close();
    _sftp = null;
    _client = null;
    _profile = null;
  }

  Future<String> _readPrivateKey(String fileName) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) throw Exception('No se ha podido encontrar la carpeta HOME del usuario.');
    final keyFile = File(p.join(home, '.ssh', fileName));
    if (!await keyFile.exists()) throw Exception('No existe la clave privada: ${keyFile.path}');
    return keyFile.readAsString();
  }

  Future<SftpClient> _safeSftp() async {
    final client = _client;
    if (client == null) throw StateError('No hay conexión SSH activa.');
    return _sftp ??= await client.sftp();
  }

  Future<List<RemoteEntry>> list(String remotePath) async {
    final sftp = await _safeSftp();
    final items = await sftp.listdir(remotePath);
    final visible = items.where((item) => item.filename != '.' && item.filename != '..').map((item) {
      return RemoteEntry(
        name: item.filename,
        isDirectory: item.attr.isDirectory,
        size: item.attr.size ?? 0,
        mode: item.attr.mode?.value,
        modifiedAt: item.attr.modifyTime == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(item.attr.modifyTime! * 1000),
      );
    }).toList();
    visible.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return visible;
  }

  Future<void> rename(String oldPath, String newPath) async {
    final sftp = await _safeSftp();
    await sftp.rename(oldPath, newPath);
  }

  Future<void> delete(String remotePath, {required bool isDirectory}) async {
    if (isDirectory) {
      await run('rm -rf ${_q(remotePath)}');
    } else {
      final sftp = await _safeSftp();
      await sftp.remove(remotePath);
    }
  }

  Future<Directory> _ubuntuDownloadsDirectory() async {
    final detected = await getDownloadsDirectory();
    if (detected != null) return detected;

    final home = Platform.environment['HOME'];
    if (home != null) {
      final spanish = Directory(p.join(home, 'Descargas'));
      if (await spanish.exists()) return spanish;

      final english = Directory(p.join(home, 'Downloads'));
      if (await english.exists()) return english;
    }

    return getApplicationDocumentsDirectory();
  }

  Future<void> download(String remotePath, {required bool isDirectory}) async {
    final downloads = await _ubuntuDownloadsDirectory();
    if (isDirectory) {
      await _downloadDirectoryAsZip(remotePath, downloads.path);
      return;
    }
    final sftp = await _safeSftp();
    final remoteFile = await sftp.open(remotePath);
    final localFile = File(p.join(downloads.path, p.posix.basename(remotePath)));
    final sink = localFile.openWrite();
    await sink.addStream(remoteFile.read());
    await sink.close();
  }

  Future<void> _downloadDirectoryAsZip(String remotePath, String localDir) async {
    final base = p.posix.basename(remotePath);
    final zipName = '${base}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final parent = p.posix.dirname(remotePath);
    final remoteZip = p.posix.join(parent, zipName);
    await run('cd ${_q(parent)} && zip -qr ${_q(zipName)} ${_q(base)}');

    final sftp = await _safeSftp();
    final remoteFile = await sftp.open(remoteZip);
    final localZip = File(p.join(localDir, zipName));
    final sink = localZip.openWrite();
    await sink.addStream(remoteFile.read());
    await sink.close();
    await run('rm -f ${_q(remoteZip)}');
  }

  Future<void> uploadFile(String localPath, String remoteDirectory) async {
    final sftp = await _safeSftp();
    final name = p.basename(localPath);
    final remotePath = p.posix.join(remoteDirectory, name);
    final localFile = File(localPath);
    final remoteFile = await sftp.open(remotePath, mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate);
    await remoteFile.write(Stream<Uint8List>.value(await localFile.readAsBytes()));
    await remoteFile.close();

    if (name.toLowerCase().endsWith('.zip')) {
      await unzipRemote(remotePath, removeZip: true);
    }
  }

  Future<void> uploadDirectoryAsZip(String localDirectory, String remoteDirectory) async {
    final source = Directory(localDirectory);
    if (!await source.exists()) throw Exception('La carpeta local no existe.');
    final temp = await getTemporaryDirectory();
    final zipName = '${p.basename(localDirectory)}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipPath = p.join(temp.path, zipName);
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    encoder.addDirectory(source);
    encoder.close();
    await uploadFile(zipPath, remoteDirectory);
    await File(zipPath).delete().catchError((_) {});
  }

  Future<void> unzipRemote(String zipPath, {bool removeZip = false}) async {
    final dir = p.posix.dirname(zipPath);
    final name = p.posix.basename(zipPath);
    final remove = removeZip ? ' && rm -f ${_q(name)}' : '';
    await run('cd ${_q(dir)} && unzip -oq ${_q(name)}$remove');
  }

  Future<void> chmod(String remotePath, String symbolicMode) async {
    await run('chmod $symbolicMode ${_q(remotePath)}');
  }

  Future<ProjectKind> detectProject(String remotePath) async {
    final names = (await list(remotePath)).map((item) => item.name).toSet();
    if (names.contains('package.json')) return ProjectKind.node;
    if (names.contains('pom.xml') || names.contains('build.gradle') || names.contains('build.gradle.kts')) {
      return ProjectKind.java;
    }
    if (names.any((name) => name.endsWith('.jar'))) return ProjectKind.java;
    return ProjectKind.unknown;
  }

  Future<RemoteServiceState> serviceState(String remotePath) async {
    final result = await run('cd ${_q(remotePath)} && test -f .remote_service.pid && ps -p "\$(cat .remote_service.pid)" -o pid=');
    return result.trim().isEmpty ? RemoteServiceState.stopped : RemoteServiceState.running;
  }

  Future<void> startService(String remotePath, ProjectKind kind) async {
    final command = switch (kind) {
      ProjectKind.node => 'npm install && nohup npm start > remote_service.log 2>&1 & echo \$! > .remote_service.pid',
      ProjectKind.java => _javaStartCommand(),
      ProjectKind.unknown => throw Exception('No se ha detectado un proyecto NodeJS o Java.'),
    };
    await run('cd ${_q(remotePath)} && $command');
  }

  String _javaStartCommand() {
    return 'JAR=\$(ls *.jar 2>/dev/null | head -n 1); '
        'if [ -n "\$JAR" ]; then nohup java -jar "\$JAR" > remote_service.log 2>&1 & echo \$! > .remote_service.pid; '
        'elif [ -f pom.xml ]; then nohup mvn spring-boot:run > remote_service.log 2>&1 & echo \$! > .remote_service.pid; '
        'else nohup ./gradlew bootRun > remote_service.log 2>&1 & echo \$! > .remote_service.pid; fi';
  }

  Future<void> stopService(String remotePath) async {
    await run('cd ${_q(remotePath)} && if [ -f .remote_service.pid ]; then kill "\$(cat .remote_service.pid)" 2>/dev/null || true; rm -f .remote_service.pid; fi');
  }

  Future<void> restartService(String remotePath, ProjectKind kind) async {
    await stopService(remotePath);
    await Future<void>.delayed(const Duration(seconds: 1));
    await startService(remotePath, kind);
  }

  Future<void> enablePort80Redirect(int targetPort) async {
    await run('sudo iptables -t nat -C PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $targetPort || sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $targetPort');
  }

  Future<void> disablePort80Redirect(int targetPort) async {
    await run('sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $targetPort || true');
  }

  Future<DiskNode> diskTree(String remotePath, {int depth = 2}) async {
    final output = await run('du -ab --max-depth=$depth ${_q(remotePath)} 2>/dev/null | sort -nr | head -n 80');
    final rootName = p.posix.basename(remotePath).isEmpty ? remotePath : p.posix.basename(remotePath);
    final root = _MutableDiskNode(rootName, 0);
    for (final line in const LineSplitter().convert(output)) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final bytes = int.tryParse(parts.first) ?? 0;
      final path = parts.sublist(1).join(' ');
      final relative = p.posix.relative(path, from: remotePath);
      if (relative == '.') {
        root.bytes = bytes;
        continue;
      }
      root.insert(relative.split('/'), bytes);
    }
    return root.freeze();
  }

  Future<String> run(String command) async {
    final client = _client;
    if (client == null) throw StateError('No hay conexión SSH activa.');
    final session = await client.execute(command);
    final stdout = await session.stdout.fold<List<int>>([], (buffer, data) => buffer..addAll(data));
    final stderr = await session.stderr.fold<List<int>>([], (buffer, data) => buffer..addAll(data));
    final exitCode = await session.exitCode;
    if (exitCode != 0) {
      final message = utf8.decode(stderr).trim();
      if (message.isNotEmpty) throw Exception(message);
    }
    return utf8.decode(stdout);
  }

  String _q(String value) => "'${value.replaceAll("'", "'\\''")}'";
}

class _MutableDiskNode {
  _MutableDiskNode(this.name, this.bytes);
  final String name;
  int bytes;
  final Map<String, _MutableDiskNode> children = {};

  void insert(List<String> parts, int bytes) {
    if (parts.isEmpty) return;
    final head = parts.first;
    final node = children.putIfAbsent(head, () => _MutableDiskNode(head, bytes));
    node.bytes = bytes;
    node.insert(parts.skip(1).toList(), bytes);
  }

  DiskNode freeze() => DiskNode(
        name: name,
        bytes: bytes,
        children: children.values.map((child) => child.freeze()).toList(),
      );
}
