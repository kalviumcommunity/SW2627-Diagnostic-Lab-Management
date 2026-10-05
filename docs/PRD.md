# Product Requirements Document (PRD)
# SW2627: Diagnostic Lab Management (LabTrack)

## 1. Document Control & Metadata

| Field | Value |
|---|---|
| **Product Name** | LabTrack (Diagnostic Lab Management System) |
| **Project Code** | SW2627 |
| **Document Version** | 2.0.0 |
| **Status** | Approved / Baseline |
| **Target Platforms** | Mobile (Android/iOS for Phlebotomists & Patients), Web/Desktop (Front Desk, Lab Techs, Administrators) |
| **Tech Stack** | Flutter (Dart), Firebase Auth, Cloud Firestore, Firebase Storage |

---

## 2. Executive Summary & Problem Statement

### 2.1 The Problem
Diagnostic healthcare providers operating across multi-branch networks face severe operational inefficiencies in sample tracking and diagnostic reporting:
1. **Disconnected Phlebotomist & Lab Operations**: Home collection executives (phlebotomists) and central laboratory technicians share no unified digital tracking mechanism. Once a sample is drawn at a patient's home, its status remains invisible until physical receipt at a lab.
2. **Chain-of-Custody & Cold-Chain Vulnerabilities**: Diagnostic samples (blood, serum, plasma, urine) require strict temperature control and time-sensitive processing. Without digital milestone tracking, transit delays, sample hemolysis, and temperature excursions go undetected until test rejection.
3. **Front-Desk Slip Bottleneck**: Front-desk receptionists cannot track the live status of pending lab tests without manually sifting through physical paper slips or placing repeated phone calls to processing benches, resulting in long patient queues and lost reports.
4. **Sample Misattribution & Loss**: Physical handwritten vial labels lead to specimen mix-ups, transcription errors, and missing accession numbers during multi-branch transit.

### 2.2 The Solution: LabTrack
**LabTrack** is an enterprise-grade diagnostic laboratory management and sample lifecycle tracking platform. It replaces manual paper slips with barcode-driven chain-of-custody tracking, enables real-time handoff verification between home collection phlebotomists and central labs, and provides front-desk executives and patients with instant digital report retrieval.

---

## 3. Goals & Success Metrics

### 3.1 Primary Goals
1. **End-to-End Sample Traceability**: Provide real-time visibility into every sample vial from collection, multi-branch transit, central accessioning, testing, to pathologist report sign-off.
2. **Zero-Paper Front-Desk Operations**: Allow front-desk staff to look up any patient, order, sample, or test report instantly by barcode, phone number, or order ID.
3. **Immutable Chain of Custody**: Log every custodian handoff with actor ID, role, GPS location, timestamp, and vial temperature status.
4. **Turnaround Time (TAT) Optimization**: Minimize turnaround delays between collection and report delivery through milestone tracking and automated status transitions.
5. **Sample Integrity & Rejection Prevention**: Track cold-chain compliance and flag delayed samples before specimen degradation occurs.

### 3.2 Success Metrics & Target KPIs

| Metric | Baseline (Manual Operations) | Target (LabTrack Implementation) |
|---|---|---|
| **Front-Desk Report Lookup Time** | 4 – 8 minutes (manual slip searching) | **< 5 seconds** (instant digital search) |
| **Specimen Misattribution Rate** | ~1.5% of total intake | **0.0%** (enforced barcode scanning) |
| **Sample Rejection / Recollection Rate** | 3.8% (delay/temperature failure) | **< 0.8%** (real-time transit monitoring) |
| **Average Test Turnaround Time (TAT)** | 14 – 22 hours | **< 8 hours** (for routine blood tests) |
| **Chain-of-Custody Audit Coverage** | 0% digital trail | **100%** tamper-evident event logging |
| **Patient Digital Report Adoption** | < 25% | **> 85%** direct in-app view and PDF download |

---

## 4. Users and Roles

The system enforces strict Role-Based Access Control (`UserRole`) with 5 dedicated user personas:

