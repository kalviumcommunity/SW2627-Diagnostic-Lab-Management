/// Demo builds use synthetic data and allow instant persona switching.
/// Default is true so that APKs generated via Android Studio or standard `flutter build apk`
/// are immediately interactive with pre-populated medical workflows.
/// Pass `--dart-define=LABTRACK_DEMO=false` for strict production deployments.
const bool isDemoMode = bool.fromEnvironment('LABTRACK_DEMO', defaultValue: true);
