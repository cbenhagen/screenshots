import 'package:screenshots/config.dart';
import 'package:screenshots/process_images.dart';
import 'package:screenshots/screens.dart';
import 'package:screenshots/screenshots.dart';
import 'package:test/test.dart';
import 'package:screenshots/fastlane.dart' as fastlane;
import 'package:yaml/yaml.dart';

final screenshotsYaml = '''
# Screen capture tests
tests:
  - example/test_driver/main.dart

# Interim location of screenshots from tests before processing
staging: /tmp/screenshots

# A list of locales supported in app
locales:
#  - fr-CA
  - en-US
#  - de-DE

# A list of devices to emulate
devices:
  ios:
    iPhone X:
    iPhone 7 Plus:
      frame: false
#    - iPad Pro (12.9-inch) (2nd generation)
#   "iPhone 6",
#   "iPhone 6 Plus",
#   "iPhone 5",
#   "iPhone 4s",
#   "iPad Retina",
#   "iPad Pro"
  android:
    Nexus 5X:

# Frame screenshots
frame: true
''';

void main() {
  test('config info for app from string', () {
    final expected = {
      'tests': ['example/test_driver/main.dart'],
      'locales': ['en-US'],
      'frame': true,
      'devices': {
        'android': {'Nexus 5X': null},
        'ios': {
          'iPhone 7 Plus': {'frame': false},
          'iPhone X': null
        }
      },
      'staging': '/tmp/screenshots'
    };

    final Map screenshotsConfig = loadYaml(screenshotsYaml);
    expect(screenshotsConfig, expected);
  });

  test('config info for app from file', () {
    final expected = {
      'tests': ['example/test_driver/main.dart'],
      'locales': ['en-US'],
      'frame': true,
      'devices': {
        'android': {'Nexus 5X': null},
        'ios': {
          'iPhone 7 Plus': {'frame': false},
          'iPhone X': null
        }
      },
      'staging': '/tmp/screenshots'
    };

    final Config config = Config('test/screenshots_test.yaml');
    Map appConfig = config.config;
    expect(appConfig, expected);
  });

  test('validate config file', () async {
    final Screens screens = Screens();
    await screens.init();
    final Config config = Config('test/screenshots_test.yaml');
    expect(await config.validate(screens), true);
  });

  test('clear all destination directories on init', () async {
    final Screens screens = Screens();
    await screens.init();
    final Map config = loadYaml(screenshotsYaml);
    await fastlane.clearFastlaneDirs(config, screens);
  });

  test('check if frame is needed', () {
    final Map config = loadYaml(screenshotsYaml);

    expect(isFrameRequired(config, DeviceType.ios, 'iPhone X'), true);
    expect(isFrameRequired(config, DeviceType.ios, 'iPhone 7 Plus'), false);
    expect(isFrameRequired(config, DeviceType.android, 'Nexus 5X'), true);
  });
}