```text
               ┌────────────────────────────────────────────────────────┐
               │                     User Personas                      │
               └───────┬──────────┬──────────┬──────────┬──────────┬────┘
                       │          │          │          │          │
                       ▼          ▼          ▼          ▼          ▼
                  [Patient] [Phlebotomist]  [Lab Tech]  [FrontDesk]  [Admin]
```

### 4.1 Patient
- Books home collection slots for diagnostic tests (e.g., CBC, Lipid Profile, HbA1c, Thyroid Panel).
- Tracks phlebotomist dispatch and sample processing progress in real time via visual timeline.
- Views parameter-level results and downloads verified PDF lab reports.

### 4.2 Phlebotomist (Home Collection Executive)
- Views daily assigned home collection appointments with addresses, phone numbers, and test requirements.
- Scans and registers physical vial barcodes (EDTA purple top, SST yellow top, etc.) at the patient's doorstep.
- Captures collection timestamp, sample temperature condition, and collection notes.
- Hand-overs collected batches to branch hubs and logs transit milestones.

### 4.3 Laboratory Technician & Pathologist
- **Lab Technician**:
  - Scans and accessions incoming sample racks from branch hubs or phlebotomists.
  - Inspects vial integrity (flags hemolyzed/clotted specimens for rejection/recollection).
  - Enters quantitative and qualitative test parameter findings (e.g., Hemoglobin, WBC count, Total Cholesterol).
- **Pathologist**:
  - Reviews entered parameters against biological reference intervals.
  - Adds clinical interpretations/flags abnormal values and electronically signs/authorizes the final report.

### 4.4 Front-Desk Receptionist
- Instantly searches patient orders and test reports using Patient Phone Number, Order ID, or Sample Barcode.
- Replaces physical paper slips with digital status tracking and on-demand report printing.
- Resolves patient walk-in inquiries regarding sample testing progress.

### 4.5 Lab Administrator & Operations Manager
- Manages multi-branch networks (Branch Hubs, Collection Centers, Central Reference Labs).
- Oversees phlebotomist and lab technician staffing and workload allocation.
- Monitors operations through the SLA Dashboard (TAT trends, branch throughput, sample rejection ratios).

---

## 5. Functional Requirements

### FR-01: Authentication & Role-Based Access Control (RBAC)
- The system shall authenticate users via Firebase Authentication (Phone OTP for Patients/Phlebotomists and Email/Password credentials for Lab Staff & Administrators).
- The system shall inspect the user's role (`UserRole`) upon sign-in and route the user to their designated role portal (`/patient`, `/phlebotomist`, `/lab`, `/frontdesk`, or `/admin`).
- Unauthenticated or unauthorized role transitions shall be intercepted and rejected.

### FR-02: Patient Test Catalog & Home Booking
- The system shall present an interactive catalog of diagnostic tests with test pricing, sample container type (e.g., EDTA, SST), fasting requirements, and description.
- The patient shall be able to select multiple tests, choose an address, schedule a collection date and time slot, and confirm the booking order.
- The system shall generate a unique `OrderId` and associate it with the selected branch.

### FR-03: Phlebotomist Assignment & Dispatch Workflow
- The system shall assign booked collection orders to phlebotomists based on geographic service zone, branch affiliation, and schedule availability.
- The phlebotomist mobile interface shall display an organized queue of pending pickups, completed pickups, and patient route details.

### FR-04: Barcode Vial Tagging & Doorstep Accessioning
- During sample drawing at the patient's location, the phlebotomist shall scan or enter unique vial barcodes (`barcode`).
- The system shall validate that the barcode format complies with laboratory standards and link the vial to the corresponding `OrderId` and `PatientId`.
- The system shall record vial type (e.g., `Standard EDTA`, `Serum SST`, `Sodium Citrate`) and collection timestamp.

