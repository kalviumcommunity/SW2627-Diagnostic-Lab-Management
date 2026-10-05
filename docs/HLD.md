# High-Level Design (HLD)
# SW2627: Diagnostic Lab Management (LabTrack)

## 1. Document Control & Metadata

| Field | Value |
|---|---|
| **System Name** | LabTrack (Diagnostic Lab Management System) |
| **Project Code** | SW2627 |
| **Document Version** | 2.0.0 |
| **Status** | Approved Architectural Specification |
| **Architectural Style** | Clean Architecture / Event-Driven Reactive Mobile & Web |
| **Primary Cloud Infrastructure** | Google Firebase (Auth, Cloud Firestore, Cloud Storage, FCM) |
| **Frontend Framework** | Flutter 3.x (Multiplatform: Android, iOS, Web) |

---

## 2. Architecture Goal & Principles

The High-Level Design establishes the macro-architectural structure for **LabTrack**, addressing the operational breakdown between field phlebotomists, multi-branch transit networks, testing laboratories, and front-desk customer service desks.

### Core Architectural Principles
1. **Clean Architecture Separation**: Strict boundaries between Presentation, Domain (Business Rules & Entities), and Data (Repositories, Firebase SDK, Hardware Camera) layers.
2. **Event-Sourced Chain of Custody**: Rather than merely mutating a status field, every custody handoff or state change creates an immutable event record (`SampleEventModel`).
3. **Offline-First Resilience**: Mobile clients used by field phlebotomists must function under intermittent 3G/4G connectivity, caching scans locally and synchronizing seamlessly upon reconnection.
4. **Real-Time Reactive State**: Utilizing Cloud Firestore snapshot streams so that front-desk personnel and patients receive live operational updates without manual screen refreshing.
5. **Zero-Trust Role-Based Access Control (RBAC)**: All database reads, writes, and cloud assets are gated at the database engine level via Firestore Security Rules, verifying token claims.

---

## 3. High-Level System Architecture Diagram

```mermaid
graph TD
    subgraph ClientLayer ["Client Presentation Layer (Flutter Multiplatform)"]
        PatientApp["Patient Portal<br/>(Mobile / Web)"]
        PhleboApp["Phlebotomist App<br/>(Android Mobile)"]
        LabDesk["Laboratory & Pathologist Portal<br/>(Desktop / Web)"]
        FrontDesk["Front-Desk Search Console<br/>(Desktop / Web)"]
        AdminPortal["Admin SLA Dashboard<br/>(Desktop / Web)"]
    end

    subgraph GatewayAuth ["Authentication & API Gateway"]
        FirebaseAuth["Firebase Authentication<br/>(Phone OTP & Email/Password RBAC)"]
    end

    subgraph AppControllers ["Application & Business Logic Layer (Clean Architecture)"]
        AuthRepo["AuthRepository"]
        OrderRepo["OrderRepository"]
        SampleRepo["SampleRepository"]
        ReportRepo["ReportRepository"]
        BranchRepo["BranchRepository"]
        StateEngine["Sample Lifecycle State Machine"]
    end

    subgraph PersistenceLayer ["Cloud Persistence & Infrastructure (Firebase)"]
        Firestore["Cloud Firestore (NoSQL)<br/>- /users<br/>- /branches<br/>- /orders<br/>- /samples<br/>- /sample_events<br/>- /reports"]
        CloudStorage["Firebase Cloud Storage<br/>(Encrypted PDF Lab Reports)"]
        FCM["Firebase Cloud Messaging (FCM)<br/>(Push & SMS Notifications)"]
    end

    subgraph ExternalDevices ["Peripherals & Hardware"]
        CameraScanner["Barcode / QR Scanner<br/>(Camera / Zebra Scanner)"]
        ThermalPrinter["Slip & Report Thermal Printer"]
    end

    %% Client to Auth
    PatientApp -->|Auth Request| FirebaseAuth
    PhleboApp -->|Auth Request| FirebaseAuth
    LabDesk -->|Auth Request| FirebaseAuth
    FrontDesk -->|Auth Request| FirebaseAuth
    AdminPortal -->|Auth Request| FirebaseAuth

    %% Client to App Layer
    PhleboApp -->|Scan Barcode| CameraScanner
    FrontDesk -->|Print Reports| ThermalPrinter
    PatientApp --> AppControllers
    PhleboApp --> AppControllers
    LabDesk --> AppControllers
    FrontDesk --> AppControllers
    AdminPortal --> AppControllers

    %% App Layer to Persistence
    AppControllers --> Firestore
    AppControllers --> CloudStorage
    AppControllers --> FCM
```

