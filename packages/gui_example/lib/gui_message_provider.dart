import 'package:flutter/widgets.dart';
import 'package:basic_message/basic_message.dart';

import './l10n/app_localizations.dart';
import './l10n/messages_registry.g.dart';

class GuiMessageProvider<T extends MessageEnum> implements MessageProvider<T> {
  final BuildContext context;
  GuiMessageProvider(this.context);

  @override
  String resolve(T message, {Map<String, Object>? args}) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return message.msg;

    try {
      return resolveL10n(l10n, message.key, args);
    } catch (e) {
      return message.msg;
    }
  }
}
