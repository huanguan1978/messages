import 'package:flutter/material.dart';

import 'package:basic_message/basic_message.dart';
import 'gui_message_provider.dart';

/// Initializes the global message provider using the current localization context.
///
/// Place this widget in [MaterialApp.builder] so the provider is refreshed when
/// the app's locale changes:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => GuiMessageInitializer(child: child!),
/// )
/// ```
class GuiMessageInitializer extends StatefulWidget {
  const GuiMessageInitializer({super.key, required this.child});

  final Widget child;

  @override
  State<GuiMessageInitializer> createState() => _GuiMessageInitializerState();
}

class _GuiMessageInitializerState extends State<GuiMessageInitializer> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    MessageEngine.init(GuiMessageProvider(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
