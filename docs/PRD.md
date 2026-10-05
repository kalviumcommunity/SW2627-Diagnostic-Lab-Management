# Product Requirements Document (PRD)
# Smart Appliance Repair Dispatch & Diagnostics

## 1. Product Overview

**Product name:** RepairTrack

RepairTrack is a technician-dispatch and repair-diagnostics platform for a regional appliance repair service.

The system gives the back office a live operational view of:
- technician locations,
- technician workload and availability,
- appliance expertise,
- assigned jobs and arrival windows,
- previous repair history and repeated faults,
- first-time-fix performance.

The goal is to replace manual/intuition-based dispatching with data-driven assignment and give technicians the information needed to fix an appliance correctly on the first visit.

## 2. Problem Statement

A regional appliance repair service dispatches technicians across a city, but the back office assigns jobs without visibility into technician locations, current workloads, or appliance expertise. Customers receive arrival windows that are regularly missed, repeat visits for the same fault are not flagged, and the business has no data to improve first-time fix rates.

## 3. Goals

### Primary Goals

1. Match each repair job with an appropriate technician using location, availability, workload, and appliance expertise.
2. Provide live technician/job status to the dispatcher.
3. Track customer arrival windows and identify delays.
4. Detect previous/repeated faults before a technician visits.
5. Capture diagnosis, repair action, parts used, and visit outcome.
6. Measure first-time-fix rate and other operational KPIs.

### Success Metrics

| Metric | Target |
|---|---|
| First-time-fix rate | Increase over baseline |
| Missed arrival windows | Reduce significantly |
| Dispatcher assignment time | Reduce |
| Repeat-fault detection | 100% of known matching history surfaced |
| Technician location freshness | Near real-time during active jobs |
| Job status visibility | All active jobs have current status |

## 4. Users and Roles

### Dispatcher / Back Office

- View all open jobs.
- View technician locations, workload, availability, and expertise.
- Create/reassign jobs.
- Accept or override recommended technician assignments.
- Monitor arrival-window risk.
- View repeat-fault alerts.

### Technician

- View assigned jobs.
- Share current location while on duty/active job.
- See appliance details and previous repair history.
- Update status:
  - Accepted
  - En route
  - Arrived
  - Diagnosing
  - Repairing
  - Completed
- Record diagnosis, parts, work performed, and outcome.

### Customer

- Create/request a repair.
- See appointment/arrival window and status.
- Receive notifications about assignment, technician arrival, delay, and completion.
- View service history.

### Manager / Admin

- Manage technicians, appliance expertise, service areas, and users.
- View analytics such as:
  - First-time-fix rate
  - Repeat visits
  - Arrival-window performance
  - Technician utilization
  - Common faults
  - Jobs by appliance type

## 5. Functional Requirements

### FR-01: Authentication and Authorization

The system shall authenticate users and restrict features by role.

### FR-02: Customer Job Creation

A customer or dispatcher shall be able to create a repair job containing:

- Customer
- Appliance type
- Brand
- Model
- Reported fault
- Address/location
- Preferred appointment
- Arrival window

### FR-03: Technician Profile

Each technician shall have:

- Name/contact
- Current availability
- Current location
- Service area
- Appliance expertise
- Workload/active-job count
- Performance metrics

### FR-04: Smart Assignment

The system shall recommend technicians using:

1. Required appliance expertise
2. Technician availability
3. Distance/travel estimate
4. Current workload
5. Service-area compatibility
6. Appointment/arrival-window constraints

The dispatcher shall be able to accept or override the recommendation.

### FR-05: Live Job Tracking

The system shall track job states:

`NEW -> ASSIGNED -> ACCEPTED -> EN_ROUTE -> ARRIVED -> DIAGNOSING -> REPAIRING -> COMPLETED`

Alternative terminal states:

- `CANCELLED`
- `NO_ACCESS`
- `FOLLOW_UP_REQUIRED`

### FR-06: Arrival-Window Monitoring

The system shall compare the expected arrival window with technician status/location and flag jobs at risk of being late.

### FR-07: Repeat-Fault Detection

Before assignment and before diagnosis, the system shall search the customer's/appliance's service history for:

