import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

/// PR #33 rehber yolları — mobil sabitlerle hizalı kalmalı.
void main() {
  test('agency PR #33 core paths', () {
    expect(ApiEndpoints.agencyRoot, '/api/agency');
    expect(ApiEndpoints.agencyRoster, '/api/agency/roster');
    expect(ApiEndpoints.agencyBlocks, '/api/agency/blocks');
    expect(ApiEndpoints.agencyWallet, '/api/agency/wallet');
    expect(ApiEndpoints.agencyWalletTransfer, '/api/agency/wallet/transfer');
    expect(ApiEndpoints.agencyWalletTransactions, '/api/agency/wallet/transactions');
    expect(ApiEndpoints.agencyMembers, '/api/agency/members');
    expect(ApiEndpoints.agencyPurchase, '/api/agency/purchase');
    expect(ApiEndpoints.agencyPeriods, '/api/agency/periods');
  });

  test('PK me parity paths', () {
    expect(ApiEndpoints.pkMeHistory, '/api/pk/me/history');
    expect(ApiEndpoints.pkMeStats, '/api/pk/me/stats');
    expect(ApiEndpoints.pkMeMatches, '/api/pk/me/matches');
  });
}
