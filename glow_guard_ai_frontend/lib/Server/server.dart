import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final apiKey = Platform.environment['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'];

  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln(
      'ERROR: Missing OPENAI_API_KEY env var.\n'
          'Set it like:\n'
          '  export OPENAI_API_KEY="sk-..."\n'
          '  dart run bin/server.dart\n',
    );
    exit(1);
  }

  final router = Router();

  router.get('/health', (Request req) {
    return Response.ok(jsonEncode({'ok': true}), headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
    });
  });

  router.post('/chat', (Request req) async {
    try {
      final body = await req.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final message = (data['message'] ?? '').toString().trim();
      final history = (data['history'] is List) ? (data['history'] as List) : const [];

      if (message.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'message is required'}),
            headers: {HttpHeaders.contentTypeHeader: 'application/json'});
      }

      // System prompt: restrict to cosmetics + ingredient safety.
      final systemPrompt = '''
You are GlowGuard Assistant, focused ONLY on cosmetics, skincare, bleaching/whitening products, and ingredient safety.
- Explain ingredients in simple terms (what it is, why used, common risks).
- If user asks for diagnosis or medical treatment: give general guidance and suggest seeing a qualified clinician/pharmacist/dermatologist.
- If uncertain: say you’re not sure and suggest checking product label + consulting a professional.
- Be extra careful with bleaching/whitening: warn about mercury, high-dose hydroquinone misuse, topical steroids misuse, and counterfeit products.
- Keep answers concise (3–8 bullet points max) and practical.
''';

      // Convert incoming history into Responses API "input" messages.
      // Expected history items: { "role": "user"|"assistant", "content": "..." }
      final input = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      for (final item in history) {
        if (item is Map) {
          final role = (item['role'] ?? '').toString();
          final content = (item['content'] ?? '').toString();
          if ((role == 'user' || role == 'assistant') && content.trim().isNotEmpty) {
            input.add({'role': role, 'content': content});
          }
        }
      }

      input.add({'role': 'user', 'content': message});

      final openAiResp = await http.post(
        Uri.parse('https://api.openai.com/v1/responses'),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          // Choose a model available to your account:
          // If "gpt-5" is not enabled, switch to another model in your dashboard.
          'model': 'gpt-5',
          'input': input,
          // Optional: reduce storage if you want
          'store': false,
        }),
      );

      if (openAiResp.statusCode < 200 || openAiResp.statusCode >= 300) {
        return Response(
          502,
          body: jsonEncode({
            'error': 'OpenAI request failed',
            'status': openAiResp.statusCode,
            'body': openAiResp.body,
          }),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        );
      }

      final decoded = jsonDecode(openAiResp.body) as Map<String, dynamic>;

      // Responses API provides a convenience field in many SDKs: output_text
      // In raw JSON, best practice is to extract text from output items.
      final reply = extractOutputText(decoded).trim();
      if (reply.isEmpty) {
        return Response(
          502,
          body: jsonEncode({'error': 'Empty reply from model'}),
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'reply': reply}),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );
    } catch (e) {
      return Response(
        500,
        body: jsonEncode({'error': 'Server error', 'details': e.toString()}),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
      );
    }
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ GlowGuard backend running on http://${server.address.host}:${server.port}');
}

/// Extract assistant text from Responses API JSON.
/// This implementation is defensive because output formats can vary.
String extractOutputText(Map<String, dynamic> json) {
  // Some responses may include a top-level "output_text" field.
  final direct = json['output_text'];
  if (direct is String && direct.trim().isNotEmpty) return direct;

  final output = json['output'];
  if (output is! List) return '';

  final buffer = StringBuffer();

  for (final item in output) {
    if (item is Map<String, dynamic>) {
      // Common structure: {type: "message", content: [{type:"output_text", text:"..."}]}
      final content = item['content'];
      if (content is List) {
        for (final c in content) {
          if (c is Map<String, dynamic>) {
            final text = c['text'];
            if (text is String) buffer.writeln(text);
          }
        }
      }
    }
  }

  return buffer.toString();
}
