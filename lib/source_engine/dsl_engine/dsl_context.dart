import 'package:html/dom.dart' as dom;
import 'package:shonenx/core/network/http_client.dart';

class StepExecutionDetail {
  final String stepType;
  final Map<String, dynamic> stepDef;
  final dynamic input;
  final dynamic output;
  final Duration duration;
  final String? error;
  final Map<String, dynamic> variablesSnapshot;

  StepExecutionDetail({
    required this.stepType,
    required this.stepDef,
    this.input,
    this.output,
    required this.duration,
    this.error,
    required this.variablesSnapshot,
  });
}

class ExecutionContext {
  final Map<String, dynamic> variables = {};
  dynamic lastOutput;
  HttpResponse? lastResponse;
  dom.Element? lastHtmlElement;
  dom.Document? lastHtmlDocument;
  dynamic lastJson;
  final Map<String, dynamic> cache = {};
  final List<StepExecutionDetail> executionLog = [];

  ExecutionContext({Map<String, dynamic>? initialVariables}) {
    if (initialVariables != null) {
      variables.addAll(initialVariables);
    }
  }

  void setVariable(String name, dynamic value) {
    variables[name] = value;
  }

  dynamic getVariable(String name) {
    return variables[name];
  }

  void logStep({
    required String stepType,
    required Map<String, dynamic> stepDef,
    dynamic input,
    dynamic output,
    required Duration duration,
    String? error,
  }) {
    executionLog.add(
      StepExecutionDetail(
        stepType: stepType,
        stepDef: stepDef,
        input: input,
        output: output,
        duration: duration,
        error: error,
        variablesSnapshot: Map<String, dynamic>.from(variables),
      ),
    );
  }

  ExecutionContext clone() {
    final newCtx = ExecutionContext();
    newCtx.variables.addAll(variables);
    newCtx.lastOutput = lastOutput;
    newCtx.lastResponse = lastResponse;
    newCtx.lastHtmlElement = lastHtmlElement;
    newCtx.lastHtmlDocument = lastHtmlDocument;
    newCtx.lastJson = lastJson;
    newCtx.cache.addAll(cache);
    newCtx.executionLog.addAll(executionLog);
    return newCtx;
  }
}
