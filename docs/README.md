# LabTrack documentation

Documentation for the implementation on `main` at `d143a36` (27 October 2026).
The application is a Flutter prototype with five role dashboards and shared,
seeded data. Features described as requirements are not automatically complete.

| Document | Contents |
| --- | --- |
| [PRD](PRD.md) | Product requirements and implementation status |
| [High-level design](HLD.md) | Runtime architecture, data flow and integration boundaries |
| [Low-level design](LLD.md) | Models, lifecycle transitions and source locations |
| [User guide](USER_GUIDE.md) | Demo access and role workflow walkthroughs |
| [CI/CD](CICD.md) | Actual workflow gates, artifacts and local verification |

## Work implemented

- Patient booking, sample tracking and report views.
- Phlebotomist pickup, vial collection and custody workflows.
- Front-desk search, walk-in requisitions and thermal label views.
- Laboratory accessioning, racks, QC rejection, result entry and report authorization.
- Admin branch/staff operations and SLA views.
- Shared `CentralDataStore`, 100 seeded users and cross-role data-flow tests.
- Live camera barcode scanning with manual input/presets.
- Android toolchain updates and APK, web, Docker and Pages workflows.

The demo store lives in the running process; restarting the application rebuilds
its seeded data. Firebase authentication and repository code exist, but the demo
is not evidence of durable multi-device synchronization, enforced backend roles,
clinical certification, working PDF exports or push notifications. See the
[architecture boundaries](HLD.md#integration-boundaries).

The separate `feat/core-input-validators` branch contains validator utilities and
tests that are not part of this main snapshot. They are not documented as shipped.

## Run locally

From the repository root:

```sh
cd lab_track
flutter pub get
flutter run -d chrome
```

Use the [user guide](USER_GUIDE.md) for demo workflows and [CI/CD](CICD.md) for
verification. The [root README](../README.md) also describes Docker startup.
