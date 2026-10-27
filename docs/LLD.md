# Low-level design

## Active modules and contracts

All paths below are relative to `lab_track/lib`.

| Module | Primary source | Responsibility |
| --- | --- | --- |
| Authentication | `auth/frontend/providers/auth_provider.dart`, `auth/backend/repositories/auth_repository.dart` | Session state, Firebase and demo access |
| Routing | `routing/role_router.dart` | Dashboard selection from canonical `UserRole` |
| Patient | `patient/backend/services/patient_api_service.dart` | Catalog, bookings and patient data |
| Collection | `phlebotomist/backend/services/phlebotomist_service.dart` | Pickup lookup, collection and custody |
| Reception | `frontdesk/backend/services/frontdesk_service.dart` | Search, walk-in requests and dispatch |
| Laboratory | `lab/backend/services/lab_service.dart` | Accessioning, racks, QC, results and authorization |
| Administration | `admin/backend/services/admin_service.dart` | Branch/staff operations and SLA data |
| Shared state | `data/services/central_data_store.dart` | In-process operational state and notifications |

Providers adapt these services to screens. Several service methods intentionally
delay responses to simulate a backend. Firestore repository paths coexist with
the shared store; not all operations are remote writes.

## Data model

Common models live in [`data/models`](../lab_track/lib/data/models).

| Model | Identity and relationships |
| --- | --- |
| `UserModel` | User ID, contact details, canonical role, optional branch/profile |
| `BranchModel` | Branch ID, address and testing capability |
| `OrderModel` | Order ID, patient, selected tests, schedule, branch, assignment and sample barcodes |
| `SampleModel` | Barcode, order/patient, current status/custodian/branch, temperature and custody events |
| `SampleEventModel` | Event ID, barcode/order, optional previous status, target status, actor and timestamp |
| `ReportModel` | Report ID, sample/order/patient, parameters, readiness and pathologist details |

`SampleEventModel` uses `fromStatus`, `toStatus`, `branchId`, `temperatureC` and
`note`, with optional latitude/longitude. Compatibility constructor aliases include
`status`, `locationName`, `temperatureCelsius` and `notes`. Consult each model's
`toMap`/`fromMap` for actual serialized fields; an in-memory event is not a
server-enforced append-only audit record.

Role-specific models cover booking requests/test catalogs, collection requests,
walk-in requisitions/labels/search results, racks/analyzers/QC and SLA metrics.

## Sample lifecycle state machine

The canonical enum is
[`domain/enums/sample_status.dart`](../lab_track/lib/domain/enums/sample_status.dart).
[`SampleStateMachine`](../lab_track/lib/domain/state_machine/sample_state_machine.dart)
defines these transitions:

| Current state | Allowed next states |
| --- | --- |
| `booked` | `phlebotomistAssigned`, `rejected` |
| `phlebotomistAssigned` | `collected`, `rejected` |
| `collected` | `inTransit`, `receivedAtBranch`, `rejected` |
| `inTransit` | `receivedAtBranch`, `receivedAtLab`, `rejected` |
| `receivedAtBranch` | `inTransitToCentralLab`, `processing`, `rejected` |
| `inTransitToCentralLab` | `receivedAtLab`, `rejected` |
| `receivedAtLab` | `processing`, `rejected` |
| `processing` | `reportReady`, `rejected` |
| `reportReady` | `delivered` |
| `delivered`, `rejected` | No different state |

`canTransition` also accepts the same state. The branch-to-processing shortcut
supports local testing; the transit-to-lab shortcut supports direct delivery.
This table describes the helper contract, not proof that every UI/store mutation
uses it. Rejected samples have no automatic transition back to booked.

Tracker percentages are 10, 20, 35, 50, 65, 75, 85, 90, 100 and 100 for the normal
sequence, and 0 for rejected. A pathologist is represented by lab-role workflow
and report metadata rather than a distinct `UserRole` value.

## Scanner and tests

[`UniversalQrScannerModal`](../lab_track/lib/shared/widgets/universal_qr_scanner_modal.dart)
uses `MobileScannerController` for camera input and `ScannerService` for barcode
extraction from raw values/URLs. Manual/preset entry is available as a fallback.

Tests in [`test`](../lab_track/test) cover the app widget, admin, front desk, lab,
QR scanning, seed users and cross-role flows. Cross-role tests exercise shared
state in one process; they do not establish multi-device Firebase persistence.

## Android configuration

Current Gradle sources specify AGP 8.9.1, Kotlin 2.3.0, Java/JVM 17, compile SDK 36
and minimum SDK 23. The app and APK workflow pin NDK 28.2.13676358, matching
the native JNI dependency. The app and APK workflow pin NDK 28.2.13676358, matching
the native JNI dependency. SDK discovery uses `android/local.properties`, then
`FLUTTER_ROOT`/`FLUTTER_HOME`. Release builds currently use the debug signing
configuration; the CI APK is a build artifact, not a production-signed release.
