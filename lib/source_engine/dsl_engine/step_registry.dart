import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/helper_registry.dart';

abstract class DSLStep {
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  );
}

class StepRegistry {
  final Map<String, DSLStep> _steps = {};

  void register(String type, DSLStep step) {
    _steps[type] = step;
  }

  DSLStep? getStep(String type) => _steps[type];
}

class DSLReturnSignal implements Exception {
  final dynamic value;
  DSLReturnSignal(this.value);

  @override
  String toString() => 'DSLReturnSignal: $value';
}
