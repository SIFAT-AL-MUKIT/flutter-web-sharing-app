import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'web_sharing_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _bg = Color(0xFF090D16);
const _card = Color(0xFF111827);
const _cardHover = Color(0xFF1E2A3A);
const _primary = Color(0xFF3B82F6);
const _primaryDim = Color(0x333B82F6);
const _green = Color(0xFF10B981);
const _greenDim = Color(0x2210B981);
const _purple = Color(0xFF8B5CF6);
const _purpleDim = Color(0x228B5CF6);
const _text = Color(0xFFF3F4F6);
const _muted = Color(0xFF9CA3AF);
const _border = Color(0x10FFFFFF);
const _borderActive = Color(0x553B82F6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _svc = WebSharingService.instance;

  String _rootDir = '/storage/emulated/0';
  bool _localLoading = false;
  bool _internetLoading = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose folder to share',
    );
    if (result != null) setState(() => _rootDir = result);
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) return;
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      if (!mounted) return;
      _showSnack('Storage permission is required to share files.');
      throw Exception('Permission denied');
    }
  }

  Future<void> _toggleLocal() async {
    if (_localLoading) return;
    setState(() => _localLoading = true);
    try {
      if (_svc.isLocalActive) {
        await _svc.stopLocalServer();
      } else {
        await _requestStoragePermission();
        await _svc.startLocalServer(_rootDir);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  Future<void> _toggleInternet() async {
    if (_internetLoading) return;
    setState(() => _internetLoading = true);
    try {
      if (_svc.isInternetActive) {
        _svc.stopInternetTunnel();
      } else {
        if (!_svc.isLocalActive) {
          await _requestStoragePermission();
          await _svc.startLocalServer(_rootDir);
        }
        await _svc.startInternetTunnel(_rootDir);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _internetLoading = false);
    }
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showSnack('Link copied!');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showQr(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan to Connect',
                style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(data: url, size: 200),
              ),
              const SizedBox(height: 16),
              Text(
                url,
                style: const TextStyle(color: _muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: _primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _svc,
      builder: (context, _) {
        final isAnyActive = _svc.isLocalActive || _svc.isInternetActive;
        final clients = _svc.activeClients;

        return Scaffold(
          backgroundColor: _bg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xCC090D16),
                surfaceTintColor: Colors.transparent,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ColorFilter.matrix([
                      1, 0, 0, 0, 0,
                      0, 1, 0, 0, 0,
                      0, 0, 1, 0, 0,
                      0, 0, 0, 20, -10,
                    ]),
                    child: const SizedBox.expand(),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _primaryDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primary.withOpacity(0.4)),
                      ),
                      child: const Icon(_iconShare, color: _primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'NFile',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (isAnyActive)
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.08 + 0.08 * _pulseAnim.value),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _green.withOpacity(0.3 + 0.2 * _pulseAnim.value),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.7 + 0.3 * _pulseAnim.value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Active',
                              style: TextStyle(
                                color: _green,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: _border),
                ),
              ),

              // ── Body Content ────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Status Hero
                    _StatusHeroCard(
                      isLocalActive: _svc.isLocalActive,
                      isInternetActive: _svc.isInternetActive,
                      clientCount: clients.length,
                      pulseAnim: _pulseAnim,
                    ),
                    const SizedBox(height: 16),

                    // Folder Picker
                    _FolderCard(
                      path: _rootDir,
                      onTap: _pickFolder,
                      isActive: isAnyActive,
                    ),
                    const SizedBox(height: 16),

                    // Share Mode Toggles
                    Row(
                      children: [
                        Expanded(
                          child: _ShareModeCard(
                            label: 'Local Wi-Fi',
                            sublabel: _svc.isLocalActive
                                ? _svc.localServerUrl
                                : 'Same network only',
                            icon: Icons.wifi_rounded,
                            color: _green,
                            dimColor: _greenDim,
                            isActive: _svc.isLocalActive,
                            isLoading: _localLoading,
                            onToggle: _toggleLocal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ShareModeCard(
                            label: 'Internet',
                            sublabel: _svc.isInternetActive
                                ? (_svc.internetShareLink.isEmpty
                                    ? 'Connecting…'
                                    : _svc.internetShareLink.replaceFirst('https://', ''))
                                : 'via localhost.run',
                            icon: Icons.language_rounded,
                            color: _purple,
                            dimColor: _purpleDim,
                            isActive: _svc.isInternetActive,
                            isLoading: _internetLoading,
                            onToggle: _toggleInternet,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // URL Cards
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: Column(
                        children: [
                          if (_svc.isLocalActive) ...[
                            _UrlCard(
                              label: 'Local Network',
                              url: _svc.localServerUrl,
                              color: _green,
                              icon: Icons.wifi_rounded,
                              onCopy: () => _copyUrl(_svc.localServerUrl),
                              onQr: () => _showQr(_svc.localServerUrl),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_svc.isInternetActive &&
                              _svc.internetShareLink.isNotEmpty) ...[
                            _UrlCard(
                              label: 'Internet Link',
                              url: _svc.internetShareLink,
                              color: _purple,
                              icon: Icons.language_rounded,
                              onCopy: () => _copyUrl(_svc.internetShareLink),
                              onQr: () => _showQr(_svc.internetShareLink),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_svc.isInternetActive &&
                              _svc.internetShareLink.isEmpty)
                            _TunnelWaitingCard(),
                        ],
                      ),
                    ),

                    // Active Clients
                    if (clients.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _SectionLabel(
                        label: 'Active Clients',
                        badge: '${clients.length}',
                      ),
                      const SizedBox(height: 8),
                      ...clients.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ClientCard(client: c),
                      )),
                    ],

                    // Empty State
                    if (!isAnyActive) ...[
                      const SizedBox(height: 24),
                      _EmptyState(),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Icon Constant ────────────────────────────────────────────────────────────
const _iconShare = Icons.share_rounded;

// ─── Status Hero Card ─────────────────────────────────────────────────────────
class _StatusHeroCard extends StatelessWidget {
  final bool isLocalActive;
  final bool isInternetActive;
  final int clientCount;
  final Animation<double> pulseAnim;

  const _StatusHeroCard({
    required this.isLocalActive,
    required this.isInternetActive,
    required this.clientCount,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final isAny = isLocalActive || isInternetActive;
    final color = isAny ? _green : _muted;

    String statusText;
    String subText;
    if (isLocalActive && isInternetActive) {
      statusText = 'Sharing on Wi-Fi & Internet';
      subText = clientCount > 0
          ? '$clientCount device${clientCount == 1 ? '' : 's'} connected'
          : 'Waiting for connections';
    } else if (isLocalActive) {
      statusText = 'Sharing on Local Network';
      subText = clientCount > 0
          ? '$clientCount device${clientCount == 1 ? '' : 's'} connected'
          : 'Waiting for connections';
    } else if (isInternetActive) {
      statusText = 'Sharing over Internet';
      subText = clientCount > 0
          ? '$clientCount device${clientCount == 1 ? '' : 's'} connected'
          : 'Waiting for connections';
    } else {
      statusText = 'Server is Offline';
      subText = 'Enable a sharing mode below';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAny ? _green.withOpacity(0.25) : _border,
        ),
        gradient: isAny
            ? LinearGradient(
                colors: [_card, _green.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Row(
        children: [
          // Animated indicator orb
          AnimatedBuilder(
            animation: pulseAnim,
            builder: (_, __) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isAny)
                    Container(
                      width: 48 + 10 * pulseAnim.value,
                      height: 48 + 10 * pulseAnim.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _green.withOpacity(0.05 * pulseAnim.value),
                      ),
                    ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12),
                      border: Border.all(color: color.withOpacity(0.4), width: 1.5),
                    ),
                    child: Icon(
                      isAny ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subText,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Folder Picker Card ───────────────────────────────────────────────────────
class _FolderCard extends StatelessWidget {
  final String path;
  final VoidCallback onTap;
  final bool isActive;

  const _FolderCard({
    required this.path,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF10B98118),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.folder_rounded, color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shared Folder',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    path,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isActive) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryDim,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primary.withOpacity(0.3)),
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              const Icon(Icons.lock_rounded, color: _muted, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Share Mode Toggle Card ───────────────────────────────────────────────────
class _ShareModeCard extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color dimColor;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onToggle;

  const _ShareModeCard({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.dimColor,
    required this.isActive,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.08) : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withOpacity(0.35) : _border,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: dimColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const Spacer(),
              GestureDetector(
                onTap: isLoading ? null : onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isActive ? color : const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isActive ? Colors.white : color,
                          ),
                        )
                      else
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          alignment: isActive
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? color : _text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sublabel,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── URL Share Card ───────────────────────────────────────────────────────────
class _UrlCard extends StatelessWidget {
  final String label;
  final String url;
  final Color color;
  final IconData icon;
  final VoidCallback onCopy;
  final VoidCallback onQr;

  const _UrlCard({
    required this.label,
    required this.url,
    required this.color,
    required this.icon,
    required this.onCopy,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IconBtn(icon: Icons.copy_rounded, color: color, onTap: onCopy),
          const SizedBox(width: 4),
          _IconBtn(icon: Icons.qr_code_rounded, color: color, onTap: onQr),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}

// ─── Tunnel Waiting Card ──────────────────────────────────────────────────────
class _TunnelWaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _purple.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Establishing internet tunnel…',
            style: TextStyle(color: _muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final String? badge;

  const _SectionLabel({required this.label, this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: _primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Active Client Card ───────────────────────────────────────────────────────
class _ClientCard extends StatelessWidget {
  final Map<String, dynamic> client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final device = client['device'] as String? ?? 'Unknown Device';
    final file = client['file'] as String? ?? '-';
    final speed = (client['speed'] as double?) ?? 0.0;
    final transferred = client['transferred'] as String? ?? '0 KB';
    final progress = (client['progress'] as double?) ?? 0.0;
    final isBrowsing = file == 'Browsing Directories';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryDim,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isBrowsing ? Icons.folder_open_rounded : Icons.devices_rounded,
                  color: _primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      file,
                      style: const TextStyle(color: _muted, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isBrowsing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2A3A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${speed.toStringAsFixed(1)} MB/s',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          if (!isBrowsing) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0xFF1F2937),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.95 ? _green : _primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  transferred,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _primaryDim,
              shape: BoxShape.circle,
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.wifi_tethering_rounded, color: _primary, size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ready to Share',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toggle Local Wi-Fi or Internet above\nto start sharing your files.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
