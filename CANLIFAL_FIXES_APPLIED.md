# CANLIFAL Fixes Applied (diagnostic loop)

Döngü: **RUN → FAIL → ROOT CAUSE → FIX → RUN AGAIN → regression test**

## Bu oturum (altyapı)

- `CfResourceTracker` — timer/poller/SSE/TRTC/request envanteri
- `CfRootCauseAnalyzer` — BUG #00N rapor şablonu
- `CfDiagnosticReport` — modül özeti + markdown
- Senaryolar: `mobile/lib/core/diagnostics/scenarios/`
- Integration: `mobile/integration_test/*_real_device_test.dart`
- Koşucu: `scripts/run-canlifal-diagnostics.sh`
- İzleme: SSE hub + TRTC join/leave hook

Otomatik kod düzeltmesi yalnızca FAIL kanıtı sonrası, minimum diff ile uygulanır.