---

## 4. Multi-Branch Diagnostic Network Topology (Hub-and-Spoke)

Diagnostic testing in LabTrack operates across a distributed multi-branch topology:

```mermaid
graph LR
    subgraph CollectionTier ["Collection Tier"]
        HomePatient["Patient Home<br/>(Doorstep Collection)"]
        SpokeBranch["Spoke Collection Center<br/>(Walk-in Sampling)"]
    end

    subgraph LogisticsTier ["Inter-Branch Transit & Logistics"]
        PhleboBike["Phlebotomist Courier<br/>(Cold-Box Transit)"]
        InterBranchVan["Inter-Branch Logistics<br/>(Temperature-Monitored Van)"]
    end

    subgraph ProcessingTier ["Central Diagnostic Hub"]
        BranchHub["Branch Collection Hub<br/>(Sorting & Initial Centrifuge)"]
        CentralLab["Central Reference Laboratory<br/>(Automated Testing & Pathologist Sign-Off)"]
    end

    HomePatient -->|Sample Draw & Barcode| PhleboBike
    PhleboBike -->|Check-in Handover| BranchHub
    SpokeBranch -->|Batch Handover| InterBranchVan
    InterBranchVan -->|Transfer| CentralLab
    BranchHub -->|Transfer to Central| CentralLab
    CentralLab -->|Verified PDF Report| HomePatient
    CentralLab -->|Verified Digital Report| SpokeBranch
```

### Topology Routing Logic
1. **Tier 1 (Home Collection)**: The phlebotomist draws blood into specialized vacuum containers (e.g., EDTA Purple, SST Gold), tags each vial with a pre-printed barcode, and logs the milestone into the mobile app.
2. **Tier 2 (Branch Collection Hub)**: The phlebotomist delivers sample batches to the nearest local branch. Hub staff scan incoming vials to confirm receipt, separating routine tests from specialized esoteric tests.
3. **Tier 3 (Central Reference Lab)**: Specialized or high-volume panels are transferred via refrigerated courier to the Central Reference Lab, where laboratory accessioning, processing, parameter analysis, and pathologist verification occur.

---

## 5. Architectural Subsystems

### 5.1 Presentation Subsystem (Flutter Single-Codebase)
- Built as a unified Flutter codebase targeting Android, iOS, and Web.
- Employs dynamic role-gated navigation: upon authentication, the user's role (`UserRole`) dictates the accessible navigation stack.
- Dedicated UI modules:
  - `features/patient`: Home booking, interactive test catalog, visual status timeline, report viewer.
  - `features/phlebotomist`: Pickup queue, home navigation, barcode camera scanner, collection confirmation.
  - `features/lab`: Batch rack scanning, accessioning, test parameter entry form, specimen rejection handler.
  - `features/frontdesk`: High-performance instant search bar (order ID/phone/barcode), slip-less report lookup, print spooler.
  - `features/admin`: Branch management, staff allocation, SLA compliance dashboard.

### 5.2 Barcode & Identification Subsystem
- Uses standard Code128 / QR alphanumeric symbology for diagnostic sample identification.
- Eliminates manual handwriting mistakes by pairing physical pre-barcoded tubes to the digital `SampleModel` in one camera scan.
- Allows front desk and lab technicians to execute zero-keystroke accessioning using either smartphone cameras or hardware USB/Bluetooth 2D barcode imagers.

### 5.3 Chain-of-Custody & Cold-Chain Telemetry Subsystem
- Enforces an append-only architecture: modifying a sample's status writes an entry into the `/sample_events` subcollection.
- Milestones record custodian metadata, GPS coordinates, location string, timestamp, and temperature reading (°C).
- If the logged temperature exceeds acceptable thresholds (e.g., > 8°C for cold-chain whole blood), the system flags a cold-chain warning.

### 5.4 Diagnostic Result Entry & Verification Engine
- Lab technicians input test findings matching discrete analytical parameters (`ReportParameter`).
- The engine automatically compares numeric values against sex- and age-specific biological reference intervals, tagging parameters with:
  - `Normal`: Within standard clinical range.
  - `High` / `Low`: Out-of-range parameters requiring physician review.
  - `Critical`: Severe panic values requiring immediate notification.
- Digital sign-off: Pathologists review entered values and digitally authorize the report, locking the document against subsequent alterations.

### 5.5 Front-Desk Instant Search Subsystem
- Designed to replace physical paper tracking slips.
- Indexes active orders and samples by:
  - Patient Phone Number (`patientPhone`)
  - Order Identifier (`orderId`)
  - Vial Barcode (`barcode`)
  - Patient Full Name (`patientName`)
