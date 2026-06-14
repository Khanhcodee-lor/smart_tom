import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'aqua_firebase_service.dart';

class GeminiChatException implements Exception {
  const GeminiChatException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeminiChatService {
  GeminiChatService({http.Client? client}) : _client = client ?? http.Client();

  static const _apiKeyFromEnvironment = String.fromEnvironment(
    'GEMINI_API_KEY',
  );
  static const _fallbackApiKey = 'AIzaSyAf-EFNBzXX2DNL4oLph5ct6dRxsEM_ZRs';
  static const _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  final http.Client _client;

  String get _apiKey {
    final environmentKey = _apiKeyFromEnvironment.trim();
    if (environmentKey.isNotEmpty) {
      return environmentKey;
    }
    return _fallbackApiKey;
  }

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  void close() {
    _client.close();
  }

  Future<String> generateReply({
    required List<AquaChatMessage> recentMessages,
    required AquaRealtimeData pondData,
  }) async {
    if (!isConfigured) {
      throw const GeminiChatException(
        'Chưa cấu hình Gemini API key. Hãy chạy app với --dart-define=GEMINI_API_KEY=API_KEY_CUA_BAN.',
      );
    }

    final response = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': _apiKey,
          },
          body: jsonEncode(_buildRequestBody(recentMessages, pondData)),
        )
        .timeout(const Duration(seconds: 35));

    final bodyText = utf8.decode(response.bodyBytes);
    final decoded = _decodeJson(bodyText);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiChatException(_extractApiError(decoded, response.statusCode));
    }

    final text = _extractResponseText(decoded);
    if (text == null || text.trim().isEmpty) {
      throw const GeminiChatException(
        'Gemini chưa trả về nội dung. Bạn thử hỏi lại ngắn hơn nhé.',
      );
    }

    return text.trim();
  }

  Uri get _endpoint {
    final modelPath = _model.startsWith('models/') ? _model : 'models/$_model';
    return Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/$modelPath:generateContent',
    );
  }

  Map<String, Object?> _buildRequestBody(
    List<AquaChatMessage> messages,
    AquaRealtimeData pondData,
  ) {
    final history = messages
        .where((message) => !message.isLocal && message.text.trim().isNotEmpty)
        .toList();
    final window = history.length > 12
        ? history.sublist(history.length - 12)
        : history;

    return {
      'systemInstruction': {
        'parts': [
          {'text': _buildSystemInstruction(pondData)},
        ],
      },
      'contents': [
        for (final message in window)
          {
            'role': message.geminiRole,
            'parts': [
              {'text': message.text},
            ],
          },
      ],
      'generationConfig': {
        'temperature': 0.65,
        'topP': 0.9,
        'maxOutputTokens': 900,
      },
    };
  }

  String _buildSystemInstruction(AquaRealtimeData data) {
    return '''
Bạn là Aqua AI, trợ lý tư vấn nuôi tôm và quản lý ao thủy sản cho ứng dụng AquaSmart.
Trả lời bằng tiếng Việt, ngắn gọn, thân thiện, ưu tiên việc người nuôi có thể làm ngay.
Không dùng tiêu đề Markdown kiểu ###. Nếu cần liệt kê, dùng danh sách ngắn 1., 2., 3. và tối đa 5 ý chính.
Khi tư vấn bệnh, hóa chất, thuốc hoặc thay nước, hãy nhắc người dùng kiểm tra thực tế ao và hỏi kỹ sư/nhân viên thú y thủy sản nếu có dấu hiệu nghiêm trọng.

Dữ liệu Firebase hiện tại của ao:
- Nhiệt độ nước: ${_formatNullable(data.temperature, '°C')}
- pH: ${_formatNullable(data.ph, '')}
- Bơm nóng: ${data.hotPumpOn ? 'đang bật' : 'đang tắt'}
- Bơm lạnh: ${data.coldPumpOn ? 'đang bật' : 'đang tắt'}
- Chế độ điều khiển: ${data.controlMode == PumpControlMode.auto ? 'tự động' : 'thủ công'}
- Ngưỡng bơm nóng: ${data.hotPumpThreshold.toStringAsFixed(1)}°C
- Ngưỡng bơm lạnh: ${data.coldPumpThreshold.toStringAsFixed(1)}°C
''';
  }

  String _formatNullable(double? value, String unit) {
    if (value == null) {
      return 'chưa có dữ liệu';
    }
    return '${value.toStringAsFixed(1)}$unit';
  }

  Map<String, dynamic> _decodeJson(String bodyText) {
    try {
      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Fall through to the generic error below.
    }
    return {'raw': bodyText};
  }

  String _extractApiError(Map<String, dynamic> decoded, int statusCode) {
    final error = decoded['error'];
    if (error is Map) {
      final message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return 'Gemini lỗi $statusCode: ${message.trim()}';
      }
    }
    return 'Gemini lỗi $statusCode. Vui lòng kiểm tra API key hoặc thử lại sau.';
  }

  String? _extractResponseText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final first = candidates.first;
    if (first is! Map) {
      return null;
    }

    final content = first['content'];
    if (content is! Map) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text']);
      }
    }

    return buffer.toString();
  }
}