### FR-05: Immutable Chain-of-Custody Audit Trail
- Every state change or custodian transfer must generate an append-only `SampleEventModel` milestone record containing:
  - Unique Event ID (`id`)
  - Sample Barcode (`sampleBarcode`)
  - Target Status (`status`)
  - Timestamp (`timestamp`)
  - Actor ID, Name, and Role (`actorId`, `actorName`, `actorRole`)
  - Location Name (`locationName`)
  - Geographic Coordinates (`latitude`, `longitude`)
  - Specimen Temperature (`temperatureCelsius`)
  - Contextual Notes (`notes`)
- Event histories shall be immutable to ensure forensic compliance and prevent data tampering.

### FR-06: Multi-Branch Sample Routing & Transit Tracking
- The system shall support sample routing across a distributed hub-and-spoke laboratory network:
  1. Patient Home ➔ Branch Collection Hub
  2. Branch Collection Hub ➔ Central Reference Laboratory
- Couriers or phlebotomists shall check out samples into `inTransit` or `inTransitToCentralLab`.
- Receiving hubs shall batch-scan incoming vials into `receivedAtBranch` or `receivedAtLab`.

### FR-07: Lab Accessioning, Rack Management & QC
- Lab technicians shall scan incoming sample vials at the central laboratory to transition them to `receivedAtLab` and assign them to test benches/racks.
- Technicians shall inspect sample quality; if a sample is hemolyzed, clotted, or insufficient in volume, the technician shall transition it to `rejected` with mandatory rejection reasons, automatically notifying the patient and front desk for recollection scheduling.

### FR-08: Diagnostic Result Entry & Pathologist Verification
- Lab technicians shall enter specific analytical values for test parameters (e.g., `ReportParameter`: name, numeric value, unit, reference range, abnormal flag).
- The system shall automatically compute whether values fall into `Normal`, `High`, `Low`, or `Critical` categories.
- Pathologists shall review entered parameters, apply clinical interpretations, and digitally sign the report, transitioning status to `reportReady`.
- The system shall generate a standardized, print-ready PDF diagnostic report with watermarks, branch letterhead, and pathologist credentials.

### FR-09: Front-Desk Instant Search & Paperless Inquiries
- Front-desk staff shall have a high-speed search bar allowing lookup by:
  - Patient Mobile Number
  - Order ID
  - Sample Vial Barcode
  - Patient Full Name
- The search view shall return real-time status (`booked`, `collected`, `inTransit`, `processing`, `reportReady`), sample milestone timeline, and a one-click button to view or print the verified PDF report.
- The front-desk system shall eliminate the need for physical paper search slips.

### FR-10: Patient Real-Time Tracker & Report Download
- Patients shall have access to an intuitive visual progress bar displaying the exact stage of their sample (percentage completion from 10% to 100%).
- Upon report authorization, patients shall receive immediate in-app viewing access and one-click PDF report download capability.

### FR-11: Automated Notifications & Alerts
- The system shall issue real-time notification events when:
  - Phlebotomist is assigned and arrives.
  - Sample is received at the central laboratory.
  - Sample is flagged as rejected (recollection alert).
  - Diagnostic report is verified and ready for download.

### FR-12: Operational SLA Dashboard & Branch Analytics
- Administrators shall have access to real-time analytics displaying:
  - Average Turnaround Time (TAT) per test and per branch.
  - Sample collection volume per phlebotomist.
  - Sample rejection rate and root-cause breakdown.
  - Active sample inventory by branch status.

---

## 6. Sample Lifecycle State Machine

The platform strictly manages sample progression through eleven deterministic states:

```text
 [booked]
    │
    ▼
 [phlebotomistAssigned]
    │
    ▼
 [collected] ──(Temperature Excursion / Hemolysis)──► [rejected]
    │
    ▼
 [inTransit]
    │
    ▼
 [receivedAtBranch]
    │
    ▼
 [inTransitToCentralLab]
    │
    ▼
 [receivedAtLab] ──────(Specimen Clotted / Insufficient)──► [rejected]
    │
    ▼
 [processing]
    │
    ▼
 [reportReady]
    │
    ▼
 [delivered]
```

---

## 7. Non-Functional Requirements (NFRs)

