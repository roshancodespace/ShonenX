import 'package:d4rt/d4rt.dart';
import 'package:shonenx/core/models/anime/server_model.dart';

class MServerBridge {
  final mServerBridgedClass = BridgedClass(
    nativeType: ServerData,
    name: 'MServer',
    constructors: {
      '': (visitor, positionalArgs, namedArgs) {
        return ServerData(
          id: namedArgs.get<String?>('id'),
          name: namedArgs.get<String?>('name'),
          isDub: namedArgs.get<bool>('isDub') ?? false,
        );
      },
    },
    getters: {
      'id': (visitor, target) => (target as ServerData).id,
      'name': (visitor, target) => (target as ServerData).name,
      'isDub': (visitor, target) => (target as ServerData).isDub,
    },
    setters: {},
  );

  void registerBridgedClasses(D4rt interpreter) {
    interpreter.registerBridgedClass(
      mServerBridgedClass,
      'package:mangayomi/bridge_lib.dart',
    );
  }
}
