import 'package:ble_chat/presentation/common/chat_icon_button.dart';
import 'package:flutter/material.dart';

/// The top bar of a screen: a back button and the screen's title.
/// Pass it to `Scaffold.appBar`.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({super.key, required this.name});

  final String name;

  // Same height as the AppBar it builds, so the Scaffold can reserve the space.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return AppBar(
      leading: ChatIconButton(
        iconData: Icons.arrow_back_ios_new_rounded,
        onPressed: Navigator.of(context).pop,
      ),
      title: Text(name, style: tt.headlineSmall),
    );
  }
}
