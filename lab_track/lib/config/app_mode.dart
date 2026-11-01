/// Demo builds use synthetic data only and never connect to Firebase.
const bool isDemoMode = bool.fromEnvironment('LABTRACK_DEMO', defaultValue: false);