| Category | Requirement Specification |
|---|---|
| **Performance** | Front-desk search queries must return results in **< 500ms**. Mobile UI must maintain **60 FPS** during list scrolling and barcode camera scanning. |
| **Scalability** | Cloud Firestore architecture must handle **100,000+ daily sample milestones** across 50+ branches without contention or throughput degradation. |
| **Availability & Resilience** | Core services must maintain **99.9% uptime**. Phlebotomist mobile app must support offline data entry (caching collected sample barcodes and syncing when connectivity resumes). |
| **Security & Privacy** | Compliance with healthcare data privacy principles (DISHA / HIPAA). All communications encrypted via TLS 1.3. Firestore documents protected by granular role-based security rules. |
| **Data Integrity** | Event history (`sample_events`) is append-only. Sample status can only move forward according to the deterministic state machine. |
| **Usability** | Single-handed barcode scanning workflow for field phlebotomists. High-contrast clinical alerts for abnormal test values (`High` in crimson, `Low` in amber). |

---

## 8. MVP Scope vs. Future Phases

### 8.1 In-Scope for MVP (Phase 1)
- Multi-role authentication (Patient, Phlebotomist, Lab Tech, Front Desk, Admin).
- Diagnostic test catalog and patient home collection appointment booking.
- Phlebotomist mobile queue with vial barcode registration.
- Chain-of-custody milestone logging (timestamp, user, location, temperature).
- Multi-branch transit status tracking (Home ➔ Branch ➔ Central Lab).
- Lab result entry with normal/abnormal parameter auto-flagging.
- Pathologist report verification and digital report viewer.
- Front-desk instant search by barcode, phone, and order ID.
- Operational SLA & sample volume dashboard.

### 8.2 Out of Scope for MVP (Phase 2 & 3)
- Automated AI-driven optical phlebotomy vein finder integration.
- Direct bidirectional HL7/ASTM interfacing with automated clinical chemistry analyzers (e.g., Roche Cobas, Sysmex).
- Third-party courier fleet algorithmic routing and GPS geofencing.
- Payment gateway integrations for instant online UPI/card settlements.

---

## 9. Core User Stories & Acceptance Criteria

### US-01: Doorstep Sample Barcode Tagging (Phlebotomist)
> **As a** field phlebotomist,  
> **I want to** scan the barcode on blood collection vials at the patient's doorstep,  
> **So that** the sample is digitally linked to the order with zero handwriting errors.
- **Acceptance Criteria**:
  - Scanning a barcode associates it with the active order in Firestore.
  - The sample state transitions from `phlebotomistAssigned` to `collected`.
  - A `SampleEventModel` milestone is generated with GPS, timestamp, and temperature reading.

### US-02: Instant Report & Status Lookup (Front Desk)
> **As a** front-desk receptionist,  
> **I want to** search for a patient by phone number or sample barcode in less than two seconds,  
> **So that** I can inform walk-in patients of their exact test status without searching for physical paper slips.
- **Acceptance Criteria**:
  - Search query matches substrings across phone numbers, patient names, and barcode IDs.
  - Result view displays real-time status and sample stage timeline.
  - If status is `reportReady`, a one-click button opens the complete PDF report.

### US-03: Diagnostic Parameter Entry & Abnormal Highlighting (Lab Tech)
> **As a** lab technician,  
> **I want to** record observed parameter values for ordered tests,  
> **So that** out-of-range parameters are visually highlighted for pathologist review.
- **Acceptance Criteria**:
  - Values entered outside the normal biological reference range automatically receive a `High` or `Low` flag.
  - The technician can submit the report draft for pathologist sign-off.

### US-04: Digital Report Access (Patient)
> **As a** patient,  
> **I want to** view my test progress and download my verified diagnostic report on my mobile device,  
> **So that** I do not have to travel to the lab branch to collect physical paper reports.
- **Acceptance Criteria**:
  - Patient sees dynamic progress bar matching `SampleStatus.progressPercentage`.
  - Report download is unlocked immediately upon `reportReady` status.