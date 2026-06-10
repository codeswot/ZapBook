import 'dart:collection';
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = '/Users/codeswot/.gemini/antigravity/brain/0904e1ef-e5e8-4f30-b847-704ee2ecfbbe/zapbook_app_icon_white_1781112994457.png';
  final inputBytes = File(inputPath).readAsBytesSync();
  final originalImage = img.decodeImage(inputBytes);
  if (originalImage == null) {
    print('Error: Could not decode image.');
    exit(1);
  }

  var image = img.copyCrop(originalImage, x: 200, y: 200, width: 624, height: 624);

  if (!image.hasAlpha) {
    image = image.convert(numChannels: 4);
  }

  final width = image.width;
  final height = image.height;
  final visited = List.generate(height, (_) => List.filled(width, false));
  final queue = Queue<List<int>>();

  final seeds = [
    [0, 0],
    [0, height - 1],
    [width - 1, 0],
    [width - 1, height - 1]
  ];

  for (final seed in seeds) {
    final x = seed[0];
    final y = seed[1];
    final pixel = image.getPixel(x, y);
    if (pixel.r > 240 && pixel.g > 240 && pixel.b > 240) {
      queue.add([x, y]);
      visited[y][x] = true;
    }
  }

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final cx = current[0];
    final cy = current[1];

    final pixel = image.getPixel(cx, cy);
    pixel.a = 0;

    final dirs = [
      [0, 1], [0, -1], [1, 0], [-1, 0]
    ];
    for (final dir in dirs) {
      final nx = cx + dir[0];
      final ny = cy + dir[1];
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        if (!visited[ny][nx]) {
          final nPixel = image.getPixel(nx, ny);
          if (nPixel.r > 240 && nPixel.g > 240 && nPixel.b > 240) {
            visited[ny][nx] = true;
            queue.add([nx, ny]);
          }
        }
      }
    }
  }

  final androidTargets = {
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
  };

  final iosPrefix = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final iosTargets = {
    '$iosPrefix/Icon-App-20x20@1x.png': 20,
    '$iosPrefix/Icon-App-20x20@2x.png': 40,
    '$iosPrefix/Icon-App-20x20@3x.png': 60,
    '$iosPrefix/Icon-App-29x29@1x.png': 29,
    '$iosPrefix/Icon-App-29x29@2x.png': 58,
    '$iosPrefix/Icon-App-29x29@3x.png': 87,
    '$iosPrefix/Icon-App-40x40@1x.png': 40,
    '$iosPrefix/Icon-App-40x40@2x.png': 80,
    '$iosPrefix/Icon-App-40x40@3x.png': 120,
    '$iosPrefix/Icon-App-60x60@2x.png': 120,
    '$iosPrefix/Icon-App-60x60@3x.png': 180,
    '$iosPrefix/Icon-App-76x76@1x.png': 76,
    '$iosPrefix/Icon-App-76x76@2x.png': 152,
    '$iosPrefix/Icon-App-83.5x83.5@2x.png': 167,
    '$iosPrefix/Icon-App-1024x1024@1x.png': 1024,
  };

  for (final entry in androidTargets.entries) {
    final file = File(entry.key);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated: ${entry.key}');
  }

  for (final entry in iosTargets.entries) {
    final file = File(entry.key);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final resized = img.copyResize(image, width: entry.value, height: entry.value);
    file.writeAsBytesSync(img.encodePng(resized));
    print('Generated: ${entry.key}');
  }

  print('Icon generation complete!');
}
