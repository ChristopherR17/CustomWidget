import 'package:flutter/material.dart';

import '../services/host_profile_repository.dart';
import '../state/remote_session_state.dart';
import '../theme/app_palette.dart';
import 'remote_explorer_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.title});

  final String title;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _servernameController;
  late TextEditingController _userController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _keyController;

  @override
  void initState() {
    super.initState();
    _servernameController = TextEditingController(text: "Laura");
    _userController = TextEditingController(text: "ltorocordero");
    _hostController = TextEditingController(text: "ieticloudpro.ieti.cat");
    _portController = TextEditingController(text: "20127");
    _keyController = TextEditingController(text: "id_rsa");
    _loadServers();
  }

  void _loadServers() async {
    await loadHostProfilesFromAssets();
    setState(() {});
  }

  void _getCurrentFiles(String route) async {
    await sshFileGateway.fetchDirectory(route);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int currentServerId = 1;
    String currentServername = "Laura";
    String currentUsername = "ltorocordero";
    String currentIP = "ieticloudpro.ieti.cat";
    String currentKey = "id_rsa";
    int currentPort = 20127;

    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              color: AppPalette.sidebar,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Conexiones",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Elige un perfil para iniciar sesión",
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: hostProfiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final server = hostProfiles[index];

                        return Material(
                          color: AppPalette.sidebarCard,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                currentServerId = server.id;
                                _servernameController.text = server.name;
                                _userController.text = server.username;
                                _hostController.text = server.ip;
                                _portController.text = server.port.toString();
                                _keyController.text = server.key;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey[700],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.dns,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          server.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          server.ip,
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 560),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppPalette.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.terminal,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Panel de conexión",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Acceso remoto mediante clave SSH",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _servernameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppPalette.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Nombre del perfil',
                          prefixIcon: const Icon(Icons.badge_outlined),
                        ),
                        onChanged: (value) => currentServername = value,
                        onEditingComplete: () => {
                          renameHostProfile(currentServerId, currentServername),
                          persistHostProfiles(hostProfiles),
                          _loadServers(),
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _userController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppPalette.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Usuario',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        onChanged: (value) => currentUsername = value,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _hostController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppPalette.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Servidor',
                          prefixIcon: const Icon(Icons.language),
                        ),
                        onChanged: (value) => currentIP = value,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppPalette.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Puerto',
                          prefixIcon: const Icon(Icons.numbers),
                        ),
                        onChanged: (value) =>
                            currentPort = int.tryParse(value) ?? 22,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _keyController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppPalette.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          labelText: 'Clave privada',
                          prefixIcon: const Icon(Icons.key),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.link),
                                label: const Text('Conectar'),
                                onPressed: () async {
                                  bool success = await sshFileGateway.openConnection(
                                    _userController.text,
                                    _hostController.text,
                                    int.tryParse(_portController.text) ?? 22,
                                    _keyController.text,
                                  );

                                  if (success && mounted) {
                                    await sshFileGateway.fetchDirectory(selectedRemotePath);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RemoteExplorerScreen(
                                          manager: sshFileGateway,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Error al conectar"),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.delete),
                                label: const Text('Eliminar'),
                                onPressed: () async {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
