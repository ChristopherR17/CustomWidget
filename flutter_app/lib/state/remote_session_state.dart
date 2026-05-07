import '../models/host_profile.dart';
import '../models/remote_node.dart';
import '../services/ssh_file_gateway.dart';

final SshFileGateway sshFileGateway = SshFileGateway();
bool sshSessionActive = false;
List<HostProfile> hostProfiles = [];
List<RemoteNode> remoteNodes = [];
String selectedRemotePath = '/';
