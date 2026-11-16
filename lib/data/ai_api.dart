import 'api_client.dart';

/// AI 노무 도우미 답변.
class AiAnswer {
  const AiAnswer(this.answer, this.createdAt);

  final String answer;
  final DateTime createdAt;
}

/// `POST /api/v1/stores/{storeId}/ai/labor-questions`. 실패하면 [ApiException] (서버 message 그대로).
Future<AiAnswer> askLaborQuestion(
  ApiClient api,
  String storeId,
  String question,
) async {
  final j = await api.post('/api/v1/stores/$storeId/ai/labor-questions', {
    'question': question,
  }) as Map<String, dynamic>;
  return AiAnswer(
    j['answer'] as String,
    DateTime.parse(j['createdAt'] as String),
  );
}

/// 화면에 띄울 에러 문구: 서버 message, 그 외(네트워크 등)는 일반 문구.
String aiErrorText(Object e) => e is ApiException ? e.message : '서버와 통신하지 못했어요';
