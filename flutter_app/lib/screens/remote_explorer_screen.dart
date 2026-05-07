import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../services/app_logger.dart';
import '../services/ssh_file_gateway.dart';
import '../state/remote_session_state.dart';
import '../theme/app_palette.dart';
import 'remote_node_details_screen.dart';

class RemoteExplorerScreen extends StatefulWidget {
  final SshFileGateway manager;

  const RemoteExplorerScreen({super.key, required this.manager});

  @override
  State<RemoteExplorerScreen> createState() => _RemoteExplorerScreenState();
}

class _RemoteExplorerScreenState extends State<RemoteExplorerScreen> {
  void _navigateTo(String path) async {
    String cleanPath = p.normalize(path);
    selectedRemotePath = cleanPath;

    await widget.manager.fetchDirectory(cleanPath);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        title: const Text("Explorador remoto"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open, color: Color(0xFF101820)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedRemotePath,
                    style: const TextStyle(
                      color: Color(0xFF101820),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.separated(
                itemCount: remoteNodes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final file = remoteNodes[index];

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (file.isDirectory) {
                          logger.i("Entrando en: ${file.name}");

                          if (file.name == "..") {
                            String parentPath = p.dirname(selectedRemotePath);
                            _navigateTo(parentPath);
                          } else {
                            String newPath = p.join(selectedRemotePath, file.name);
                            _navigateTo(newPath);
                          }
                        }
                      },
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RemoteNodeDetailsScreen(
                              manager: widget.manager,
                              file: file,
                            ),
                          ),
                        ).then((_) {
                          widget.manager.fetchDirectory(selectedRemotePath);
                          setState(() {});
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: file.isDirectory
                                    ? Colors.amber.withOpacity(0.18)
                                    : Colors.blueAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                file.isDirectory
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                color: file.isDirectory
                                    ? Colors.amber[800]
                                    : Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                file.name,
                                style: const TextStyle(
                                  color: Color(0xFF101820),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              file.permissions,
                              style: const TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.more_vert,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload),
        label: const Text("Subir"),
        onPressed: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles();

          if (result != null) {
            String? filePath = result.files.single.path;

            if (filePath != null) {
              await widget.manager.uploadRemoteFile(filePath, selectedRemotePath);
              await widget.manager.fetchDirectory(selectedRemotePath);

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Archivo subido correctamente")),
              );
            }
          }
        },
      ),
    );
  }
}
