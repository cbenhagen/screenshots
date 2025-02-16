import 'dart:async';
import 'dart:io';

import 'package:screenshots/screens.dart';
import 'package:screenshots/fastlane.dart' as fastlane;
import 'package:screenshots/image_magick.dart' as im;
import 'package:screenshots/resources.dart' as resources;
import 'package:screenshots/screenshots.dart';
import 'package:screenshots/utils.dart' as utils;
import 'package:path/path.dart' as p;
import 'package:screenshots/utils.dart';

const kDefaultIosBackground = 'xc:white';
const kDefaultAndroidBackground = 'xc:none'; // transparent
const kCrop =
    '1000x40+0+0'; // default sample size and location to test for brightness

///
/// Process screenshots.
///
/// If android, screenshot is overlaid with a status bar and appended with
/// a navbar.
///
/// If ios, screenshot is overlaid with a status bar.
///
/// If 'frame' in config file is true, screenshots are placed within image of device.
///
/// After processing, screenshots are handed off for upload via fastlane.
///
void process(Screens screens, Map config, DeviceType deviceType,
    String deviceName, String locale) async {
  final Map screenProps = screens.screenProps(deviceName);
  final staging = config['staging'];
  final Map screenResources = screenProps['resources'];
//  print('screenResources=$screenResources');
  print('Processing screenshots from test...');

  // unpack images for screen from package to local staging area
  await resources.unpackImages(screenResources, staging);

  // add status and nav bar and frame for each screenshot
  final screenshots = Directory('$staging/test').listSync();
  for (final screenshotPath in screenshots) {
    // add status bar for each screenshot
//    print('overlaying status bar over screenshot at $screenshotPath');
    await overlay(config, screenResources, screenshotPath.path);

    if (deviceType == DeviceType.android) {
      // add nav bar for each screenshot
//      print('appending navigation bar to screenshot at $screenshotPath');
      await append(config, screenResources, screenshotPath.path);
    }

    // add frame if required
    if (isFrameRequired(config, deviceType, deviceName)) {
//      print('placing $screenshotPath in frame');
      await frame(config, screenProps, screenshotPath.path, deviceType);
    }
  }

  // move to final destination for upload to stores via fastlane
  final srcDir = '${config['staging']}/test';
  final dstDir = fastlane.path(deviceType, locale, '', screenProps['destName']);
  // prefix screenshots with name of device before moving
  // (useful for uploading to apple via fastlane)
  await utils.prefixFilesInDir(srcDir, '$deviceName-');

  print('Moving screenshots to $dstDir');
  utils.moveFiles(srcDir, dstDir);
}

///
/// Overlay status bar over screenshot.
///
Future overlay(Map config, Map screenResources, String screenshotPath) async {
  // if no status bar skip
  // todo: get missing status bars
  if (screenResources['statusbar'] == null) {
    print('error: image ${p.basename(screenshotPath)} is missing status bar.');
    return Future.value(null);
  }

  String statusbarPath;
  // select black or white status bar based on brightness of area to be overlaid
  // todo: add black and white status bars
  if (im.thresholdExceeded(screenshotPath, kCrop)) {
    // use black status bar
    statusbarPath =
        '${config['staging']}/${screenResources['statusbar black']}';
  } else {
    // use white status bar
    statusbarPath =
        '${config['staging']}/${screenResources['statusbar white']}';
  }

  final options = {
    'screenshotPath': screenshotPath,
    'statusbarPath': statusbarPath,
  };
  await im.imagemagick('overlay', options);
}

///
/// Append android navigation bar to screenshot.
///
Future append(Map config, Map screenResources, String screenshotPath) async {
  final screenshotNavbarPath =
      '${config['staging']}/${screenResources['navbar']}';
  final options = {
    'screenshotPath': screenshotPath,
    'screenshotNavbarPath': screenshotNavbarPath,
  };
  await im.imagemagick('append', options);
}

/// Checks if frame is required for [deviceName].
bool isFrameRequired(Map config, DeviceType deviceType, String deviceName) {
  final deviceConfig = config['devices'][enumToStr(deviceType)][deviceName];
  bool isFrameRequired = config['frame'];
  if (deviceConfig != null) {
    final frame = deviceConfig['frame'];
    if (frame != null) isFrameRequired = frame;
  }
  return isFrameRequired;
}

///
/// Frame a screenshot with image of device.
///
/// Resulting image is scaled to fit dimensions required by stores.
///
void frame(Map config, Map screen, String screenshotPath,
    DeviceType deviceType) async {
  final Map resources = screen['resources'];

  final framePath = config['staging'] + '/' + resources['frame'];
  final size = screen['size'];
  final resize = screen['resize'];
  final offset = screen['offset'];

  // set the default background color
  String backgroundColor;
  (deviceType == DeviceType.ios)
      ? backgroundColor = kDefaultIosBackground
      : backgroundColor = kDefaultAndroidBackground;

  final options = {
    'framePath': framePath,
    'size': size,
    'resize': resize,
    'offset': offset,
    'screenshotPath': screenshotPath,
    'backgroundColor': backgroundColor,
  };
  await im.imagemagick('frame', options);
}
