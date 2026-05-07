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
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        title: const Text("Detalles del elemento"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: widget.file.isDirectory
                              ? Colors.amber.withOpacity(0.18)
                              : Colors.blueAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          widget.file.isDirectory
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          size: 70,
                          color: widget.file.isDirectory
                              ? Colors.amber[800]
                              : Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.file.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF101820),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 430,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppPalette.background,
                            labelText: 'Nombre del archivo',
                            prefixIcon: const Icon(Icons.edit),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (value) {
                            String oldPath = p.join(
                              selectedRemotePath,
                              widget.file.name,
                            );
                            String newPath = p.join(selectedRemotePath, value);

                            widget.manager.renameRemoteNode(oldPath, newPath);

                            setState(() {
                              widget.file.name = value;
                              widget.manager.fetchDirectory(selectedRemotePath);
                            });
                          },
                          controller: TextEditingController(
                            text: widget.file.name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPalette.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Iniciando descarga..."),
                                ),
                              );

                              String fullRemotePath = p.posix.join(
                                selectedRemotePath,
                                widget.file.name,
                              );

                              await widget.manager.downloadRemoteNode(fullRemotePath);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Descarga completada"),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text("Descargar"),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 16,
                              ),
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
                            icon: const Icon(Icons.delete),
                            label: const Text("Eliminar"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (serverType != null) ...[
                        Container(
                          width: 430,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppPalette.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Control del proyecto",
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF101820),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Status: ${isRunning ? 'Activo' : 'Detenido'}",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isRunning ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: startServer,
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text("Iniciar"),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: stopServer,
                                    icon: const Icon(Icons.stop),
                                    label: const Text("Parar"),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: restartServer,
                                    icon: const Icon(Icons.restart_alt),
                                    label: const Text("Reiniciar"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppPalette.background,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings,
                              color: Color(0xFF101820),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Permisos",
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF101820),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.file.permissions,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 22),
                        permissionGroup(
                          title: "Propietario",
                          buttons: [
                            permissionButton(
                              text: "Lectura",
                              index: 0,
                              permission: '1r',
                              activeLetter: 'r',
                            ),
                            permissionButton(
                              text: "Escritura",
                              index: 1,
                              permission: '1w',
                              activeLetter: 'w',
                            ),
                            permissionButton(
                              text: "Ejecución",
                              index: 2,
                              permission: '1x',
                              activeLetter: 'x',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        permissionGroup(
                          title: "Grupo",
                          buttons: [
                            permissionButton(
                              text: "Lectura",
                              index: 3,
                              permission: '2r',
                              activeLetter: 'r',
                            ),
                            permissionButton(
                              text: "Escritura",
                              index: 4,
                              permission: '2w',
                              activeLetter: 'w',
                            ),
                            permissionButton(
                              text: "Ejecución",
                              index: 5,
                              permission: '2x',
                              activeLetter: 'x',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        permissionGroup(
                          title: "Otros",
                          buttons: [
                            permissionButton(
                              text: "Lectura",
                              index: 6,
                              permission: '3r',
                              activeLetter: 'r',
                            ),
                            permissionButton(
                              text: "Escritura",
                              index: 7,
                              permission: '3w',
                              activeLetter: 'w',
                            ),
                            permissionButton(
                              text: "Ejecución",
                              index: 8,
                              permission: '3x',
                              activeLetter: 'x',
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
        ),
      ),
    );
  }
}

