import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/helper_registry.dart';
import 'package:shonenx/source_engine/dsl_engine/step_registry.dart';
import 'package:shonenx/source_engine/dsl_engine/steps_impl.dart';

class DSLRuntime {
  late final StepRegistry stepRegistry;
  late final HelperRegistry helperRegistry;
  final _log = AppLogger.scope(DSLRuntime);

  DSLRuntime({required HTTP httpClient}) {
    stepRegistry = StepRegistry();
    helperRegistry = HelperRegistry(client: httpClient);
    _registerDefaultSteps(httpClient);
  }

  void _registerDefaultSteps(HTTP httpClient) {
    stepRegistry.register('fetch', GetStep(httpClient));
    stepRegistry.register('get', GetStep(httpClient));
    stepRegistry.register('post', PostStep(httpClient));
    stepRegistry.register('html', HtmlStep());
    stepRegistry.register('json', JsonStep());
    stepRegistry.register('select', SelectStep());
    stepRegistry.register('path', PathStep());
    stepRegistry.register('object', ObjectStep());
    stepRegistry.register('map', MapStep(this));
    stepRegistry.register('regex', RegexStep());
    stepRegistry.register('transform', TransformStep());
    stepRegistry.register('return', ReturnStep());
  }

  Future<dynamic> executePipeline(
    List<Map<String, dynamic>> steps,
    ExecutionContext context,
  ) async {
    for (final stepDef in steps) {
      final stepType = stepDef['type']?.toString();

      if (stepType == null || stepType.isEmpty) {
        throw Exception('Step definition missing "type" attribute: $stepDef');
      }

      final step = stepRegistry.getStep(stepType);
      if (step == null) {
        throw Exception(
          'Step type "$stepType" is not registered in the StepRegistry.',
        );
      }

      final startTime = DateTime.now();
      dynamic inputSnapshot = context.lastOutput;
      String? errorMsg;

      try {
        await step.execute(stepDef, context, helperRegistry);
      } on DSLReturnSignal {
        final duration = DateTime.now().difference(startTime);
        context.logStep(
          stepType: stepType,
          stepDef: stepDef,
          input: inputSnapshot,
          output: context.lastOutput,
          duration: duration,
        );
        rethrow;
      } catch (e, st) {
        final duration = DateTime.now().difference(startTime);
        errorMsg = e.toString();

        _log.fail('Pipeline aborted at "$stepType" step.');
        _log.e('Step Exception Details:', e, st);

        context.logStep(
          stepType: stepType,
          stepDef: stepDef,
          input: inputSnapshot,
          output: null,
          duration: duration,
          error: errorMsg,
        );
        rethrow;
      }

      final duration = DateTime.now().difference(startTime);

      context.logStep(
        stepType: stepType,
        stepDef: stepDef,
        input: inputSnapshot,
        output: context.lastOutput,
        duration: duration,
      );
    }

    return context.lastOutput;
  }

  Future<dynamic> executeMethod(
    Map<String, dynamic> providerDef,
    String methodName,
    Map<String, dynamic> arguments,
  ) async {
    final providerId = providerDef['id'] ?? 'unknown_provider';

    _log.section('Execute Method: $methodName');
    _log.i('Provider: $providerId | Method: $methodName');

    final methods = providerDef['methods'];
    if (methods is! Map) {
      throw Exception('Provider does not define a "methods" map.');
    }

    final methodDef = methods[methodName];
    if (methodDef == null) {
      throw Exception('Method "$methodName" is not defined in this provider.');
    }

    final stepsRaw = methodDef['steps'];
    if (stepsRaw is! List) {
      throw Exception('Method "$methodName" steps must be a JSON array.');
    }

    final steps = stepsRaw
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    // Setup context with arguments and provider metadata
    final initialVariables = Map<String, dynamic>.from(arguments);
    initialVariables['baseUrl'] = providerDef['baseUrl'];
    initialVariables['providerId'] = providerId;
    initialVariables['providerName'] = providerDef['name'];

    final context = ExecutionContext(initialVariables: initialVariables);

    try {
      await executePipeline(steps, context);
      _log.s('Method "$methodName" execution finished.');
      return context.lastOutput;
    } on DSLReturnSignal catch (e) {
      _log.s('Method "$methodName" execution finished via early return.');
      return e.value;
    } catch (e) {
      _log.fail('Method "$methodName" execution aborted due to error.');
      rethrow;
    }
  }
}
