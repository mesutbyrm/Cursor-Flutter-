import 'package:canlifal_social/features/admin/domain/admin_complaint.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('complaint status query maps legacy UI to PR #56 API', () {
    expect(complaintStatusQueryForApi('reviewing'), 'reviewed');
    expect(complaintStatusQueryForApi('resolved'), 'reviewed');
    expect(complaintStatusQueryForApi('pending'), 'pending');
    expect(complaintStatusQueryForApi('dismissed'), 'dismissed');
  });
}
