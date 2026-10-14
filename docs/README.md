# LabTrack Documentation Suite
# SW2627: Diagnostic Lab Management System

Welcome to the comprehensive technical and operational documentation repository for **LabTrack** (Project Code: **SW2627**).

---

## 📚 Document Index

| Document | Purpose | Target Audience | Direct Link |
|---|---|---|---|
| **Product Requirements Document (PRD)** | Business objectives, user personas, functional requirements (FR-01 to FR-12), sample lifecycle state machine, and target KPIs. | Product Managers, Stakeholders, Developers | [PRD.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/PRD.md) |
| **High-Level Design (HLD)** | Architectural principles, system topology (hub-and-spoke), Clean Architecture layers, sequence flows, and security model. | Architects, Tech Leads, Cloud Engineers | [HLD.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/HLD.md) |
| **Low-Level Design (LLD)** | Cloud Firestore schemas, class models, repository contracts, state management, UI component tree, and security rules. | Software Engineers, QA Engineers | [LLD.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/LLD.md) |
| **User & Operational Guide** | Step-by-step operational workflows and walkthroughs for all 5 user roles (Patient, Phlebotomist, Lab Tech, Front Desk, Admin). | Clinical Staff, Support Teams, Testers | [USER_GUIDE.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/USER_GUIDE.md) |
| **CI/CD Pipeline & Quality Gates** | Multi-tier GitHub Actions pipeline, Chrome execution, static analysis, and Docker verification. | DevOps, Release Engineers, Developers | [CICD.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/CICD.md) |

---

## 🗺️ Architectural & Functional Traceability

```text
┌────────────────────────────────────────────────────────────────────────┐
│                          Business Problem                              │
│  - Phlebotomist/Lab status blindspots during home collection           │
│  - Fragile cold-chain and specimen transit misattribution              │
│  - Front-desk paper slip searching bottleneck (4-8 mins per patient)   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        PRD Requirements (PRD.md)                       │
│  FR-01: Multi-Role Authentication & Access Control (5 Personas)       │
│  FR-04: Barcode Vial Tagging & Doorstep Accessioning                   │
│  FR-05: Immutable Chain-of-Custody Telemetry (GPS, Temp, Timestamp)   │
│  FR-08: Analytical Result Entry & Pathologist Electronic Sign-off      │
│  FR-09: Front-Desk Instant Search (< 500ms, Zero-Paper Slips)          │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        HLD Architecture (HLD.md)                       │
│  - Clean Architecture (Presentation, Domain, Data)                     │
│  - Distributed Hub-and-Spoke Topology (Home -> Spoke -> Central Lab)   │
│  - Event-Sourced Chain-of-Custody Stream (/sample_events)              │
│  - Deterministic 11-Stage Sample Lifecycle State Machine               │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      LLD Implementation (LLD.md)                       │
│  - Firestore Collections: /users, /branches, /orders, /samples,        │
│    /sample_events, /reports                                            │
│  - Flutter Provider State Architecture (AuthProvider, etc.)            │
│  - Dynamic Role Routing via RoleRouter                                 │
│  - Production Nginx + Docker multi-stage containerization              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Navigation

- **Running the Application Locally**: See the [Main README.md Quick Start](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/README.md#quick-start-options).
- **Understanding Sample Statuses**: Review the [Sample Lifecycle State Machine in LLD.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/LLD.md#4-sample-lifecycle-state-machine--transitions).
- **Testing Each User Role**: Follow the step-by-step role scenarios in [USER_GUIDE.md](file:///a:/Projects/SW2627-Diagnostic-Lab-Management/docs/USER_GUIDE.md).
