// import 'package:basic_message/basic_message.dart';

/*
AppMessage is a simple enum that implements MessageEnum, defining message metadata.
AppMessageProvider is a concrete implementation of MessageProvider that uses Intl.message to resolve messages.

dart run bin/gen_msg_source.dart -i /Users/kaguya/Documents/Projects/avatar/basic_message/example/basic_message_definition.dart -o /Users/kaguya/Documents/Projects/avatar/basic_message/example/l10n/l10n_resource.dart
dart run intl_translation:extract_to_arb --output-dir=example/l10n example/l10n/l10n_resource.dart
dart run intl_translation:generate_from_arb --output-dir=example/l10n  example/l10n/l10n_source.dart  example/l10n/intl_*.arb
*/

void main(List<String> arguments) {
  print('Hello world!');
}
