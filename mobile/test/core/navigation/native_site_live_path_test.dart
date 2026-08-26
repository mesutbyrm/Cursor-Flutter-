import 'package:canlifal_social/core/navigation/native_site_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('/live hub ile /live/type ayrılır', () {
    expect(isLiveHubOnlyPath('/live'), isTrue);
    expect(isLiveHubOnlyPath('/live/'), isTrue);
    expect(isLiveHubOnlyPath('/live/type'), isFalse);
    expect(isLiveHubOnlyPath('/live/prep'), isFalse);
    expect(isLiveHubOnlyPath('/yayinci-ol'), isFalse);
  });
}
