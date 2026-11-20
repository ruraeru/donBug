import 'api_client.dart';

/// AI 노무 도우미 답변. [citations] 는 근거 조항(예: `근로기준법 제55조`), 예전 서버는 없다.
class AiAnswer {
  const AiAnswer(this.answer, this.createdAt, [this.citations = const []]);

  final String answer;
  final DateTime createdAt;
  final List<String> citations;
}

enum AuditSeverity { high, medium, low }

/// 매장 노무 점검 항목 하나. [staffIds] 는 해당 직원(Staff id).
class AuditFinding {
  const AuditFinding(this.code, this.severity, this.title, this.detail, this.action,
      this.staffIds, this.citations);

  final String code;
  final AuditSeverity severity;
  final String title;
  final String detail;
  final String action;
  final List<String> staffIds;
  final List<String> citations;
}

/// 매장 노무 점검 결과. [aiUsed] 가 false 면 AI 설명 없이 기본 안내.
class LaborAudit {
  const LaborAudit(this.summary, this.aiUsed, this.findings);

  final String summary;
  final bool aiUsed;

  /// 심각도 높은 순.
  final List<AuditFinding> findings;
}

List<String> _strings(Object? v) =>
    v is List ? [for (final e in v) if (e != null) '$e'] : const [];

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
    _strings(j['citations']),
  );
}

/// `POST /api/v1/stores/{storeId}/ai/labor-audit` (사장님만). 모르는 심각도는 low, 빠진 목록은 빈 목록.
Future<LaborAudit> auditLabor(ApiClient api, String storeId) async {
  final j = await api.post('/api/v1/stores/$storeId/ai/labor-audit') as Map<String, dynamic>;
  final findings = [
    for (final f in (j['findings'] as List?) ?? const [])
      if (f is Map)
        AuditFinding(
          '${f['code'] ?? ''}',
          AuditSeverity.values
                  .where((v) => v.name == f['severity'])
                  .firstOrNull ??
              AuditSeverity.low,
          '${f['title'] ?? ''}',
          '${f['detail'] ?? ''}',
          '${f['action'] ?? ''}',
          _strings(f['staffIds']),
          _strings(f['citations']),
        ),
  ]..sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return LaborAudit('${j['summary'] ?? ''}', j['aiUsed'] == true, findings);
}

/// 화면에 띄울 에러 문구: 서버 message, 그 외(네트워크 등)는 일반 문구.
String aiErrorText(Object e) => e is ApiException ? e.message : '서버와 통신하지 못했어요';
