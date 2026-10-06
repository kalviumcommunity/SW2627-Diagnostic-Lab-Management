# SW2627: Diagnostic Lab Management (LabTrack)

## Problem Statement

A network of diagnostic labs collects patient samples at home and processes them across multiple branches, but phlebotomists and lab technicians share no digital status tracking. Samples are misattributed or delayed in transit, and front-desk staff cannot locate reports without manually tracing physical slips.

---

## Overview

**LabTrack** is a diagnostic lab management system built with Flutter to provide end-to-end digital tracking of patient samples:
- Real-time digital status updates between phlebotomists and laboratory technicians.
- Chain-of-custody tracking across home collection and multi-branch transit.
- Instant digital report lookup for front-desk staff, eliminating reliance on manual physical slips.

## Project Structure

- [`lab_track/`](lab_track/): Flutter mobile/web application codebase.
- [`Dockerfile`](Dockerfile): Multi-stage Dockerfile producing a lightweight `nginx:alpine` runtime image.
- [`docker-compose.yml`](docker-compose.yml): Docker Compose configuration with port mapping for local browser view.
- [`nginx.conf`](nginx.conf): Nginx configuration optimized for Flutter Web SPA routing and caching.
- [`docker-entrypoint.sh`](docker-entrypoint.sh): Container entrypoint script displaying the direct localhost link upon startup.

---

## Quick Start with Docker

### 1. Build and Run Container
```bash
docker compose up -d --build
```

### 2. View in Browser
Open your browser and navigate to:
👉 **[http://localhost:8080](http://localhost:8080)**

### 3. View Logs (Displays Localhost Access Link)
```bash
docker compose logs -f
```

### 4. Stop the Container
```bash
docker compose down
```
