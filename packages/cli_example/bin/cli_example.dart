// import 'package:intl/intl.dart';
import 'package:basic_message/basic_message.dart';
import 'package:share_message/share_message.dart';

import 'package:cli_example/cli_message_provider.dart';
import 'package:cli_example/generated/messages_all.dart';

/*
// import 'package:cli_example/cli_example.dart' as cli_example;

void main(List<String> arguments) {
  print('Hello world: ${cli_example.calculate()}!');
}
*/

/*
AppMessage is a simple enum that implements MessageEnum, defining message metadata.
AppMessageProvider is a concrete implementation of MessageProvider that uses Intl.message to resolve messages.

```shell
# cd into the root of the project to run the following commands
cd ..

# Generate message resources from the base definition file
dart run basic_message:gen_msg_resource -i packages/share_message/lib/src/share_message_base.dart -o packages/cli_example/lib/generated/messages_resource.g.dart 

# Generate the .arb files for translation
dart run intl_translation:extract_to_arb --output-dir=packages/cli_example/lib/l10n packages/cli_example/lib/generated/messages_resource.g.dart

# Rename the generated .arb file to match the locale (e.g., intl_en.arb for English), and add the @@locale key (e.g., "@@locale": "en") to the .arb file.
mv packages/cli_example/lib/l10n/intl_messages.arb packages/cli_example/lib/l10n/intl_en.arb

# After translating the .arb files, generate the Dart code for message resolution
dart run intl_translation:generate_from_arb --output-dir=packages/cli_example/lib/generated/ packages/cli_example/lib/generated/messages_resource.g.dart packages/cli_example/lib/l10n/intl_*.arb
```

Note: The generated code is placed in the `lib/generated/` directory, and the analysis options are configured to exclude this directory from linting to avoid issues with generated code.
```yaml
# analysis_options.yaml
analyzer:
  exclude:
    - lib/generated/
```
*/

void main() {
  final locales = ['en', 'zh_CN'];
  final locale = locales.first;
  // Intl.defaultLocale = locale;

  toggleLocale(locale);
}

void toggleLocale(String locale) {
  initializeMessages(locale).then((_) {
    MessageEngine.init(CliMessageProvider(locale));
    print(MessageEngine.tr(AppMessage.commonGlobalActionConfirmExitLabel));
    print(
      MessageEngine.tr(
        AppMessage.homeIndexHeaderWelcomeLabel,
        args: AppMessage.homeIndexHeaderWelcomeLabel.param,
      ),
    );

    // toggleLangAssembleWhoseApple();
  });
}

void toggleLangAssembleWhoseApple() {
  var whose = MessageEngine.tr(
    AppMessage.commonGlobalBodyGenderLabel,
    args: AppMessage.commonGlobalBodyGenderLabel.param,
  );
  var apple = MessageEngine.tr(
    AppMessage.commonGlobalBodyAppleLabel,
    args: AppMessage.commonGlobalBodyAppleLabel.param,
  );
  var combWhoseApples = MessageEngine.tr(
    AppMessage.commonGlobalBodyAssembleWhoseAppleLabel,
    args: {'whose': whose, 'apple': apple},
  );
  print(combWhoseApples);

  whose = MessageEngine.tr(
    AppMessage.commonGlobalBodyGenderLabel,
    args: {'gender': 'female'},
  );
  apple = MessageEngine.tr(
    AppMessage.commonGlobalBodyAppleLabel,
    args: {'count': 4},
  );

  combWhoseApples = MessageEngine.tr(
    AppMessage.commonGlobalBodyAssembleWhoseAppleLabel,
    args: {'whose': whose, 'apple': apple},
  );

  print(combWhoseApples);
}
