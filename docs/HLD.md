# High-Level Design (HLD)
# Smart Appliance Repair Dispatch & Diagnostics — RepairTrack

## 1. Architecture Goal

The HLD defines the major components and how they communicate. The design uses the repository's existing **Flutter + Firebase/Firestore** foundation.

## 2. Proposed Architecture

```text
                 ┌──────────────────────────────┐
                 │        Flutter Clients       │
                 │                              │
                 │ Dispatcher | Technician      │
                 │ Customer   | Manager         │
                 └──────────────┬───────────────┘
                                │
                     Firebase Authentication
                                │
                 ┌──────────────▼───────────────┐
                 │       Application Layer      │
                 │ Providers / Controllers      │
                 │ Use cases / business rules   │
                 └──────────────┬───────────────┘
                                │
             ┌──────────────────┼──────────────────┐
             │                  │                  │
      ┌──────▼──────┐    ┌──────▼──────┐    ┌──────▼──────┐
      │ Firestore   │    │ Location    │    │ Notification│
      │ Data        │    │ Service     │    │ Service     │
      └──────┬──────┘    └─────────────┘    └─────────────┘
             │
      ┌──────▼────────────────────────────────────┐
      │ Cloud Functions / Trusted Server Logic     │
      │ - assignment scoring                      │
      │ - repeat-fault detection                  │
      │ - arrival-window risk                     │
      │ - KPI aggregation                         │
      └───────────────────────────────────────────┘