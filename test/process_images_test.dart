import 'package:screenshots/config.dart';
import 'package:screenshots/image_magick.dart';
import 'package:screenshots/process_images.dart';
import 'package:screenshots/resources.dart';
import 'package:screenshots/screens.dart';
import 'package:test/test.dart';

main() {
  test('process screenshots for iPhone X and iPhone XS Max', () async {
    final Screens screens = Screens();
    await screens.init();
    final Config config = Config('test/screenshots_test.yaml');
    Map appConfig = config.config;

    final Map devices = {
      'iPhone X': 'iphone_x_1.png',
      'iPhone XS Max': 'iphone_xs_max_1.png',
      'iPad Pro (12.9-inch) (3rd generation)':
          'ipad_pro_12.9inch_3rd_generation_1.png',
    };

    for (final String deviceName in devices.keys) {
      final screenshotName = devices[deviceName];
      print('deviceName=$deviceName, screenshotName=$screenshotName');
      Map screen = screens.screenProps(deviceName);

      final Map screenResources = screen['resources'];
      await unpackImages(screenResources, '/tmp/screenshots');

      final screenshotPath = './test/resources/$screenshotName';
      final statusbarPath =
          '${appConfig['staging']}/${screenResources['statusbar']}';

      var options = {
        'screenshotPath': screenshotPath,
        'statusbarPath': statusbarPath,
      };
//      print('options=$options');
      await imagemagick('overlay', options);

      final framePath = appConfig['staging'] + '/' + screenResources['frame'];
      final size = screen['size'];
      final resize = screen['resize'];
      final offset = screen['offset'];
      options = {
        'framePath': framePath,
        'size': size,
        'resize': resize,
        'offset': offset,
        'screenshotPath': screenshotPath,
        'backgroundColor': kDefaultAndroidBackground,
      };
//      print('options=$options');
      await imagemagick('frame', options);
    }
  });
}
