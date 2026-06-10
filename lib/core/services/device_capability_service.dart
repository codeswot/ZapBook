import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

enum DeviceCapability { incapable, capable2B, capable4B }

extension DeviceCapabilityExtension on DeviceCapability {
  String? get modelUrl {
    switch (this) {
      case DeviceCapability.capable2B:
        return 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
      case DeviceCapability.capable4B:
        return 'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm';
      case DeviceCapability.incapable:
        return null;
    }
  }

  String? get modelName {
    switch (this) {
      case DeviceCapability.capable2B:
        return 'Gemma 4 E2B';
      case DeviceCapability.capable4B:
        return 'Gemma 4 E4B';
      case DeviceCapability.incapable:
        return null;
    }
  }

  int? get expectedFileSize {
    switch (this) {
      case DeviceCapability.capable2B:
        return 2576980377;
      case DeviceCapability.capable4B:
        return 3650722208;
      case DeviceCapability.incapable:
        return null;
    }
  }

  String? get expectedHash {
    switch (this) {
      case DeviceCapability.capable2B:
        return '181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c';
      case DeviceCapability.capable4B:
        return '0b2a8980ce155fd97673d8e820b4d29d9c7d99b8fa6806f425d969b145bd52e0';
      case DeviceCapability.incapable:
        return null;
    }
  }
}

abstract class DeviceCapabilityService {
  Future<DeviceCapability> checkDeviceCapability();
}

@LazySingleton(as: DeviceCapabilityService)
class DeviceCapabilityServiceImpl implements DeviceCapabilityService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  @override
  Future<DeviceCapability> checkDeviceCapability() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        final machine = iosInfo.utsname.machine;
        return _estimateIosCapability(machine);
      } else if (Platform.isAndroid) {
        return await _estimateAndroidCapability();
      }
    } catch (_) {}

    return DeviceCapability.capable2B;
  }

  DeviceCapability _estimateIosCapability(String machine) {
    if (machine.startsWith('iPhone')) {
      final clean = machine.replaceAll('iPhone', '');
      final majorStr = clean.split(',').first;
      final modelNumber = int.tryParse(majorStr) ?? 0;
      if (modelNumber >= 16) {
        return DeviceCapability.capable4B;
      }
      if (modelNumber >= 12) {
        return DeviceCapability.capable2B;
      }
      return DeviceCapability.incapable;
    }

    if (machine.startsWith('iPad')) {
      final clean = machine.replaceAll('iPad', '');
      final majorStr = clean.split(',').first;
      final modelNumber = int.tryParse(majorStr) ?? 0;
      if (modelNumber >= 14) {
        return DeviceCapability.capable4B;
      }
      if (modelNumber >= 8) {
        return DeviceCapability.capable2B;
      }
      return DeviceCapability.incapable;
    }

    return DeviceCapability.capable4B;
  }

  Future<int> _getAndroidTotalRamKb() async {
    try {
      final file = File('/proc/meminfo');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            final match = RegExp(r'\d+').firstMatch(line);
            if (match != null) {
              return int.tryParse(match.group(0)!) ?? 0;
            }
          }
        }
      }
    } catch (_) {}
    return 0;
  }

  Future<DeviceCapability> _estimateAndroidCapability() async {
    final ramKb = await _getAndroidTotalRamKb();
    final processors = Platform.numberOfProcessors;

    if (ramKb >= 7000000 && processors >= 8) {
      return DeviceCapability.capable4B;
    } else if (ramKb >= 3500000 && processors >= 4) {
      return DeviceCapability.capable2B;
    }
    return DeviceCapability.incapable;
  }
}
