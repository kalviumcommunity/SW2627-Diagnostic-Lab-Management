# CI/CD workflows and verification

The source of truth is [`.github/workflows`](../.github/workflows).
Documentation-only PRs still trigger the workflows: there are no docs path filters.

## Pull-request checks

[`ci.yml`](../.github/workflows/ci.yml) runs on push, pull request and manual
dispatch. A concurrency group cancels older runs for the same workflow/ref.

| Job | Dependency | Commands / outcome |
| --- | --- | --- |
| Static Analysis & Unit Tests | None | Stable Flutter, dependency resolution, formatting advisory, `flutter analyze --fatal-warnings --no-fatal-infos`, `flutter test --coverage` |
| Web Compilation & Chrome Execution | Analysis/tests | `flutter build web --release`, `flutter test --platform chrome`; web artifact retained 7 days |
| Docker Multi-Stage Build & Container Smoke Test | Web/Chrome | Build/load `labtrack:ci-test`, start Nginx on port 8080, retry up to 15 times for HTTP 200, inspect logs and remove successful test container |

Formatting is advisory: the command uses `|| echo` and `continue-on-error`.
Analyzer errors/warnings fail the job; informational diagnostics do not. Coverage
is generated without a minimum coverage threshold. HTTP 200 checks static
serving, not authenticated end-to-end application behavior.

[`build-apk.yml`](../.github/workflows/build-apk.yml) runs independently on every
PR, manual dispatch, and pushes to `main`, `master`, `Aryan-*`, `feat/*` and
`fix/*`. It installs Java 17, NDK 28.2.13676358 and stable Flutter, caches pub packages,
generates SDK paths in local.properties, resolves dependencies and runs:

```sh
flutter build apk --release --android-skip-build-dependency-validation --no-shrink --verbose
```

APK runs queue rather than cancel in progress, with a 45-minute job timeout
and a 30-minute build timeout. The workflow writes signing fingerprints to the
job summary. It omits the deprecated global `ndk.dir` so native plugins can resolve
their declared NDK versions without conflicting with a forced directory.

The `labtrack-release-apk` artifact is retained 14 days. Dependency validation is
explicitly bypassed; this is not proof of toolchain compatibility validation.
The Android project currently signs release builds with debug keys.

## Deployment

[`deploy-pages.yml`](../.github/workflows/deploy-pages.yml) runs on pushes to
`main`/`master` or manual dispatch. It builds web with a repository-name base href
and publishes through GitHub Pages using the `github-pages` environment. It is a
separate workflow without a dependency on CI completion. It does not run just
because a PR was opened. The Docker CI job builds locally and does not push an
image to a registry.

## Local verification

From `lab_track`, reproduce the analysis/test/web stages with:

```sh
flutter pub get
flutter analyze --fatal-warnings --no-fatal-infos
flutter test --coverage
flutter build web --release
flutter test --platform chrome
```

Chrome must be installed; set `CHROME_EXECUTABLE` if needed. Docker and Android
require their own installed toolchains. Run the APK command above for Android;
the Docker check builds from the repository root:

```sh
docker build -t labtrack:ci-test .
docker run -d --name test-app -p 8080:8080 labtrack:ci-test
curl --fail http://localhost:8080
docker stop test-app
docker rm test-app
```

The convenience scripts [`verify.ps1`](../scripts/verify.ps1) and
[`verify.sh`](../scripts/verify.sh) resolve dependencies, analyze, test and build
web. They do not run Chrome-platform tests, Docker or APK generation. Their
analyzer flags also differ from CI, so they are not exact pipeline replicas.

## Test coverage and merge readiness

The current test tree covers widgets, admin, front desk, laboratory, scanner,
seed-user integrity and cross-role data flow. These are local/demo tests rather
than proof of production Firebase behavior.

Before merging, inspect all checks for the PR's latest commit, including the
independent APK job, and confirm GitHub reports no merge conflicts with the
current base branch. Branch-protection settings determine which checks and
reviews are required; workflow files alone do not establish those settings.
Do not treat skipped downstream jobs after a failed prerequisite as passing.
