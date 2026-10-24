import 'package:ble_chat/presentation/common/ble_chat_outlined_button.dart';
import 'package:ble_chat/business_logic/host_session/host_session_bloc.dart';
import 'package:ble_chat/business_logic/host_session/host_session_event.dart';
import 'package:ble_chat/business_logic/host_session/host_session_state.dart';
import 'package:ble_chat/common/bluetooth_signal.dart';
import 'package:ble_chat/presentation/common/app_padding.dart';
import 'package:ble_chat/presentation/common/close_room_sheet.dart';
import 'package:ble_chat/presentation/common/dashed_border.dart';
import 'package:ble_chat/presentation/common/closing_room_banner.dart';
import 'package:ble_chat/presentation/common/host_room_label_card.dart';
import 'package:ble_chat/presentation/common/host_room_status_chip.dart';
import 'package:ble_chat/presentation/common/signal_bars.dart';
import 'package:ble_chat/presentation/common/spacer_box.dart';
import 'package:ble_chat/presentation/screens/host/widgets/host_room_setting_up.dart';
import 'package:ble_chat/theme/app_colors.dart';
import 'package:ble_chat/theme/app_palette.dart';
import 'package:ble_chat/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A guest connected to the room. [rssi] drives the signal bars; a
/// [reconnecting] guest shows a spinner instead.
class HostParticipant {
  const HostParticipant({
    required this.name,
    required this.rssi,
    this.reconnecting = false,
  });

  final String name;
  final int rssi;
  final bool reconnecting;
}

class HostRoomScreen extends StatelessWidget {
  const HostRoomScreen({
    super.key,
    this.hostName = 'You',
    this.bluetoothOn = true,
    this.onOpenChat,
  });

  final String hostName;
  final bool bluetoothOn;

  /// Called when the host opens the chat; only reachable once someone joined.
  final VoidCallback? onOpenChat;

