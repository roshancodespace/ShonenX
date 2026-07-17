import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_runtime.dart';
import 'package:shonenx/source_engine/dsl_engine/expression_evaluator.dart';
import 'package:shonenx/source_engine/dsl_engine/helper_registry.dart';
import 'package:shonenx/source_engine/dsl_engine/step_registry.dart';

String _summarize(dynamic data) {
  if (data == null) return 'null';
  if (data is List) return 'List(${data.length} items)';
  if (data is String) return 'String(${data.length} chars)';
  if (data is Map) return 'Map(${data.length} keys)';
  return data.runtimeType.toString();
}

class GetStep implements DSLStep {
  final HTTP client;
  final _log = AppLogger.scope(GetStep);

  GetStep(this.client);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final urlVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['url'] ?? '',
      context,
      helpers,
    );
    final headersVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['headers'],
      context,
      helpers,
    );
    final headers = headersVal is Map
        ? Map<String, String>.from(headersVal)
        : null;

    _log.i('GET: $urlVal');
    final res = await client.get(urlVal.toString(), headers: headers);
    context.lastResponse = res;
    _log.s('Response: ${res.statusCode} | Output: ${_summarize(res.body)}');

    dynamic outVal;
    try {
      outVal = res.json;
    } catch (_) {
      outVal = res.body;
    }

    context.lastOutput = outVal;
    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), outVal);
    }
  }
}

class PostStep implements DSLStep {
  final HTTP client;
  final _log = AppLogger.scope(PostStep);

  PostStep(this.client);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final urlVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['url'] ?? '',
      context,
      helpers,
    );
    final bodyVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['body'],
      context,
      helpers,
    );
    final headersVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['headers'],
      context,
      helpers,
    );
    final headers = headersVal is Map
        ? Map<String, String>.from(headersVal)
        : null;

    _log.i('POST: $urlVal');
    final res = await client.post(
      urlVal.toString(),
      body: bodyVal,
      headers: headers,
    );
    context.lastResponse = res;
    _log.s('Response: ${res.statusCode} | Output: ${_summarize(res.body)}');

    dynamic outVal;
    try {
      outVal = res.json;
    } catch (_) {
      outVal = res.body;
    }

    context.lastOutput = outVal;
    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), outVal);
    }
  }
}

class HtmlStep implements DSLStep {
  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'] ?? '{{lastOutput}}',
      context,
      helpers,
    );
    if (inputVal == null) return;

    final doc = html_parser.parse(inputVal.toString());
    context.lastHtmlDocument = doc;
    context.lastOutput = doc;

    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), doc);
    }
  }
}

class JsonStep implements DSLStep {
  final _log = AppLogger.scope(JsonStep);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'] ?? '{{lastOutput}}',
      context,
      helpers,
    );
    if (inputVal == null) return;

    if (inputVal is Map || inputVal is List) {
      context.lastJson = inputVal;
      context.lastOutput = inputVal;
    } else {
      try {
        final json = jsonDecode(inputVal.toString());
        context.lastJson = json;
        context.lastOutput = json;
      } catch (e) {
        _log.e('JsonStep failed: $e');
        rethrow;
      }
    }

    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), context.lastOutput);
    }
  }
}

class SelectStep implements DSLStep {
  final _log = AppLogger.scope(SelectStep);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final selectorVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['selector'] ?? '',
      context,
      helpers,
    );
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'],
      context,
      helpers,
    );

    dom.Element? root;
    final target =
        inputVal ?? context.lastHtmlElement ?? context.lastHtmlDocument;

    if (target is dom.Element) {
      root = target;
    } else if (target is dom.Document)
      root = target.documentElement;
    else if (target is String)
      root = html_parser.parse(target).documentElement;

    if (root == null) return;

    final all = stepDef['all'] == true;
    dynamic result;

    if (all) {
      final elements = root.querySelectorAll(selectorVal.toString());
      result = elements;
      _log.i('Select "$selectorVal" found ${elements.length} elements.');
    } else {
      final element = root.querySelector(selectorVal.toString());
      if (element != null) context.lastHtmlElement = element;
      result = element;
      _log.i(
        'Select "$selectorVal" found ${element != null ? "1" : "0"} element.',
      );
    }

    if (result != null) {
      if (stepDef['attribute'] != null || stepDef['attr'] != null) {
        final attrName = (stepDef['attribute'] ?? stepDef['attr']).toString();
        if (all && result is List<dom.Element>) {
          result = result.map((el) => el.attributes[attrName]).toList();
        } else if (result is dom.Element)
          result = result.attributes[attrName];
      } else if (stepDef['text'] == true) {
        if (all && result is List<dom.Element>) {
          result = result.map((el) => el.text.trim()).toList();
        } else if (result is dom.Element)
          result = result.text.trim();
      } else if (stepDef['html'] == true) {
        if (all && result is List<dom.Element>) {
          result = result.map((el) => el.outerHtml).toList();
        } else if (result is dom.Element)
          result = result.outerHtml;
      }
    }

    context.lastOutput = result;
    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), result);
    }
  }
}

