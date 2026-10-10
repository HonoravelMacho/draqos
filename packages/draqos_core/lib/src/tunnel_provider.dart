import 'result.dart';

/// Status of a tunnel / sharing backend.
enum TunnelStatus { stopped, starting, running, error }

/// Abstraction over "expose local HTTP port to a tailnet / the internet".
/// Implementations: Tailscale (serve/funnel) and Cloudflare (cloudflared).
abstract class TunnelProvider {
  /// Human-readable backend name, e.g. "tailscale" / "cloudflare".
  String get name;

  /// Ports this backend can publicly expose (Funnel: 443, 8443, 10000).
  List<int> get publicPorts;

  /// Expose [localPort] privately (tailnet-only). Returns the base URL.
  Future<Result<String>> startPrivate(int localPort);

  /// Expose ONLY /r/<id> publicly. Returns the public base URL.
  Future<Result<String>> startPublic(int localPort);

  Future<Result<void>> stop();
  Future<TunnelStatus> status();
}

/// Error kinds when the Android editor cannot reach the PC daemon.
enum DaemonUnreachableKind { pcOffline, tailscaleOff, unauthorized, unknown }

class DaemonUnreachable {
  final DaemonUnreachableKind kind;
  final String message;
  const DaemonUnreachable(this.kind, this.message);
}
