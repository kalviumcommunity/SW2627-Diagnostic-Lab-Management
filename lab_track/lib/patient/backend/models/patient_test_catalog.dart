/// Diagnostic test definition available for patient home booking.
class DiagnosticTestItem {
  final String id;
  final String name;
  final int price;
  final bool requiresFasting;
  final String description;
  final String sampleType;

  const DiagnosticTestItem({
    required this.id,
    required this.name,
    required this.price,
    required this.requiresFasting,
    required this.description,
    required this.sampleType,
  });
}

class PatientTestCatalog {
  static const List<DiagnosticTestItem> availableTests = [
    DiagnosticTestItem(
      id: 'cbc',
      name: 'Complete Blood Count (CBC)',
      price: 350,
      requiresFasting: false,
      description: 'Checks overall health and detects anemia, infection, and platelet disorders.',
      sampleType: 'Whole Blood (EDTA Purple Top)',
    ),
    DiagnosticTestItem(
      id: 'lipid',
      name: 'Lipid Profile',
      price: 650,
      requiresFasting: true,
      description: 'Measures cholesterol and triglyceride levels to assess cardiovascular risk.',
      sampleType: 'Serum (SST Yellow/Gold Top)',
    ),
    DiagnosticTestItem(
      id: 'thyroid',
      name: 'Thyroid Panel (T3, T4, TSH)',
      price: 550,
      requiresFasting: false,
      description: 'Evaluates thyroid gland function and metabolic health.',
      sampleType: 'Serum (SST Yellow/Gold Top)',
    ),
    DiagnosticTestItem(
      id: 'hba1c',
      name: 'HbA1c (Glycated Hemoglobin)',
      price: 450,
      requiresFasting: false,
      description: 'Average blood sugar levels over the past 2-3 months for diabetes tracking.',
      sampleType: 'Whole Blood (EDTA Purple Top)',
    ),
    DiagnosticTestItem(
      id: 'vit_d_b12',
      name: 'Vitamin D & B12 Combo',
      price: 1200,
      requiresFasting: true,
      description: 'Crucial for bone density, neurological function, and energy vitality.',
      sampleType: 'Serum (SST Yellow/Gold Top)',
    ),
  ];
}
