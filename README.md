# SW2627: Diagnostic Lab Management (LabTrack)

[![Codemagic Build](https://img.shields.io/badge/Codemagic-CI%2FCD%20Ready-blue?logo=codemagic)](codemagic.yaml)
[![Flutter](https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20Storage-FFA611?logo=firebase)](https://firebase.google.com)
[![Docker](https://img.shields.io/badge/Docker-Production%20Nginx-2496ED?logo=docker)](Dockerfile)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**LabTrack** is an enterprise-grade diagnostic laboratory and sample lifecycle tracking system engineered to eliminate manual paper slips, specimen misattribution, and undetected cold-chain failures across multi-branch healthcare networks.

---

## 📑 Technical Documentation Index

| Document | Description | Target Audience | Direct Link |
|---|---|---|---|
| 🎓 **Viva Voce & Defense Guide** | Complete viva defense cheatsheet, 60s pitch, architecture, and top 20 questions & answers. | Evaluators, Examiners, Students | [docs/VIVA_VOICE_GUIDE.md](docs/VIVA_VOICE_GUIDE.md) |
| 📋 **Product Requirements (PRD)** | Business objectives, user personas, 12 functional requirements, KPIs, and acceptance criteria. | Stakeholders, Project Managers | [docs/PRD.md](docs/PRD.md) |
| 🏛️ **High-Level Design (HLD)** | Distributed hub-and-spoke topology, Clean Architecture layers, and Mermaid sequence flows. | System Architects, Tech Leads | [docs/HLD.md](docs/HLD.md) |
| 🔬 **Low-Level Design (LLD)** | Cloud Firestore NoSQL schemas, Dart class models, and state machine transition matrix. | Software Engineers, QA | [docs/LLD.md](docs/LLD.md) |
| 📱 **Codemagic CI/CD Guide** | Cloud build setup, Firebase Google Auth, SHA-1 fingerprints, and M2 runner configuration. | DevOps, Release Engineers | [docs/CODEMAGIC.md](docs/CODEMAGIC.md) |
| 🩺 **User & Operational Guide** | Step-by-step walkthrough for all 5 roles (Patient, Phlebotomist, Lab, Front Desk, Admin). | Clinicians, Lab Staff, Testers | [docs/USER_GUIDE.md](docs/USER_GUIDE.md) |
| 🛡️ **CI/CD Quality Gates** | GitHub Actions 3-tier quality gates, Chrome headless testing, and Docker health checks. | DevOps Engineers | [docs/CICD.md](docs/CICD.md) |

---

## 🏥 Problem Statement & Engineering Solution

### The Core Problem
1. **In-Transit Status Blindspot**: Field phlebotomists collecting blood at home share no real-time status with central lab testing benches.
2. **Cold-Chain & Integrity Failures**: Samples requiring strict temperature regulation (2°C – 8°C) suffer undetected delays or heat hemolysis.
3. **Paper Counter Slip Bottleneck**: Front-desk receptionists spend 4–8 minutes searching paper slips or calling processing labs to find report progress.
4. **Vial Misattribution**: Handwritten tube labels lead to transcription errors and lost accession numbers.

### The LabTrack Solution
- **Immutable Chain-of-Custody**: Every handoff is logged with custodian ID, role, timestamp, GPS coordinates, and temperature telemetry in an append-only audit ledger.
- **Sub-500ms Paperless Front-Desk Search**: Instant search by phone, barcode, or patient name replaces paper counter slips.
- **Doorstep Camera Barcode Tagging**: Phlebotomists scan sterile pre-barcoded vacuum tubes using native camera MLKit scanning.
- **Automated QC Specimen Recollection**: Lab pre-analytical rejections (hemolyzed/clotted specimens) instantly trigger free STAT priority re-draw orders for field staff.
- **Direct Patient Portal**: Live 10%–100% progress tracker and verified PDF report downloads.

---

## 🔄 The 11-Stage Sample Lifecycle State Machine

```
[1. booked] (10%)
    │
    ▼
[2. phlebotomistAssigned] (20%)
    │
    ▼
[3. collected] (35%) ───────────(Excursion / Hemolysis)────────► [11. rejected] (0%)
    │                                                                   │
    ▼                                                            (Auto-Triggers STAT
[4. inTransit] (50%)                                             Priority Recollection)
    │
    ▼
[5. receivedAtBranch] (65%)
    │
    ▼
[6. inTransitToCentralLab] (75%)
    │
    ▼
[7. receivedAtLab] (85%) ───────(Specimen Clotted / Lysis)──────► [11. rejected] (0%)
    │
    ▼
[8. processing] (90%) ──(Analyzer Rack photometric testing)
    │
    ▼
[9. reportReady] (100%) ─(Pathologist verifies & signs)
    │
    ▼
[10. delivered] (100%) ──(Patient views / Front desk prints)
```

---

## 👥 Multi-Role User Workspaces

| Workspace | Persona | Key Features |
|---|---|---|
| **Patient Portal** | Patients & Clients | Browse test catalog, book home collection slots, live progress tracker, download PDF reports. |
| **Phlebotomist Portal** | Home Collection Field Staff | Daily pickup route queue, camera barcode scanner, cold-box temp (°C) & GPS logger, branch handover. |
| **Laboratory Portal** | Lab Techs & Pathologists | Inward batch accessioning, QC rejection handler, analyzer rack loading, parameter entry, digital sign-off. |
| **Front Desk Portal** | Reception & Clinic Executives | Sub-500ms instant search by phone/barcode/name, walk-in registration, thermal barcode dispatch. |
| **Admin Portal** | Operations & Lab Directors | SLA dashboard, average Turnaround Time (TAT) metrics, rejection root-cause analysis, staff allocation. |

---

## 🚀 Quick Start Options

### Option 1: Mobile & Tablet Cloud Build (Codemagic CI/CD)
The project includes a ready-to-use [`codemagic.yaml`](codemagic.yaml) configured for the **Codemagic Free Tier (`mac_mini_m2`)**:
1. Connect this repository to [Codemagic.io](https://codemagic.io).
2. Start a new build on branch `main` or `Aryan-Flutter-Fix` with workflow **`android-workflow`**.
3. Download the generated **`app-release.apk`** from Artifacts and install on your phone or tablet!
*(See [`docs/CODEMAGIC.md`](docs/CODEMAGIC.md) for full instructions and Firebase Google Auth setup).*

### Option 2: Run with Docker Compose (Web Portal)
```bash
# 1. Build and start Nginx container
docker compose up -d --build

# 2. Open in your browser
# URL: http://localhost:8080

# 3. View container logs
docker compose logs -f

# 4. Stop the container
docker compose down
```

### Option 3: Local Flutter Development
```bash
cd lab_track
flutter pub get
flutter run -d chrome     # Run Web app
flutter run -d android    # Run Android app
flutter test              # Run automated test suite
```

---

## 📂 Repository Directory Blueprint

```
SW2627-Diagnostic-Lab-Management/
├── codemagic.yaml              # Codemagic CI/CD configuration (Free Tier mac_mini_m2)
├── Dockerfile                  # Multi-stage production Nginx container
├── docker-compose.yml          # Container port mapping (http://localhost:8080)
├── nginx.conf                  # Nginx SPA routing and caching configuration
├── docs/                       # Complete engineering documentation suite
│   ├── VIVA_VOICE_GUIDE.md     # Comprehensive viva defense & technical Q&A guide
│   ├── PRD.md                  # Product Requirements Document
│   ├── HLD.md                  # High-Level Architecture & Distributed Topology
│   ├── LLD.md                  # Low-Level Design, Firestore Schemas & State Machine
│   ├── CODEMAGIC.md            # Codemagic deployment & Firebase Auth configuration
│   ├── USER_GUIDE.md           # Role-based operational user guide
│   └── CICD.md                 # CI/CD Quality Gates & Docker verification
├── lab_track/                  # Flutter application source code
│   ├── android/                # Native Android config & Google Services
│   │   ├── app/build.gradle.kts # Release signing configuration
│   │   └── app/debug.keystore   # Bundled signing key matching Firebase SHA-1
│   ├── lib/
│   │   ├── main.dart           # App entry point & Provider hierarchy
│   │   ├── routing/            # Dynamic RoleRouter
│   │   ├── domain/             # Enums & SampleStateMachine
│   │   ├── data/               # Models, Repositories, CentralDataStore (100 seed users)
│   │   ├── patient/            # Patient frontend screens & backend services
│   │   ├── phlebotomist/       # Phlebotomist screens, queue & barcode scanner
│   │   ├── lab/                # Lab accessioning, analyzer racks & result entry
│   │   ├── frontdesk/          # Instant search (<500ms) & thermal dispatch
│   │   ├── admin/              # SLA dashboard & branch operations
│   │   ├── auth/               # Google Auth & 1-click role switcher
│   │   └── shared/             # Bio-tech theme tokens & universal scanner modal
│   └── test/                   # Cross-role data flow & integration tests
└── scripts/                    # Local CI/CD verification scripts (PowerShell / Bash)
```