- Queries execute directly against optimized Firestore indexes, delivering sub-second search results even under high concurrency.

---

## 6. End-to-End System Sequence Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Patient
    actor Phlebotomist
    actor LabTech
    actor Pathologist
    actor FrontDesk
    participant Firestore as Cloud Firestore
    participant Storage as Cloud Storage

    %% Step 1: Booking
    Patient->>Firestore: Create Order (Tests, Slot, Address) [OrderStatus: confirmed]
    Note over Firestore: Sample created [SampleStatus: booked]

    %% Step 2: Assignment & Pickup
    Firestore-->>Phlebotomist: Push Assigned Order [SampleStatus: phlebotomistAssigned]
    Phlebotomist->>Patient: Doorstep Arrival & Sample Collection
    Phlebotomist->>Firestore: Scan Vial Barcode & Log Temp [SampleStatus: collected]
    Note over Firestore: SampleEvent: Milestone 1 recorded

    %% Step 3: Transit
    Phlebotomist->>Firestore: Check out for Branch Transit [SampleStatus: inTransit]
    Phlebotomist->>Firestore: Handover at Branch [SampleStatus: receivedAtBranch]
    Note over Firestore: SampleEvent: Milestone 2 recorded

    %% Step 4: Central Lab Accessioning
    Firestore->>LabTech: Incoming Transit Notification
    LabTech->>Firestore: Scan Rack Inward [SampleStatus: receivedAtLab]
    LabTech->>Firestore: Start Analyzer Testing [SampleStatus: processing]

    %% Step 5: Results & Verification
    LabTech->>Firestore: Enter Test Parameters (Value, Unit, Flag)
    Pathologist->>Firestore: Review & Electronically Sign [SampleStatus: reportReady]
    Pathologist->>Storage: Generate & Upload PDF Report
    Storage-->>Firestore: Save Verified pdfUrl

    %% Step 6: Retrieval
    Patient->>Firestore: View Test Results & Download PDF
    FrontDesk->>Firestore: Instant Search by Barcode / Phone
    Firestore-->>FrontDesk: Return Real-Time Status & Print Report
```

---

## 7. Data Architecture & Storage Strategy

### 7.1 Cloud Firestore Collections
The database is structured into six top-level NoSQL collections:
1. `users`: Stores user profiles, authentication metadata, and role assignments (`patient`, `phlebotomist`, `labTechnician`, `frontDesk`, `admin`).
2. `branches`: Multi-branch network metadata (Hubs, Collection Centers, Central Lab, coordinates, contact info).
3. `orders`: High-level patient bookings, scheduled slots, payment status, list of sample barcodes.
4. `samples`: Granular vial entities with barcode primary key, order reference, current status, and vial type.
5. `sample_events`: Immutable audit trail documenting every custody milestone.
6. `reports`: Pathologist-verified diagnostic reports, parameter lists, abnormal flags, and PDF links.

### 7.2 Firebase Cloud Storage
- Stores compiled, print-ready PDF reports (`/reports/{orderId}/{sampleBarcode}.pdf`).
- Encrypted at rest using AES-256 server-side encryption.
- Read access gated through Firebase Storage Security Rules ensuring only authorized patients, attending clinicians, front desk, and admins can download documents.

---

## 8. Security, Privacy & Compliance Architecture

1. **Healthcare Data Privacy (HIPAA / DISHA)**:
   - Patient health information (PHI) and clinical results are strictly partitioned.
   - Audit logging ensures every view and download of diagnostic reports is registered with the requesting user ID.
2. **Transport & Data Security**:
   - All client-to-cloud network traffic is secured using TLS 1.3.
   - Firebase offline cache databases on mobile devices utilize platform-native AES encrypted storage.
3. **Role-Based Granular Access Rules**:
   - Patients can only read their own orders and reports (`request.auth.uid == resource.data.patientId`).
   - Phlebotomists can only update samples assigned to them.
   - Lab Technicians can write parameter data; only Pathologists/Admins can mark reports as verified (`reportReady`).
   - Front Desk has read-only access to search and view reports across all branches.

---

## 9. Deployment & Containerization Architecture

- **Mobile Client**: Compiled to native Android ARM64/x86_64 APK/AAB and iOS IPA.
- **Web / Desktop Console**:
  - The repository includes a production [`Dockerfile`](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/Dockerfile) and [`docker-compose.yml`](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docker-compose.yml) for containerized web hosting.
  - Nginx web server serves the Flutter Web build bundle with HTTP/2 and gzip/brotli compression enabled.
  - Healthcheck probes verify container availability on port 80.