import 'dart:mirrors';
import 'package:ndk/domain_layer/entities/ndk_file.dart';
import 'package:ndk/domain_layer/usecases/files/files.dart';
void main() {
  var classMirror = reflectClass(Files);
  for (var decl in classMirror.declarations.values.whereType<MethodMirror>()) {
    if (MirrorSystem.getName(decl.simpleName) == 'upload') {
      print('upload params:');
      for (var param in decl.parameters) {
        print('${MirrorSystem.getName(param.simpleName)} (isNamed: ${param.isNamed}, type: ${param.type.reflectedType})');
      }
    }
  }
}
