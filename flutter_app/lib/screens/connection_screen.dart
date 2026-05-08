/// Pantalla de conexión SSH.
/// Permite al usuario seleccionar un perfil de servidor y establecer una conexión SSH.

import 'package:flutter/material.dart';

import '../models/host_profile.dart';
import '../services/host_profile_repository.dart';
import '../state/remote_session_state.dart';
import '../theme/app_palette.dart';
import 'remote_explorer_screen.dart';

/// Widget de pantalla de conexión.
/// Pantalla principal para gestionar perfiles y establecer conexiones.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.title});

  final String title;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

/// Estado de la pantalla de conexión.
/// Gestiona los controladores de texto y las operaciones de conexión.
class _ConnectionScreenState extends State<ConnectionScreen> {
  late TextEditingController _servernameController;
  late TextEditingController _userController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _keyController;

  int _activeProfileId = 1;

  @override
  void initState() {
    super.initState();
    _servernameController = TextEditingController(text: 'Christopher');
    _userController = TextEditingController(text: 'ccarrillocrespo');
    _hostController = TextEditingController(text: 'ieticloudpro.ieti.cat');
    _portController = TextEditingController(text: '20127');
    _keyController = TextEditingController(text: 'id_rsa');
    _loadServers();
  }

  @override
  void dispose() {
    _servernameController.dispose();
    _userController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  /// Carga los perfiles de servidores disponibles desde los assets.
  void _loadServers() async {
    await loadHostProfilesFromAssets();
    if (mounted) setState(() {});
  }

  /// Selecciona un perfil de servidor y actualiza los campos de entrada.
  void _selectProfile(HostProfile server) {
    setState(() {
      _activeProfileId = server.id;
      _servernameController.text = server.name;
      _userController.text = server.username;
      _hostController.text = server.ip;
      _portController.text = server.port.toString();
      _keyController.text = server.key;
    });
  }

  /// Guarda el nombre modificado del perfil seleccionado.
  Future<void> _saveProfileName() async {
    renameHostProfile(_activeProfileId, _servernameController.text);
    await persistHostProfiles(hostProfiles);
    _loadServers();
  }

  /// Establece la conexión SSH con el servidor seleccionado.
  /// Si la conexión es exitosa, navega a la pantalla del explorador remoto.
  Future<void> _connect() async {
    final success = await sshFileGateway.openConnection(
      _userController.text,
      _hostController.text,
      int.tryParse(_portController.text) ?? 22,
      _keyController.text,
    );

    if (!mounted) return;

    if (success) {
      await sshFileGateway.fetchDirectory(selectedRemotePath);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RemoteExplorerScreen(manager: sshFileGateway),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la conexión SSH')),
      );
    }
  }

  Widget _connectionField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    VoidCallback? onEditingComplete,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppPalette.primary),
        filled: true,
        fillColor: AppPalette.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _profileTile(HostProfile server) {
    final isActive = server.id == _activeProfileId;

    return ListTile(
      onTap: () => _selectProfile(server),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: isActive ? AppPalette.primary.withOpacity(0.18) : Colors.transparent,
      leading: CircleAvatar(
        backgroundColor: isActive ? AppPalette.primary : AppPalette.sidebarCard,
        child: Icon(Icons.dns_rounded, color: isActive ? Colors.white : Colors.white70),
      ),
      title: Text(
        server.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        server.ip,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white.withOpacity(0.55)),
      ),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: AppPalette.accent)
          : const Icon(Icons.circle_outlined, color: Colors.white30, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: Row(
        children: [
          Container(
            width: 320,
            height: double.infinity,
            color: AppPalette.sidebar,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.widgets_rounded, color: AppPalette.accent),
                    SizedBox(width: 12),
                    Text(
                      'SSH Widget',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                const Text(
                  'Servidores',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Elige un perfil SSH.',
                  style: TextStyle(color: Colors.white.withOpacity(0.58)),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: hostProfiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _profileTile(hostProfiles[index]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Conexión SSH',
                            style: TextStyle(
                              color: AppPalette.textDark,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Configura el perfil y accede al gestor de archivos remoto.',
                            style: TextStyle(color: AppPalette.textMuted),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _connectionField(
                                  controller: _servernameController,
                                  label: 'Nombre del perfil',
                                  icon: Icons.badge_outlined,
                                  onEditingComplete: _saveProfileName,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _connectionField(
                                  controller: _userController,
                                  label: 'Usuario',
                                  icon: Icons.person_outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _connectionField(
                            controller: _hostController,
                            label: 'Servidor',
                            icon: Icons.language_rounded,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: _connectionField(
                                  controller: _portController,
                                  label: 'Puerto',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _connectionField(
                                  controller: _keyController,
                                  label: 'Clave privada',
                                  icon: Icons.key_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppPalette.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.login_rounded),
                                  label: const Text(
                                    'Conectar',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  onPressed: _connect,
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  minimumSize: const Size(140, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Eliminar'),
                                onPressed: () async {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