  void handleRoomClose(BuildContext context, HostSessionBloc bloc) {
    confirmClose(context, bloc.state.participants).then((value) {
      if (value) bloc.add(CloseRoomEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    final hostSessionBloc = context.read<HostSessionBloc>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleRoomClose(context, hostSessionBloc);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppPadding.portraitScreen,
            child: BlocBuilder<HostSessionBloc, HostSessionState>(
              builder: (context, state) {
                final failed = state.status == HostSessionStatus.failed;
                final closeFailed =
                    state.status == HostSessionStatus.closeFailed;
                final inStartup =
                    state.status == HostSessionStatus.idle ||
                    state.status == HostSessionStatus.starting;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "HOSTING",
                          style: tt.labelSmall?.copyWith(letterSpacing: 0.88),
                        ),
                        BlocSelector<
                          HostSessionBloc,
                          HostSessionState,
                          HostSessionStatus
                        >(
                          selector: (select) => select.status,
                          builder: (_, status) {
                            return HostRoomStatusChip(
                              status: status,
                              full: hostSessionBloc.isFull,
                              stopped: !bluetoothOn,
                            );
                          },
                        ),
                      ],
                    ),
                    const SpacerBox(
                      type: SpacerBoxType.vertical,
                      size: SpacerBoxSize.medium,
                    ),
                    Expanded(
                      child: ListView(
                        children: [
                          HostRoomLabelCard(
                            name: hostSessionBloc.state.roomName,
                            code: hostSessionBloc.state.code,
                            authCode: hostSessionBloc.state.authCode,
                          ),
                          const SpacerBox(
                            type: SpacerBoxType.vertical,
                            size: SpacerBoxSize.medium,
                          ),
                          _CountCard(
                            count: hostSessionBloc.count,
                            max: hostSessionBloc.state.maxPeople,
                          ),
                          const SpacerBox(
                            type: SpacerBoxType.vertical,
                            size: SpacerBoxSize.medium,
                          ),
                          switch (hostSessionBloc.state.status) {
                            HostSessionStatus.idle => const SizedBox.shrink(),
                            HostSessionStatus.starting =>
                              const HostRoomSettingUp(),
                            HostSessionStatus.hosting ||
                            HostSessionStatus.closeFailed => Column(
                              children: [
                                if (closeFailed)
                                  const _FailedBanner(
                                    title: "Couldn’t close your room",
                                    message: "Please try again.",
                                  )
                                else if (failed)
                                  const _FailedBanner()
                                else if (inStartup)
                                  const SizedBox.shrink()
                                else if (hostSessionBloc.isFull)
                                  const _FullBanner()
                                else
                                  _WaitingBanner(
                                    open: hostSessionBloc.isOpen,
                                    label:
                                        "${hostSessionBloc.state.roomName} · ${hostSessionBloc.state.code}",
                                  ),
                                const SpacerBox(
                                  type: SpacerBoxType.vertical,
                                  size: SpacerBoxSize.large,
                                ),
                                ...[
                                  Text(
                                    "CONNECTED · ${hostSessionBloc.count}",
                                    style: tt.labelSmall?.copyWith(
                                      letterSpacing: 0.88,
                                    ),
                                  ),
                                  const SpacerBox(
                                    type: SpacerBoxType.vertical,
                                    size: SpacerBoxSize.medium,
                                  ),
                                  _MemberRow.host(name: hostName),
                                  for (final p
                                      in hostSessionBloc.state.participants)
                                    _MemberRow.guest(p),
                                  for (
                                    var i = 0;
                                    i < hostSessionBloc.isOpen;
                                    i++
                                  )
                                    const _MemberRow.empty(),
                                ],
                              ],
                            ),
                            HostSessionStatus.closing =>
                              BlocListener<HostSessionBloc, HostSessionState>(
                                listener: (_, state) {
                                  if (state.status ==
                                      HostSessionStatus.closed) {
                                    Navigator.of(context)
                                        .popUntil((r) => r.isFirst);
                                  }
                                },
                                child: const ClosingRoomBanner(),
                              ),
                            HostSessionStatus.closed ||
                            HostSessionStatus.failed => const SizedBox.shrink(),
                          },
                        ],
                      ),
                    ),
                    const SpacerBox(
                      type: SpacerBoxType.vertical,
                      size: SpacerBoxSize.medium,
                    ),
                    Row(
                      children: [
                        BleChatOutlinedButton(
                          onPressed: closeFailed
                              ? () => hostSessionBloc.add(
                                  DismissCloseErrorEvent(),
                                )
                              : failed
                              ? Navigator.of(context).pop
                              : () => handleRoomClose(context, hostSessionBloc),
                          tone: failed || closeFailed
                              ? BleChatButtonTone.primary
                              : BleChatButtonTone.danger,
                          child: Text(
                            closeFailed
                                ? "Back"
                                : failed
                                ? "Back to Setup"
                                : "Close Room",
                          ),
                        ),
                        const SpacerBox(
                          type: SpacerBoxType.horizontal,
                          size: SpacerBoxSize.large,
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: closeFailed
                                ? () => hostSessionBloc.add(CloseRoomEvent())
                                : failed
                                ? () => hostSessionBloc.add(StartHostingEvent())
                                : hostSessionBloc.hasPeer
                                ? onOpenChat
                                : null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: cs.outline,
                              disabledForegroundColor: cs.onSurfaceVariant,
                            ),
                            child: Text(
                              failed || closeFailed ? "Try Again" : "Open Chat",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.count, required this.max});

  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [palette.shadowCard],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: "$count",
                  children: [
                    TextSpan(
                      text: " / $max",
                      style: TextStyle(color: AppColors.fg4),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: AppFonts.mono,
                  fontSize: 44,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.88,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text("people in the room", style: tt.bodySmall),
            ],
          ),
          Row(
            children: [
              for (var i = 0; i < max; i++)
                Container(
                  width: 12,
                  height: 36,
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: i < count ? AppColors.primary : cs.outline,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaitingBanner extends StatefulWidget {
  const _WaitingBanner({required this.open, required this.label});

  final int open;
  final String label;

  @override
  State<_WaitingBanner> createState() => _WaitingBannerState();
}

class _WaitingBannerState extends State<_WaitingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.primaryBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: AnimatedBuilder(
              animation: _ring,
              builder: (_, _) => CustomPaint(
                painter: _RipplePainter(_ring.value, AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Waiting for ${widget.open} more",
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  "People nearby can find “${widget.label}”.",
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, 4, Paint()..color = color);
    // Two rings, the second offset by 0.45 of the cycle (0.9s of 2s).
    for (final phase in [t, (t + 0.55) % 1.0]) {
      final scale = 0.25 + 0.75 * phase;
      canvas.drawCircle(
        c,
        r * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.8 * (1 - phase)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t || old.color != color;
}

class _FullBanner extends StatelessWidget {
  const _FullBanner();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.fullBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.fullBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Room full",
                  style: tt.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "No one else can join right now. It reopens when someone "
                  "leaves.",
                  style: tt.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow.host({required this._name})
    : _kind = _RowKind.host,
      _participant = null;

  const _MemberRow.guest(HostParticipant p)
    : _name = null,
      _kind = _RowKind.guest,
      _participant = p;

  const _MemberRow.empty()
    : _name = null,
      _kind = _RowKind.empty,
      _participant = null;

  final String? _name;
  final _RowKind _kind;
  final HostParticipant? _participant;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    final isHost = _kind == _RowKind.host;
    final isEmpty = _kind == _RowKind.empty;
    final p = _participant;
    final reconnecting = p?.reconnecting ?? false;

    final title = isHost
        ? "$_name (host)"
        : isEmpty
        ? "Empty spot"
        : p!.name;
    final sub = isHost
        ? "you · host"
        : isEmpty
        ? "waiting for someone to join"
        : reconnecting
        ? "connection lost · trying again…"
        : switch (bluetoothSignalOf(p!.rssi)) {
            BluetoothSignal.good => "Strong signal",
            BluetoothSignal.weak => "Weak signal",
            BluetoothSignal.poor => "Very weak signal",
          };
    final initial = isEmpty ? "+" : (isHost ? _name! : p!.name)[0];

    final avatarBg = isHost
        ? AppColors.primary
        : isEmpty
        ? Colors.transparent
        : palette.primarySoft;
    final avatarFg = isHost
        ? Colors.white
        : isEmpty
        ? cs.onSurfaceVariant
        : palette.primaryStrong;

    final row = Container(
      height: 60,
      padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
      decoration: BoxDecoration(
        color: reconnecting
            ? palette.primarySoft
            : isEmpty
            ? Colors.transparent
            : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: isEmpty
            ? null
            : Border.all(
                color: reconnecting ? palette.primaryBorder : cs.outlineVariant,
                width: 1.5,
              ),
      ),
      foregroundDecoration: isEmpty
          ? DashedBorder(color: cs.outline, radius: 14)
          : null,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: avatarFg,
                  ),
                ),
              ),
              if (isHost)
                Positioned(
                  right: -4,
                  top: -5,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.surface, width: 1.5),
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 10,
                      color: palette.crownOn,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(
                    color: isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                  ),
                ),
                Text(
                  sub,
                  style: tt.bodySmall?.copyWith(
                    fontFamily: AppFonts.mono,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (reconnecting)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: palette.primaryFg,
                backgroundColor: palette.primaryBorder,
              ),
            )
          else if (p != null)
            SignalBars(rssi: p.rssi),
        ],
      ),
    );

    return Padding(padding: const EdgeInsets.only(bottom: 8), child: row);
  }
}

enum _RowKind { host, guest, empty }

class _FailedBanner extends StatelessWidget {
  const _FailedBanner({
    this.title = "Couldn’t start your room",
    this.message = "Nearby devices can’t see it yet.",
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.error, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: palette.badFg, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(message, style: tt.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
