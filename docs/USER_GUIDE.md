# User and demo guide

## Start and sign in

Run `flutter pub get` and `flutter run -d chrome` from `lab_track`.
The startup portal offers Patient, Phlebotomist, Front Desk, Clinical Laboratory
and Admin entries. Use the role's demo access to explore its dashboard. Email,
phone/OTP and Google authentication paths also exist, but depend on Firebase
configuration and may use demo fallbacks.

The authentication repository includes these default demonstration identities:

| Role | ID | Default identity |
| --- | --- | --- |
| Patient | `PT-84210` | John Doe |
| Phlebotomist | `PH-204` | Rahul Verma |
| Front desk | `FD-108` | Priya Sharma |
| Lab technician | `LAB-501` | Dr. Sarah Chen |
| Admin | `ADM-001` | Dr. Vikram Malhotra |

The seeded dataset adds 100 users across the five roles. Demo login and the OTP
shortcut `123456` are test behavior, not production identity verification.
Use demo data only. Changes are shared inside the running app and reset after a
restart; separate browser sessions do not share this in-memory state.

## Patient

1. Open the catalog/booking screen, select tests and provide the requested
   collection address, date and time slot.
2. Confirm the booking and inspect the resulting order in the patient dashboard.
3. Open sample tracking to see custody milestones, current status and available
   temperature information.
4. Open My Reports to view available results and authorization details.

Report-ready and delivered states show 100% progress; rejected is a separate
recollection state with 0% progress. Download controls may display confirmation
feedback; a generated PDF file is not guaranteed by this implementation.

## Phlebotomist

1. Open the pickup queue and select an assigned order.
2. Review the patient, address and requested tests, then open collection/scanning.
3. Scan a vial barcode or use Manual / Presets when a camera is unavailable.
4. Complete the collection details and confirm. Review the resulting sample and
   custody state before continuing the handover workflow.

For seeded data, Rahul's order `ORD-84210` and sample `SMP-88390` are useful
lookup examples. Camera capture needs permission; location/temperature metadata
does not establish continuous sensor monitoring.

## Front desk

1. Search using a patient name, phone, order ID or sample barcode, for example
   `John Doe`, `ORD-84210` or `SMP-88390`.
2. Inspect the returned order/sample, custodian and custody timeline.
3. Use walk-in requisition and thermal barcode/dispatch views to explore intake
   and labeling.
4. Open available reports and review results/readiness.

Search performance has no published benchmark. Print buttons include simulated
confirmation messages; they do not verify a physical printer job or PDF export.

## Laboratory and pathologist workflow

1. Inspect incoming samples and use the scanner/manual entry to accession a vial.
2. Assign an accepted specimen to a rack and review analyzer/rack details.
3. For a quality failure, record a QC rejection reason and review the updated
   sample/QC record. Automated patient push delivery is not implemented.
4. Enter test-result parameters and save the draft report.
5. Review and authorize/sign the report through the lab workflow, then confirm
   that report readiness is visible to other roles in the same running app.

`SMP-77401` is seeded at received-at-lab; `SMP-77219` is seeded report-ready.
Signing updates demo application metadata; it is not a certified digital-signature
service. Pathologist actions share the lab-technician role.

## Administrator

Open branch management, staff management and the SLA dashboard. Inspect branch
capabilities, staff allocations and available operational metrics. These views
use demonstration/shared state and do not prove operational SLA compliance.

## Verify an end-to-end change

Within one running application, create a patient booking, collect its vial as a
phlebotomist, search it at reception, then accession/process/authorize it in the
lab and revisit the patient report. Use sign-out/role selection between roles
without restarting the app. Compare order IDs/barcodes throughout the flow.
For repeatable automated coverage, run the cross-role data-flow suite described
in [CI/CD](CICD.md). Reload the app to restore the demo seed state if needed.
