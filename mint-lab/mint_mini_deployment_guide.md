# A Guide to Deploying Services on a Mac Mini Homelab

**Report Date: 2025-10-26**

## Introduction to the Mac Mini Homelab

This guide provides a technical walkthrough for deploying a suite of services on a **late 2014 Mac Mini**. This machine, running **Mint Linux** and upgraded with a **1 TB SSD**, serves as a capable and energy-efficient homelab server. This setup leverages the Mac Mini's x86_64 architecture, making it suitable for a wide range of containerized applications without the compatibility concerns of ARM-based platforms. The deployment is managed entirely through Docker and Docker Compose, ensuring a reproducible, isolated, and easily manageable environment. This document details the configuration of core database services, a reactive web development backend (Convex), and a CalDAV/CardDAV server (RustiCal), serving as a blueprint for this specific homelab configuration.

## Core System Preparation and Best Practices

The foundation of this homelab is a late 2014 Mac Mini running Mint Linux. The upgrade to a 1 TB SSD provides ample and fast storage for container volumes and application data.

Before launching the services, the following preparation is required:

1.  **Docker Engine and Compose:** Install Docker Engine and the Docker Compose plugin directly on Mint Linux. This can be done by following the official Docker installation instructions for Debian-based distributions.
2.  **.env File:** Create a `.env` file in the root of the project directory. This file is crucial for managing secrets and environment-specific configurations. It should contain the necessary passwords and URLs for the services, such as:
    *   `POSTGRES_PASSWORD`: The password for the main PostgreSQL user.
    *   `MYSQL_PASSWORD`: The root password for the MariaDB server.
    *   `CONVEX_POSTGRES_URL`: The full database connection URL for the Convex backend.
3.  **Initialization Script (`init-dbs.fish`):** The setup relies on a Fish script named `init-dbs.fish` to perform initial setup tasks for the databases. This script is executed by one-off containers (`init-postgres` and `init-mariadb`) at startup.

The services are defined within a single `compose.yaml` file and connected via a custom bridge network named `homelab`, which allows for easy inter-service communication using container names as hostnames.

## Service Deployment Guides

### Core Database Services

This homelab runs two primary relational database services to support various applications.

*   **PostgreSQL (`postgres`):** A powerful, open-source object-relational database system.
    *   **Image:** `tensorchord/pgvecto-rs:pg14-v0.2.0`. This specific image is notable as it includes the `pgvecto-rs` extension, providing vector similarity search capabilities, which is often used for AI and machine learning applications.
    *   **Configuration:** The service is configured with a username (`admin`) and a password sourced from the `.env` file. Data is persisted using a named volume (`postgres_data`). A healthcheck is included to ensure the container is ready before dependent services start.
*   **MariaDB (`mariadb`):** A popular, community-developed fork of the MySQL relational database management system.
    *   **Image:** `mariadb:11`.
    *   **Configuration:** The root password is set via the `.env` file. Data is persisted in a named volume (`mariadb_data`).

### In-Memory Data Store

*   **Redis (`redis`):** An in-memory data structure store, commonly used as a database, cache, and message broker.
    *   **Image:** `redis:6.2-alpine`. The `alpine` tag indicates a lightweight version of the image.
    *   **Configuration:** The setup is straightforward, exposing the standard Redis port (`6379`) and connecting it to the `homelab` network.

### Application Services

*   **RustiCal (`rustical`):** A modern CalDAV and CardDAV server for synchronizing calendars and contacts.
    *   **Image:** `ghcr.io/lennart-k/rustical:0.9.12`.
    *   **Configuration:** The service exposes port `4000` and uses a named volume (`rustical_data`) for persistent storage of calendar and contact data.

*   **Convex Stack (`convex-backend` & `convex-dashboard`):** A reactive backend platform that simplifies web development by providing a realtime database and serverless functions.
    *   **`convex-backend`:** This is the core Convex service.
        *   **Image:** `ghcr.io/get-convex/convex-backend` pinned to a specific SHA for stability.
        *   **Configuration:** It connects to the PostgreSQL database via the `POSTGRES_URL` environment variable. It depends on the `postgres` service being healthy and the `init-postgres` job completing successfully. A healthcheck is configured to monitor the backend's status.
    *   **`convex-dashboard`:** A web-based user interface for managing the Convex backend.
        *   **Image:** `ghcr.io/get-convex/convex-dashboard` pinned to a specific SHA.
        *   **Configuration:** It connects to the backend via the `NEXT_PUBLIC_DEPLOYMENT_URL` environment variable and depends on the `convex-backend` being healthy before it starts.

### Initialization Jobs

*   **`init-postgres` & `init-mariadb`:** These are short-lived containers designed to run an initialization script (`init-dbs.fish`) for the databases. They use a lightweight `alpine:latest` image, install necessary tools (`fish`, `gettext`, `docker-cli`), and execute the script. They are configured to run only after their respective database services have started.

## Conclusion and Further Considerations

This `compose.yaml` file orchestrates a powerful and flexible development environment on a Mac Mini. The use of specific, pinned image versions ensures reproducibility, while the inclusion of database initialization jobs automates the setup process.

Key next steps and considerations for this homelab include:

*   **Networking and Reverse Proxy:** This setup uses **Tailscale Services** for reverse proxying, a deliberate choice over traditional solutions like Caddy for several reasons. Primarily, Tailscale integrates the reverse proxy directly into the network layer, which eliminates the need to manage a separate Caddy container, thus reducing architectural complexity and removing a potential point of failure. While Caddy is excellent for public-facing services, it requires exposing ports and managing its own configuration for SSL. In contrast, [Tailscale Services](https://tailscale.com/blog/services-beta) automatically handles HTTPS certificate issuance and renewal for all services on the private `.ts.net` domain without any public exposure. For a homelab where the primary goal is secure, zero-configuration access for internal services, Tailscale's approach is significantly more straightforward and secure.

*   **Backup Strategy:** Implementing an automated backup solution for the named volumes (`postgres_data`, `mariadb_data`, `rustical_data`, `convex_data`) is critical to prevent data loss.
