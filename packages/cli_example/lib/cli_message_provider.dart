import 'package:intl/intl.dart';
import 'package:basic_message/basic_message.dart';
import 'package:share_message/share_message.dart';

class CliMessageProvider extends MessageProvider<AppMessage> {
  final String locale;
  CliMessageProvider(this.locale);

  @override
  String resolve(AppMessage message, {Map<String, Object>? args}) {
    // final methodName = message.key.replaceAll('.', '_');
    return Intl.message(
      message.msg,
      name: message.key,
      args: args?.values.toList(),
      locale: locale,
    );
  }
}