- Previous jobs for the same appliance
- Similar fault descriptions
- Recent repeat visits
- Unresolved/follow-up jobs

A repeat-fault alert shall be shown to the dispatcher and technician.

### FR-08: Diagnosis and Repair Record

A technician shall record:

- Diagnosis
- Fault category
- Root cause
- Repair performed
- Parts used
- Notes
- Completion status
- Whether the issue was fixed on the first visit

### FR-09: Notifications

The system shall notify relevant users when:

- A job is assigned
- Technician accepts
- Technician is en route
- Technician arrives
- Arrival is delayed
- Job is completed
- Follow-up is required

### FR-10: Analytics

Managers shall be able to view:

- First-time-fix rate
- Repeat-visit rate
- Missed/late arrival windows
- Average travel time
- Average repair duration
- Technician utilization
- Common fault categories
- Jobs by appliance type

## 6. Non-Functional Requirements

| Requirement | Description |
|---|---|
| Performance | Active job/dispatch screens should load quickly and updates should appear near real time. |
| Availability | Core dispatch and job tracking should remain available during business hours. |
| Security | Role-based access, authenticated users, protected customer information. |
| Scalability | Data model should support additional technicians, branches/service zones, and job volume. |
| Reliability | Job state changes must be persisted and auditable. |
| Usability | Dispatcher should understand technician workload and job risk from one dashboard. |
| Privacy | Location tracking should be limited to operational need and appropriate user consent/policy. |

## 7. MVP Scope

### In Scope

- Login and role-based access
- Customer/job creation
- Technician profiles and expertise
- Technician availability/location
- Dispatcher dashboard
- Smart technician recommendation
- Job status tracking
- Repeat-fault alert
- Diagnosis/repair record
- Basic notifications
- First-time-fix and operational dashboard

### Out of Scope for MVP

- Automated route optimization across dozens of jobs
- Payment processing
- Spare-parts purchasing
- AI diagnosis
- Predictive failure forecasting
- Full customer billing/accounting

## 8. Core User Stories

### US-01 — Dispatcher Assignment

> As a dispatcher, I want to see nearby available technicians with matching appliance expertise so that I can assign the best technician instead of guessing.

### US-02 — Technician Context

> As a technician, I want to see the appliance's previous faults and repairs before visiting so that I can prepare and avoid an unnecessary repeat visit.

### US-03 — Customer Visibility

> As a customer, I want to know whether my technician is on the way and whether the arrival window is at risk so that I am not waiting without information.

### US-04 — Manager Analytics

> As a manager, I want first-time-fix and repeat-visit metrics so that I can identify training, staffing, and process problems.

## 9. Acceptance Criteria

### Smart Assignment

- A job cannot be recommended to an unavailable technician.
- Matching appliance expertise increases recommendation priority.
- Distance and workload influence the recommendation.
- Dispatcher can manually override the recommendation.

### Repeat Fault

- A matching recent service history is visible before the visit.
- Technician can view the previous diagnosis and repair.
- A follow-up job can be linked to the original job.

### First-Time Fix

- A completed job records whether the appliance was fixed during that visit.
- Follow-up/repeat visits are linked to the previous job.
- Dashboard calculates first-time-fix rate from completed jobs.

## 10. KPIs

### First-Time-Fix Rate

`FTF % = jobs fixed on first visit / completed repair jobs × 100`

### Repeat Visit Rate

`Repeat Visit % = repeat/follow-up visits / completed repair jobs × 100`

### On-Time Arrival Rate

`On-Time % = jobs arriving within promised window / completed visits × 100`

### Technician Utilization

`Utilization % = active/assigned working time / available working time × 100`

## 11. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| GPS unavailable | Use last known location and clearly show stale location time. |
| Poor location accuracy | Use location timestamp/accuracy and avoid pretending GPS is exact. |
| Wrong expertise data | Admin can maintain technician skill profiles. |
| Too many recommendations | Rank candidates and explain the main ranking factors. |
| Repeat fault not described similarly | Combine appliance identity, fault category, and recent history; allow manual linking. |
| Network interruption | Cache safe local UI state and retry writes where appropriate. |