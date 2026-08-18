/// RetellReviewEvaluationController 测试：登录闸门、后端错误码映射。
library;

import 'package:dio/dio.dart';
import 'package:echo_loop/features/auth/providers/auth_providers.dart';
import 'package:echo_loop/models/retell_review_evaluation.dart';
import 'package:echo_loop/providers/retell_review_evaluation_provider.dart';
import 'package:echo_loop/services/retell_review_audio_preparer.dart';
import 'package:echo_loop/services/sentence_ai_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';

/// 可脚本化的评估流替身，并记录 accessToken 入参。
class _ScriptApi implements SentenceAiApiClient {
  _ScriptApi(this.script);
  final Stream<RetellReviewStreamFrame> Function() script;

  int callCount = 0;
  String? lastAccessToken;

  @override
  Stream<RetellReviewStreamFrame> evaluateReviewStream({
    required File audioFile,
    required String originalText,
    required String targetLanguage,
    required String accessToken,
    CancelToken? cancelToken,
  }) {
    callCount++;
    lastAccessToken = accessToken;
    return script();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 记录调用次数的音频准备替身：闸门必须早于它，一次都不该被调到。
class _SpyPreparer implements RetellReviewAudioPreparer {
  _SpyPreparer(this._output);
  final File _output;
  int callCount = 0;

  @override
  Future<File> prepare(File source) async {
    callCount++;
    return _output;
  }
}

Session _session() => Session(
  accessToken: 'test-token',
  tokenType: 'bearer',
  user: const User(
    id: 'u',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-07-13T00:00:00.000Z',
  ),
);

DioException _httpError(int status, {Object? data}) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/stream/evaluate-review'),
  response: Response(
    requestOptions: RequestOptions(path: '/api/v1/stream/evaluate-review'),
    statusCode: status,
    data: data,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SpyPreparer preparer;
  late File prepared;

  setUp(() async {
    prepared = File(
      '${Directory.systemTemp.path}/retell-review-controller-test.m4a',
    );
    await prepared.writeAsBytes([0, 1, 2]);
    preparer = _SpyPreparer(prepared);
  });

  tearDown(() async {
    if (await prepared.exists()) await prepared.delete();
  });

  /// 构造容器：默认已登录。
  ///
  /// supabaseSessionProvider 是 StreamProvider（异步 emit），controller 同步读
  /// `valueOrNull`，故先 await 让其落定，避免误判 AsyncLoading → auth_required。
  Future<ProviderContainer> make(
    _ScriptApi api, {
    bool authenticated = true,
    bool hasSession = true,
  }) async {
    final container = ProviderContainer(
      overrides: [
        sentenceAiApiClientProvider.overrideWithValue(api),
        retellReviewAudioPreparerProvider.overrideWithValue(preparer),
        isAuthenticatedProvider.overrideWithValue(authenticated),
        supabaseSessionProvider.overrideWith(
          (ref) => Stream<Session?>.value(hasSession ? _session() : null),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(retellReviewEvaluationProvider, (_, __) {});
    await container.read(supabaseSessionProvider.future);
    return container;
  }

  Future<void> evaluate(ProviderContainer c) => c
      .read(retellReviewEvaluationProvider.notifier)
      .evaluate(
        attemptKey: 'p1:/tmp/retell.m4a',
        recordingPath: prepared.path,
        originalText: 'Practice every day.',
        targetLanguage: 'zh-CN',
      );

  RetellReviewEvaluationState st(ProviderContainer c) =>
      c.read(retellReviewEvaluationProvider);

  Stream<RetellReviewStreamFrame> okStream() async* {
    yield const RetellReviewStreamFrame(
      evaluation: RetellReviewEvaluation(summary: '表达清楚'),
      isFinal: false,
    );
    yield const RetellReviewStreamFrame(
      evaluation: RetellReviewEvaluation(
        summary: '表达清楚',
        rating: RetellReviewRating.good,
      ),
      isFinal: true,
    );
  }

  test('成功评估：带上 accessToken，进入 completed', () async {
    final api = _ScriptApi(okStream);
    final c = await make(api);
    await evaluate(c);

    expect(st(c).phase, RetellReviewEvaluationPhase.completed);
    expect(api.lastAccessToken, 'test-token');
  });

  test('未登录直接失败，不转码也不发请求', () async {
    final api = _ScriptApi(okStream);
    final c = await make(api, authenticated: false, hasSession: false);
    await evaluate(c);

    expect(st(c).phase, RetellReviewEvaluationPhase.failed);
    expect(st(c).errorCode, 'auth_required');
    // 闸门必须早于 ffmpeg 转码与 2MB 上传。
    expect(preparer.callCount, 0);
    expect(api.callCount, 0);
  });

  test('后端 401 → auth_required', () async {
    final api = _ScriptApi(() => Stream.error(_httpError(401)));
    final c = await make(api);
    await evaluate(c);

    expect(st(c).errorCode, 'auth_required');
  });

  test('其余后端错误仍为 request_failed', () async {
    final api = _ScriptApi(() => Stream.error(_httpError(503)));
    final c = await make(api);
    await evaluate(c);

    expect(st(c).errorCode, 'request_failed');
  });
}