class PathStep implements DSLStep {
  final _log = AppLogger.scope(PathStep);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final pathVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['selector'] ?? stepDef['path'] ?? '',
      context,
      helpers,
    );
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'] ?? '{{lastOutput}}',
      context,
      helpers,
    );

    final result = await helpers.execute('jsonPath', [
      inputVal,
      pathVal,
    ], context);
    context.lastOutput = result;
    _log.i('Path "$pathVal" result: ${_summarize(result)}');

    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), result);
    }
  }
}

class ObjectStep implements DSLStep {
  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final fieldsDef = stepDef['fields'];
    if (fieldsDef is! Map) return;

    final result = await ExpressionEvaluator.evaluateTemplate(
      fieldsDef,
      context,
      helpers,
    );
    context.lastOutput = result;

    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), result);
    }
  }
}

class MapStep implements DSLStep {
  final DSLRuntime runtime;
  final _log = AppLogger.scope(MapStep);

  MapStep(this.runtime);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'] ?? '{{lastOutput}}',
      context,
      helpers,
    );
    if (inputVal is! List) return;
    final steps = stepDef['steps'];
    if (steps is! List) return;

    final itemVar = stepDef['itemVar']?.toString() ?? 'item';
    final results = [];
    _log.i('Mapping over ${inputVal.length} items ("$itemVar")');

    for (int i = 0; i < inputVal.length; i++) {
      final item = inputVal[i];
      final subCtx = context.clone();
      subCtx.setVariable(itemVar, item);
      subCtx.lastOutput = item;
      if (item is dom.Element) subCtx.lastHtmlElement = item;

      try {
        final pipelineSteps = steps
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        await runtime.executePipeline(pipelineSteps, subCtx);
        results.add(subCtx.lastOutput);
      } on DSLReturnSignal catch (e) {
        results.add(e.value);
      } catch (e) {
        _log.e('Error on item [$i]:', e);
        results.add(null);
      }
    }

    context.lastOutput = results;
    _log.s('Map completed (Output: ${_summarize(results)})');

    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), results);
    }
  }
}

class RegexStep implements DSLStep {
  final _log = AppLogger.scope(RegexStep);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final patternVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['pattern'] ?? '',
      context,
      helpers,
    );
    final inputVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['input'] ?? '{{lastOutput}}',
      context,
      helpers,
    );
    if (inputVal == null) return;

    final groupIdx = stepDef['group'] != null
        ? int.tryParse(stepDef['group'].toString()) ?? 1
        : 1;
    final match = RegExp(patternVal.toString()).firstMatch(inputVal.toString());

    dynamic result;
    if (match != null) {
      result = match.groupCount >= groupIdx
          ? match.group(groupIdx)
          : match.group(0);
    } else {
      _log.warning('No match for: $patternVal');
    }

    context.lastOutput = result;
    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), result);
    }
  }
}

class TransformStep implements DSLStep {
  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final expressionVal = stepDef['expression']?.toString() ?? '';
    final result = await ExpressionEvaluator.evaluate(
      expressionVal,
      context,
      helpers,
    );
    context.lastOutput = result;
    if (stepDef['output'] != null) {
      context.setVariable(stepDef['output'].toString(), result);
    }
  }
}

class ReturnStep implements DSLStep {
  final _log = AppLogger.scope(ReturnStep);

  @override
  Future<void> execute(
    Map<String, dynamic> stepDef,
    ExecutionContext context,
    HelperRegistry helpers,
  ) async {
    final valueVal = await ExpressionEvaluator.evaluateTemplate(
      stepDef['value'] ?? '{{lastOutput}}',
      context,
      helpers,
    );
    _log.i('ReturnStep invoked.');
    throw DSLReturnSignal(valueVal);
  }
}
