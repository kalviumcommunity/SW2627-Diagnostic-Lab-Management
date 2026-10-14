# User & Operational Guide
# SW2627: Diagnostic Lab Management (LabTrack)

This guide provides end-to-end operational instructions and testing scenarios for each of the five user roles supported by **LabTrack**.

---

## 👥 Overview of Roles

LabTrack uses dynamic Role-Based Access Control (`UserRole`) with a role switcher on startup:

| Role | Primary User | Core Responsibilities |
|---|---|---|
| **Patient** | Test Patients | Book home collections, monitor live specimen progress, download signed PDF reports |
| **Phlebotomist** | Home Collection Field Staff | View assigned bookings, scan physical tube barcodes, log temperature and custody handover |
| **Lab Technician / Pathologist** | Laboratory Testing Bench | Accession incoming racks, inspect sample QC, enter quantitative test results, digitally sign reports |
| **Front Desk** | Reception & Clinic Executives | Rapid paperless search by barcode, phone, or order ID; resolve walk-in inquiries; print reports |
| **Administrator** | Lab Operations Manager | Manage branches, allocate phlebotomist fleets, review turnaround time (TAT) and rejection metrics |

---

## 🩺 1. Patient Workflow

### 1.1 Booking a Home Sample Collection
1. **Launch App**: Select the **Patient** role on the initial screen.
2. **Browse Catalog**: View available diagnostic tests and comprehensive health packages (e.g., Complete Blood Count (CBC), Fasting Lipid Profile, HbA1c, Thyroid Stimulating Hormone).
3. **Select Tests & Requirements**: The UI automatically highlights fasting instructions (e.g., 10-12 hours overnight fasting for lipid profiles) and collection container types.
4. **Choose Slot & Address**: Select your preferred collection date, morning time slot, and home address.
5. **Confirm Order**: Submit the booking. The system immediately issues a unique `OrderId` (e.g., `ORD-2026-1049`).

### 1.2 Live Specimen Tracking
1. Navigate to the **Track Sample** screen.
2. View your sample's live progress bar (10% to 100% completion) moving through milestones:
   - `Booking Confirmed` (10%)
   - `Phlebotomist Assigned` (20%)
   - `Sample Collected` (35%)
   - `In Transit to Branch Hub` (50%)
   - `Received at Branch Hub` (65%)
   - `Transferred to Central Lab` (75%)
   - `Received at Central Lab` (85%)
   - `Processing & Testing` (90%)
   - `Report Ready & Verified` (100%)
3. Review cold-chain status to verify sample integrity (e.g., `4.0°C - Cold Chain Maintained`).

### 1.3 Downloading Reports
1. Go to **My Reports**.
2. Once status transitions to `Report Ready`, click **View Report** or **Download PDF**.
3. Inspect analytical parameter readings, biological reference intervals, and digital pathologist signature.

---

## 💉 2. Phlebotomist Workflow

### 2.1 Viewing the Collection Queue
1. Log in with the **Phlebotomist** role.
2. The dashboard displays today's assigned patient home visits sorted by appointment time and geographical proximity.
3. Tap an order to open the patient details, address, test requirements, and contact phone number.

### 2.2 Doorstep Barcode Tagging & Collection
1. Upon arriving at the patient's residence, tap **Start Collection**.
2. **Barcode Binding**:
   - Tap **Scan Barcode** (or input the alphanumeric barcode printed on the sterile vacuum tube, e.g., `SMP-90214`).
   - Select vial type (e.g., `Standard EDTA (Purple Top)`, `Serum SST (Gold Top)`).
3. **Cold-Chain & Environmental Logging**:
   - Confirm sample temperature placed into the insulated cold-box (`2°C - 8°C`).
   - The app records GPS coordinates, local device timestamp, and phlebotomist identity into an immutable `SampleEventModel`.
4. Tap **Confirm & Secure Sample**. The sample status instantly updates to `collected`.

### 2.3 Handover to Branch Hub
1. At the end of the collection run, transport the cold-box to the assigned Branch Collection Hub.
2. Select batches in transit and tap **Handover to Hub** to transition samples to `receivedAtBranch`.

---

## 🔬 3. Laboratory Technician & Pathologist Workflow

### 3.1 Batch Accessioning & Quality Inspection
1. Log in under the **Lab Technician** role.
2. Tap **Accession Incoming Samples**.
3. Scan or enter tube barcodes received from the branch logistics van.
4. **Quality Control (QC)**:
   - **Accept**: If sample volume is sufficient and unhemolyzed, mark as `receivedAtLab` and assign to an analyzer rack.
   - **Reject**: If specimen is clotted, severely hemolyzed, or degraded due to temperature excursion, tap **Reject Sample**, select the rejection reason, and trigger an automated recollection alert.

### 3.2 Test Parameter Entry
1. Select an accessioned sample in `processing`.
2. Enter observed quantitative and qualitative findings for each parameter:
   - e.g., Hemoglobin (`14.2 g/dL`), Total WBC (`7,400 /uL`), Platelet Count (`240,000 /uL`).
3. The engine automatically flags abnormal values (`HIGH` in crimson, `LOW` in amber).
4. Save and forward for pathologist sign-off.

### 3.3 Pathologist Verification & Report Signing
1. Review test findings against standard clinical reference intervals.
2. Add diagnostic remarks or interpretations.
3. Electronically sign the report. The sample status transitions to `reportReady`.

---

## 🖥️ 4. Front-Desk Receptionist Workflow

### 4.1 Zero-Paper Inquiry Resolution
1. Log in with the **Front Desk** role.
2. **Instant Search Bar**: Enter any identifier:
   - Patient Mobile Number (e.g., `9811122233`)
   - Order ID (e.g., `ORD-2026-1049`)
   - Barcode ID (e.g., `SMP-90214`)
   - Patient Name (e.g., `Aarav Patel`)
3. Results render in **< 500ms** without needing to look up physical paper counter slips.

### 4.2 Live Stage & Report Printing
1. View the exact sample location, custodian name, and status timestamp.
2. If the report is ready, tap **View & Print Report** to trigger standard browser printing or PDF download.

---

## 📊 5. Administrator Workflow

### 5.1 Network Operations & Branch Management
1. Log in with the **Administrator** role.
2. Inspect active branches, collection hubs, and testing laboratories.
3. Review real-time sample routing between collection spokes and the central reference hub.

### 5.2 SLA & Quality Metrics Dashboard
1. Review Key Performance Indicators (KPIs):
   - **Average Turnaround Time (TAT)**: Collection to Report Sign-Off.
   - **Phlebotomist Efficiency**: Samples collected per field executive.
   - **Sample Rejection Ratio**: Target `< 0.8%`.
   - **Cold-Chain Excursion Alerts**: Track transit temperature compliance.
