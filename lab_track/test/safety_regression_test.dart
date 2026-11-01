import 'package:flutter_test/flutter_test.dart';
import 'package:lab_track/config/app_mode.dart';
import 'package:lab_track/auth/backend/repositories/auth_repository.dart';
import 'package:lab_track/data/models/report_model.dart';
import 'package:lab_track/data/models/sample_event_model.dart';
import 'package:lab_track/domain/enums/sample_status.dart';
import 'package:lab_track/domain/enums/user_role.dart';
import 'package:lab_track/phlebotomist/backend/models/phlebotomist_collection_request.dart';

void main() {
  test('non-demo build rejects demo login and fabricated credentials', () async {
    if (isDemoMode) return;
    final auth = AuthRepository();
    await expectLater(auth.signInAsRole(UserRole.admin), throwsException);
    await expectLater(
      auth.signInWithCredentials(role: UserRole.admin, email: 'unknown@example.com', password: 'incorrect'),
      throwsException,
    );
    await expectLater(
      auth.verifyOtp(verificationId: 'demo-test', smsCode: '123456', phoneNumber: '1234567890'),
      throwsException,
    );
  });

  test('report signer and custody event ID survive serialization', () {
    final report = ReportModel(id: 'r', orderId: 'o', sampleBarcode: 's',
      patientId: 'p', status: 'Verified & Ready', pathologistName: 'Dr Test');
    expect(ReportModel.fromMap(report.toMap()).pathologistName, 'Dr Test');
    final event = SampleEventModel(id: 'event-1', sampleBarcode: 's',
      toStatus: SampleStatus.collected, timestamp: DateTime(2026),
      actorId: 'staff', actorName: 'Test', actorRole: UserRole.phlebotomist);
    expect(SampleEventModel.fromMap(event.toMap()).id, 'event-1');
    expect(ReportModel(id: 'r', orderId: 'o', sampleBarcode: 's',
      patientId: 'p', status: 'Not ready').isReady, isFalse);
  });

  test('cold-box reading must be finite and between 2 and 8 degrees', () {
    PhlebotomistCollectionRequest request(double temp) => PhlebotomistCollectionRequest(
      orderId: 'o', patientId: 'p', patientName: 'P', sampleBarcode: 'SMP-1234',
      vialType: 'tube', temperatureCelsius: temp, locationAddress: 'address',
      phlebotomistId: 'u', phlebotomistName: 'U');
    expect(request(2).validate(), isNull);
    expect(request(8).validate(), isNull);
    expect(request(1.9).validate(), isNotNull);
    expect(request(8.1).validate(), isNotNull);
    expect(request(double.nan).validate(), isNotNull);
  });
}
