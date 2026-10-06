# ==============================================================================
# Multi-Stage Dockerfile for LabTrack (Flutter Web Application)
# Produces an ultra-lightweight production image using Nginx Alpine
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build Stage (Flutter SDK)
# ------------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Disable analytics for cleaner logs and faster builds
RUN flutter config --no-analytics

# Copy dependency specifications first for Docker layer caching
COPY lab_track/pubspec.yaml lab_track/pubspec.lock* ./lab_track/

# Resolve Flutter dependencies
WORKDIR /app/lab_track
RUN flutter pub get

# Copy all application source files
WORKDIR /app
COPY lab_track/ ./lab_track/

# Build Flutter Web in release mode
WORKDIR /app/lab_track
RUN flutter build web --release

# ------------------------------------------------------------------------------
# Stage 2: Runtime Stage (Lightweight Nginx Alpine)
# Final image size: ~25MB (vs ~5GB+ for Flutter SDK/Android image)
# ------------------------------------------------------------------------------
FROM nginx:alpine

# Copy custom Nginx configuration for Flutter single-page application routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script to display the clickable localhost link in console
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

# Copy compiled Flutter web assets from builder stage
COPY --from=builder /app/lab_track/build/web /usr/share/nginx/html

# Expose web server port
EXPOSE 8080

# Default port environment variable
ENV PORT=8080

# Run entrypoint script which logs the localhost link and starts Nginx
ENTRYPOINT ["/docker-entrypoint.sh"]
