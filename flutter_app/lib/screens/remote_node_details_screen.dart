import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../models/remote_node.dart';
import '../services/ssh_file_gateway.dart';
import '../state/remote_session_state.dart';
import '../theme/app_palette.dart';

class RemoteNodeDetailsScreen extends StatefulWidget {
  final SshFileGateway manager;
  final RemoteNode file;

  const RemoteNodeDetailsScreen({
    super.key,
    required this.manager,
    required this.file,
  });

  @override
  State<RemoteNodeDetailsScreen> createState() => _RemoteNodeDetailsScreenState();
}

class _RemoteNodeDetailsScreenState extends State<RemoteNodeDetailsScreen> {
  double buttonPadding = 4;
  String? serverType;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();

    if (widget.file.isDirectory) {
      _detectProjectRuntime();
    }
  }

  Future<void> _detectProjectRuntime() async {
    serverType = await widget.manager.detectProjectRuntime(
      p.posix.join(selectedRemotePath, widget.file.name),
    );

    if (serverType != null) {
      await _checkServerStatus();
    }

    setState(() {});
  }

  Future<void> _checkServerStatus() async {
    isRunning = await widget.manager.isRuntimeListening(
      serverType!,
      p.posix.join(selectedRemotePath, widget.file.name),
    );

    setState(() {});
  }

  Future<void> startServer() async {
    String path = p.posix.join(selectedRemotePath, widget.file.name);
    String command;

    if (serverType == 'node') {
      command = 'cd "$path" && nohup npm run dev > /dev/null 2>&1 &';
    } else if (serverType == 'java') {
      command = 'cd "$path" && nohup mvn spring-boot:run > /dev/null 2>&1 &';
    } else {
      return;
    }

    await widget.manager.runCommand(command);

    await Future.delayed(const Duration(seconds: 3));

    await _checkServerStatus();
  }

  Future<void> stopServer() async {
    String process = serverType == 'node' ? 'node' : 'java';

    await widget.manager.runCommand('pkill -f $process');

    await _checkServerStatus();
  }

  Future<void> restartServer() async {
    await stopServer();

    await Future.delayed(const Duration(seconds: 2));

    await startServer();
  }

  Widget permissionButton({
    required String text,
    required int index,
    required String permission,
    required String activeLetter,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: widget.file.permissions[index] == activeLetter
              ? AppPalette.permissionColor
              : AppPalette.noPermissionColor,
          foregroundColor: AppPalette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          setState(() {
            widget.manager.setPermissionFlag(
              p.join(selectedRemotePath, widget.file.name),
              permission,
              widget.file.permissions[index] != activeLetter,
            );

            widget.file.permissions = widget.file.permissions[index] ==
                    activeLetter
                ? widget.file.permissions.replaceRange(index, index + 1, '-')
                : widget.file.permissions.replaceRange(
                    index,
                    index + 1,
                    activeLetter,
                  );

            widget.manager.fetchDirectory(selectedRemotePath);
          });
        },
        child: Text(text),
      ),
    );
  }

  Widget permissionGroup({
    required String title,
    required List<Widget> buttons,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101820),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...buttons.map(
            (button) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: button,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullPath = p.posix.join(selectedRemotePath, widget.file.name);
    final isFolder = widget.file.isDirectory;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.sidebar,
        foregroundColor: Colors.white,
        title: const Text('Detalles del elemento'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isFolder
                          ? AppPalette.primary.withOpacity(0.12)
                          : AppPalette.accent.withOpacity(0.12),
                      child: Icon(
                        isFolder ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                        color: isFolder ? AppPalette.primary : AppPalette.accent,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.file.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.textDark,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fullPath,
                            style: const TextStyle(color: AppPalette.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (serverType != null)
                      Chip(
                        label: Text(isRunning ? 'Activo' : 'Detenido'),
                        backgroundColor: isRunning
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFFE4E6),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones básicas',
                      style: TextStyle(
                        color: AppPalette.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppPalette.background,
                        labelText: 'Renombrar',
                        prefixIcon: const Icon(Icons.drive_file_rename_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        final oldPath = p.join(selectedRemotePath, widget.file.name);
                        final newPath = p.join(selectedRemotePath, value);

                        widget.manager.renameRemoteNode(oldPath, newPath);

                        setState(() {
                          widget.file.name = value;
                          widget.manager.fetchDirectory(selectedRemotePath);
                        });
                      },
                      controller: TextEditingController(text: widget.file.name),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Iniciando descarga...')),
                              );

                              await widget.manager.downloadRemoteNode(fullPath);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Descarga completada')),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Descargar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                widget.manager.deleteRemoteNode(
                                  p.join(selectedRemotePath, widget.file.name),
                                );

                                widget.manager.fetchDirectory(selectedRemotePath).then((_) {
                                  Navigator.pop(context);
                                });
                              });
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (serverType != null) ...[
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proyecto ${serverType!.toUpperCase()}',
                        style: const TextStyle(
                          color: AppPalette.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: startServer,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Iniciar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: stopServer,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Parar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: restartServer,
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reiniciar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Permisos',
                          style: TextStyle(
                            color: AppPalette.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.file.permissions,
                          style: const TextStyle(
                            color: AppPalette.textMuted,
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: permissionGroup(
                            title: 'Propietario',
                            buttons: [
                              permissionButton(text: 'Lectura', index: 0, permission: '1r', activeLetter: 'r'),
                              permissionButton(text: 'Escritura', index: 1, permission: '1w', activeLetter: 'w'),
                              permissionButton(text: 'Ejecución', index: 2, permission: '1x', activeLetter: 'x'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: permissionGroup(
                            title: 'Grupo',
                            buttons: [
                              permissionButton(text: 'Lectura', index: 3, permission: '2r', activeLetter: 'r'),
                              permissionButton(text: 'Escritura', index: 4, permission: '2w', activeLetter: 'w'),
                              permissionButton(text: 'Ejecución', index: 5, permission: '2x', activeLetter: 'x'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: permissionGroup(
                            title: 'Otros',
                            buttons: [
                              permissionButton(text: 'Lectura', index: 6, permission: '3r', activeLetter: 'r'),
                              permissionButton(text: 'Escritura', index: 7, permission: '3w', activeLetter: 'w'),
                              permissionButton(text: 'Ejecución', index: 8, permission: '3x', activeLetter: 'x'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
