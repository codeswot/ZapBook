import 'dart:mirrors';
import 'package:marmot_dart/marmot_dart.dart';

void main() {
  var classMirror = reflectClass(MarmotGroup);
  for (var decl in classMirror.declarations.values.whereType<VariableMirror>()) {
    print('${MirrorSystem.getName(decl.simpleName)} (isFinal: ${decl.isFinal})');
  }
}
