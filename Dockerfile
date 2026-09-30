# ==============================================================================
# Dockerfile for LabTrack (Flutter Android App)
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:stable

# Set container working directory
WORKDIR /app

# Ensure Android SDK licenses are accepted
RUN yes | sdkmanager --licenses || true

# Copy dependency definition file first for optimal Docker layer caching
COPY lab_track/pubspec.yaml ./lab_track/

# Download and resolve dependencies
WORKDIR /app/lab_track
RUN flutter pub get

# Copy the complete application source code
WORKDIR /app
COPY lab_track/ ./lab_track/

# Set the active working directory to the Flutter app
WORKDIR /app/lab_track

# Run flutter doctor to verify Android toolchain
RUN flutter doctor -v

# Default command: build the Android debug APK
CMD ["flutter", "build", "apk", "--debug"]
