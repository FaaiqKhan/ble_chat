import 'package:ble_chat/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Persistent banner shown when Bluetooth is off or permission is denied.
class BluetoothBanner extends StatelessWidget {
  const BluetoothBanner({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final palette = context.palette;
    final radius = BorderRadius.circular(14);

    return Material(
      color: palette.errorSoft,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: palette.error, width: 1.5),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.bluetooth_disabled, size: 20, color: palette.error),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.labelMedium),
                    Text(
                      'Needed to start, find and chat in rooms',
                      style: tt.bodySmall?.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Fix',
                style: tt.labelMedium?.copyWith(color: palette.error),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 14, color: palette.error),
            ],
          ),
        ),
      ),
    );
  }
}
