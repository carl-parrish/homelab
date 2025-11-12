# A Comprehensive Guide to Deploying Self-Hosted Services on a Raspberry Pi 5 Homelab

**Report Date: 2025-09-02**

## Introduction to the Raspberry Pi 5 Homelab

The advent of powerful single-board computers like the Raspberry Pi 5 has revolutionized the homelab landscape, offering a low-power, cost-effective, and highly capable platform for enthusiasts to host a wide array of personal services. This guide provides a comprehensive technical walkthrough for deploying over a dozen self-hosted applications on a Raspberry Pi 5. The focus is on leveraging Docker and Docker Compose for streamlined management, with a critical examination of system requirements, database dependencies, storage strategies, and the nuances of ARM64 architecture compatibility. By containerizing applications, users can achieve isolation, portability, and simplified updates, transforming the Raspberry Pi 5 into a robust and versatile home server. This document serves as a detailed blueprint for individuals planning a multi-service deployment, ensuring each application is configured for stability, performance, and long-term maintainability within a home network environment.

## Core System Preparation and Best Practices

Before deploying any services, establishing a solid foundation on the Raspberry Pi 5 is paramount. This involves selecting appropriate hardware, installing a compatible operating system, and configuring the Docker environment correctly. The recommended hardware configuration for a multi-service homelab begins with a Raspberry Pi 5 model equipped with at least 8GB of RAM to comfortably manage multiple concurrent Docker containers. While the device can function with 4GB, the higher memory ceiling provides crucial headroom for memory-intensive applications and database services. For storage, it is strongly advised to use an external Solid State Drive (SSD) connected via a USB 3.0 port as the primary storage for Docker volumes and application data. Relying solely on a microSD card for persistent data is discouraged due to its lower endurance and slower I/O performance, which can create bottlenecks and lead to premature failure under the constant read/write operations of a server. The microSD card should primarily be used to host the operating system itself. A stable power supply, specifically the official 27W (5V/5A) USB-C adapter, is non-negotiable to prevent system instability and data corruption caused by undervoltage, especially when the CPU is under load. Finally, an active cooler or a quality passive cooling case is essential to manage thermals and prevent CPU throttling during sustained workloads.

The choice of operating system is critical for ensuring ARM64 compatibility. The recommended choice is the official **Raspberry Pi OS (64-bit)**, based on Debian Bookworm. A 64-bit OS is a mandatory requirement, as the vast majority of modern Docker images for ARM are built for the `aarch64` (ARM64) architecture. Attempting to run these on a 32-bit OS will result in compatibility errors. Once the OS is installed and the system is updated, the next step is to install Docker Engine and the Docker Compose plugin. This can be accomplished using the official convenience script: `curl -sSL https://get.docker.com | sh`. After installation, it is crucial to add your user to the `docker` group with `sudo usermod -aG docker $USER` to allow management of Docker containers without requiring `sudo` for every command. For network stability, assigning a static IP address to the Raspberry Pi via your router's DHCP reservation settings is a fundamental best practice. This ensures that the services remain accessible at a consistent address on your local network, which is essential for inter-service communication and client access.

## Service Deployment Guides

### Caddy: Reverse Proxy with Automated SSL

Caddy is a powerful, modern reverse proxy that is particularly well-suited for a homelab environment due to its simple configuration and automatic HTTPS. In this deployment, Caddy serves as the single entry point for all web-based services, routing traffic to the appropriate container based on the hostname.

A primary goal of this setup is to use custom, memorable domain names (e.g., `movies.streetgeek.media`) for services that are kept private on the Tailscale network. This creates a significant challenge for standard SSL certificate issuance. The default method used by Let's Encrypt (the HTTP-01 challenge) requires the server to be accessible from the public internet, which is not the case here.

The solution is to use the **DNS-01 challenge**. This method proves domain ownership by having Caddy create a temporary DNS record using the DNS provider's API, rather than by serving a file over HTTP. This requires a DNS provider that offers API access, such as Cloudflare.

While it is possible to build a custom Caddy image with the required DNS plugin, this process can be fraught with build-time dependency issues. After significant troubleshooting, the most reliable and recommended solution is to use a community-maintained, pre-built Docker image that already includes the necessary plugins. For this deployment, we use **`ghcr.io/caddybuilds/caddy-cloudflare:latest`**. This image bypasses the need for a custom `Dockerfile` entirely.

The configuration in `docker-compose.yaml` specifies this image and passes the necessary Cloudflare API token as an environment variable (`CLOUDFLARE_API_TOKEN`). The `Caddyfile` is then configured with a global `tls` block that instructs Caddy to use the `cloudflare` DNS provider for all certificate operations. This setup provides robust, automated SSL for all private services using their custom domain names.

### n8n: Workflow Automation

n8n is a powerful, node-based workflow automation tool that serves as an open-source alternative to services like Zapier. For a Raspberry Pi 5 deployment, a model with at least 4GB of RAM is sufficient for light to medium workloads, though 8GB is preferable for more complex automations or when running alongside a dedicated database. Storage requirements start at a 32GB A2-class microSD card, but an SSD is highly recommended for performance and reliability of the Docker volume where workflow data is stored. The official `n8nio/n8n` Docker image is fully compatible with the ARM64 architecture, provided a 64-bit operating system is in use. While n8n defaults to an SQLite database, for enhanced scalability and performance, integrating a separate PostgreSQL container is a common practice. A basic Docker Compose configuration involves defining the n8n service, mapping port 5678, and creating a named volume for data persistence. Key environment variables include setting your timezone (`TZ`), enabling basic authentication for security (`N8N_BASIC_AUTH_ACTIVE`, `N8N_BASIC_AUTH_USER`, `N8N_BASIC_AUTH_PASSWORD`), and defining the host and protocol for proper operation within a local network.

### ActivityWatch: Automated Time Tracking

ActivityWatch is an open-source, privacy-first application for tracking time and activity on your devices. The server component, `aw-server`, is well-suited for containerization on a Raspberry Pi 4 or 5. A minimum of 2GB of RAM is recommended for the host system. The primary challenge with ARM64 deployment is the availability of a compatible Docker image. While official support can vary, community-maintained images such as `ephillipe/activitywatch-server-docker` have been reported to work on ARM64 platforms. It is important to note that only the server component should be run in Docker on the Pi; the "watcher" clients must be installed directly on the devices you wish to monitor. The deployment involves a simple Docker command or a Docker Compose file to run the `aw-server` container, mapping port 5600 for access to the web interface. For data persistence, a volume should be mounted to store the activity database, which is typically SQLite-based. Users should verify the specific image tag they pull from Docker Hub to ensure it includes a manifest for the `linux/arm64` architecture.

### Jellyfin: Media Server (with Critical Caveats)

Jellyfin is a popular open-source media system for managing and streaming movies, shows, music, and photos. While it is technically possible to run Jellyfin on a Raspberry Pi 5 using Docker, it comes with a significant and critical limitation: the **Raspberry Pi 5 lacks hardware acceleration for video transcoding**. The device's hardware does not include dedicated encoders and decoders for common codecs like H.264. Consequently, any transcoding task—such as changing resolution, burning in subtitles, or converting formats for client compatibility—must be performed by the CPU in software. This process is extremely CPU-intensive and will lead to severe performance issues, buffering, and playback failure, especially with high-resolution 4K content. Therefore, the Raspberry Pi 5 is **not recommended** for a Jellyfin setup if any form of transcoding is anticipated. It is only viable for scenarios where all media is in a format that all client devices can play directly (**Direct Play**). For a direct-play-only setup, a Docker Compose configuration can be used to run the official `jellyfin/jellyfin` image, mapping port 8096 for the web UI and mounting volumes for configuration and media libraries. Users proceeding with this setup must ensure their media library is pre-formatted for their clients to avoid any transcoding triggers.

### Calibre-web: E-Book Library Manager

Calibre-web is a web-based interface for browsing, reading, and downloading e-books stored in a Calibre database. It provides a clean and modern UI for accessing your e-book library from any device. For deployment on a Raspberry Pi, the multi-architecture image from LinuxServer.io (`lscr.io/linuxserver/calibre-web:latest`) is an excellent choice. The setup requires mapping a port for the web UI (e.g., 8083) and defining environment variables for user/group permissions (`PUID`/`PGID`) and your timezone. Two volumes are necessary: one for the application's configuration data and another pointing to the location of your Calibre e-book library.

### Kimai: Professional Time Tracking

Kimai is a flexible open-source time-tracking application designed for freelancers and businesses. It requires a relational database backend, with MySQL or MariaDB being the standard choices. For an ARM64 deployment on a Raspberry Pi 5, the `lscr.io/linuxserver/kimai:latest` Docker image is highly recommended as it is a multi-architecture image with excellent ARM64 support. The deployment is best managed with a Docker Compose file that defines two services: one for the Kimai application and another for a MariaDB database. The Kimai service depends on the database service to ensure a correct startup order. The most critical configuration element is the `DATABASE_URL` environment variable in the Kimai service definition. This connection string must be formatted correctly (`mysql://user:password@hostname:port/database_name`) and must point to the MariaDB container's service name (e.g., `db`). Persistent volumes must be created for both Kimai's configuration and the MariaDB data to prevent data loss upon container restarts.

### Actual Budget: Local-First Personal Finance

Actual Budget is a personal finance application focused on local-first data storage and envelope budgeting. It is exceptionally lightweight, making it an ideal candidate for a Raspberry Pi 5 homelab. The application is self-contained and does not require an external database. The official Docker images are multi-architecture, and for optimal performance on the resource-constrained environment of a Raspberry Pi, the `actualbudget/actual-server:latest-alpine` tag is recommended. The Alpine Linux base results in a smaller image size and lower resource footprint. Deployment is straightforward using a Docker Compose file that defines the service, maps port 5006 for the web interface, and mounts a single volume to a host directory (e.g., `/opt/homelab/actual-data`) to ensure all budget data is persisted securely. This simple setup provides a robust and private financial management tool with minimal system overhead.

### Firefly III: In-Depth Financial Management

Firefly III is a feature-rich personal finance manager that provides detailed insights into spending, saving, and budgeting. Its deployment requires a dedicated database backend. While it supports both MariaDB/MySQL and PostgreSQL, the official documentation and community experience strongly recommend using **PostgreSQL for ARM64 deployments**, including on the Raspberry Pi. This is due to reported stability and compatibility issues with MariaDB containers on certain ARM platforms. The official `fireflyiii/core` Docker image fully supports the `linux/arm64` architecture. A proper setup uses Docker Compose to orchestrate the Firefly III application container and a separate PostgreSQL container. Configuration is managed through environment files. A `.env` file is used for the main application settings (like `DB_CONNECTION=pgsql` and the `APP_KEY`), and a `.db.env` file is used to set credentials for the PostgreSQL database (`POSTGRES_USER`, `POSTGRES_PASSWORD`, etc.). It is critical that the database credentials match between these files and the service definitions in the `docker-compose.yml` file. Persistent volumes for both the application's upload directory and the PostgreSQL data directory are essential for data integrity.

### Forgejo: Self-Hosted Git Service

Forgejo is a lightweight, community-driven fork of Gitea, providing a self-hosted Git service similar to GitHub or GitLab. Its low resource usage makes it an excellent choice for the Raspberry Pi 5. The official `codeberg.org/forgejo/forgejo` image is multi-architecture, and using a pinned version tag (e.g., `7.0.1`) is recommended for stability. Deployment is managed with Docker Compose. The service requires a database backend, such as PostgreSQL, which can be run locally or on another machine. Key environment variables include `DB_TYPE`, `DB_HOST`, `DB_NAME`, and credentials. The `ROOT_URL` must be set to the public-facing URL (e.g., `https://git.deeplydigital.net/`), and `SSH_DOMAIN` and `SSH_PORT` must be configured to allow Git access over SSH. A critical part of the setup is mounting a volume for the repository data itself; using a NAS or other reliable external storage is highly recommended for this purpose (e.g., `/mnt/nas/repo:/data`). The service exposes a web port (e.g., 3000) for the UI, which is served by the Caddy reverse proxy, and an SSH port (e.g., 2222) for direct Git operations.

### Vaultwarden: Lightweight Password Management

Vaultwarden is an unofficial, lightweight, and resource-efficient Bitwarden server implementation written in Rust. Its minimal CPU and memory footprint make it one of the most popular and practical services to self-host on a Raspberry Pi 5. It is fully compatible with all official Bitwarden clients. The official `vaultwarden/server:latest` Docker image is multi-architecture and runs flawlessly on ARM64. The application uses an internal SQLite database by default, simplifying the setup as no external database container is required. A Docker Compose configuration should be used to define the service, map a port for the web vault (e.g., 8080), and mount a volume for persistent data storage. For enhanced security and functionality, it is highly recommended to enable WebSockets (`WEBSOCKET_ENABLED=true`). After the initial setup, it is critical to disable new user sign-ups (`SIGNUPS_ALLOWED=false`) and set a secure `ADMIN_TOKEN` via environment variables to access the administrative interface and manage users. For secure remote access, Vaultwarden is often deployed behind a reverse proxy like Caddy or Nginx Proxy Manager, which can handle SSL certificate management automatically.

### LanguageTool: Private Grammar and Style Checker

LanguageTool is an open-source proofreading software that can be self-hosted to provide a private alternative to cloud-based services like Grammarly. The application is Java-based and requires a 64-bit Java Virtual Machine (JVM), making a 64-bit OS on the Raspberry Pi mandatory. While there is no official Docker image, the community-maintained `erikvl87/languagetool` image provides excellent multi-architecture support, including ARM64. A Raspberry Pi 5 with at least 2GB of RAM is recommended, though performance can be improved with more. The Docker Compose setup is simple, requiring only the service definition and mapping port 8010. For users seeking higher accuracy, LanguageTool can utilize n-gram data, which can consume up to 10GB of additional storage. To use this feature, the n-gram data must be downloaded separately and mounted into the container as a read-only volume. Performance can be tuned by setting Java heap size limits via environment variables, such as `Java_Xms` (initial heap size) and `Java_Xmx` (maximum heap size), to prevent the application from consuming excessive memory.

### Vale: Command-Line Prose Linter

Vale is a powerful, syntax-aware linter for prose that helps enforce a consistent writing style. Unlike most services in this guide, Vale is not a long-running web server but a command-line tool. It is built in Go, making it extremely fast and lightweight, with native ARM64 support. Docker provides an excellent way to run Vale without installing it directly on the host system. Official or community-maintained images like `ghcr.io/vshn/vale:latest` can be used. To use it, you execute a `docker run` command that mounts your project directory (containing the documents to be linted) and your Vale configuration file (`.vale.ini`) into the container. The command then invokes Vale to analyze the files and prints the output to the console. This workflow is particularly effective for integrating automated prose checking into CI/CD pipelines or for local development, ensuring documentation and other written materials adhere to predefined style guides.

### Convex: Reactive Backend Platform

Convex is an open-source backend platform that provides a reactive database and serverless functions, designed to simplify web application development. Self-hosting Convex on a Raspberry Pi 5 is an advanced and somewhat experimental endeavor. The platform is primarily tested on x86 Linux and macOS, and while ARM64 support is possible, it is not officially guaranteed. Users may need to rely on unofficial or community-built multi-architecture Docker images, as the official build process can be resource-intensive. A Raspberry Pi 5 with 8GB of RAM is strongly recommended for this workload. The self-hosted version uses SQLite by default but can be configured to connect to an external PostgreSQL or MySQL database for production use. The Docker Compose setup involves running the `convex-backend` container and configuring several environment variables, including `CONVEX_CLOUD_ORIGIN` and `CONVEX_SITE_ORIGIN` to define the accessible URLs. Users attempting this deployment should be comfortable with potential troubleshooting and be aware that they are operating on a less-tested platform.

### Docmost: Collaborative Documentation Wiki

Docmost is a modern, open-source wiki and documentation platform featuring real-time collaboration. Its architecture relies on several components, making Docker Compose the ideal deployment method. The core dependencies include a PostgreSQL database for storing content and a Redis instance for caching and managing real-time events. The official `docmost/docmost` Docker image is expected to be multi-architecture, but if compatibility issues arise on ARM64, building the image from source using Docker Buildx is a viable alternative. The Docker Compose file must define three services: `docmost`, `postgres`, and `redis`. Persistent volumes are required for the PostgreSQL data and Docmost's storage directory. Critical environment variables for the Docmost service include the `APP_URL` (the public-facing URL of the instance), a securely generated `APP_SECRET`, and the connection URLs for the database (`DATABASE_URL`) and Redis (`REDIS_URL`). For real-time collaboration to function correctly, any reverse proxy placed in front of Docmost must be configured to properly handle WebSocket connections.

### Plane: Open-Source Project Management

Plane is a comprehensive open-source project management tool, offering an alternative to platforms like Jira and Asana. The developers of Plane provide excellent support for self-hosting and explicitly list ARM64 as a compatible architecture. The minimum system requirements are 2 vCPUs and 4GB of RAM, with 8GB being recommended for smoother performance, making the Raspberry Pi 5 a suitable host. The official deployment method utilizes Docker Compose. Plane provides an express installation script that automates the process of downloading the correct `docker-compose.yml` and `.env` files and initializing the services. This stack includes the Plane web application, a database, and other necessary components. This streamlined setup process makes it one of the more accessible complex applications to deploy on a Raspberry Pi, as it abstracts away much of the manual configuration.

### NocoDB: No-Code Database Platform

NocoDB transforms existing databases (like MySQL, PostgreSQL, or SQLite) into a smart spreadsheet and no-code application platform, similar to Airtable. A significant consideration for deployment on a Raspberry Pi is that the official `nocodb/nocodb` Docker image **does not support the ARM64 architecture**. This is a critical limitation that requires a workaround. Fortunately, the community has provided a solution with a multi-architecture image available at `azrikahar/nocodb:latest`. This community-maintained image enables NocoDB to run successfully on ARM64 devices. The deployment should be managed via Docker Compose, using this specific image. A persistent volume must be mounted to `/usr/app/data/` inside the container to store the application's metadata and the default SQLite database. For more robust deployments, NocoDB can be configured via environment variables to connect to an external PostgreSQL or MariaDB database container.

### Paperless-ngx: Digital Document Management

Paperless-ngx is a highly regarded open-source document management system that digitizes paper documents using Optical Character Recognition (OCR). The official Docker images are multi-architecture and fully support ARM64, making it a perfect fit for the Raspberry Pi 5. The Pi 5's improved processing power is particularly beneficial for the OCR process, which can be CPU-intensive. A minimum of 4GB of RAM is recommended. The application stack consists of the main web server, a Redis message broker, and a PostgreSQL database, all managed via Docker Compose. The recommended installation method involves using an official interactive script that helps generate the `docker-compose.yml` and `.env` files. Key configuration options set via environment variables include the timezone (`PAPERLESS_TIME_ZONE`) and the default OCR language (`PAPERLESS_OCR_LANGUAGE`), with support for adding multiple languages. Persistent volumes for the consumption directory, media, data, and database are essential for a functional and durable setup.

## Conclusion and Further Considerations

The Raspberry Pi 5, when paired with Docker, stands as a formidable platform for building a versatile and energy-efficient homelab. This guide has detailed the deployment of a diverse suite of over a dozen services, from workflow automation and password management to document archiving and project planning. The key to a successful multi-service deployment lies in careful planning around ARM64 compatibility, diligent management of persistent storage on a reliable medium like an SSD, and a clear understanding of each application's database and resource requirements. While this report provides the technical foundation, the journey continues with networking, security, and maintenance. Implementing a reverse proxy, such as Nginx Proxy Manager or Caddy, is a logical next step to centralize access to services and automate SSL certificate management. Furthermore, establishing a robust, automated backup strategy for all Docker volumes is not just recommended; it is essential for protecting your valuable data. This powerful single-board computer offers a gateway to digital self-sufficiency, empowering users to take control of their data and services in a private, customizable, and sustainable manner.

## References

[How to run n8n on a Raspberry Pi 5 - CyberSecLabs](https://www.cyberseclabs.org/how-to-run-n8n-on-a-raspberry-pi-5/)
[Run n8n Docker Image above 1.26.0 on RaspberryPi - n8n community](https://community.n8n.io/t/run-n8n-docker-image-above-1-26-0-on-raspberrypi/43318)
[How to setup n8n on a Raspberry Pi 5 (local setup) - n8n community](https://community.n8n.io/t/how-to-setup-n8n-on-a-raspberry-pi-5-local-setup/120609)
[Docker - n8n Docs](https://docs.n8n.io/hosting/installation/docker/)
[Docker Compose - n8n Docs](https://docs.n8n.io/hosting/installation/server-setups/docker-compose/)
[How to Install n8n on Raspberry Pi - mathias.rocks](https://mathias.rocks/blog/2024-09-19-how-to-install-n8n-on-raspberry-pi)
[Self-hosting n8n on a Raspberry Pi 5 with Docker, PostgreSQL, and Cloudflared - Bhashit Parikh](https://bhashit.in/?p=224)
[Raspberry Pi Docker n8n - Cytron](https://my.cytron.io/tutorial/rpi-docker-n8n)
[Installation steps for the latest Raspberry Pi OS 64-bit - Docker Forums](https://forums.docker.com/t/installation-steps-for-the-latest-raspberry-pi-os-64-bit/138838)
[Docker on Raspberry Pi - Raspberry Tips](https://raspberrytips.com/docker-on-raspberry-pi/)
[Cross-architecture Docker deployment from x86-64 to amd64 on Raspberry Pi - Medium](https://tobibot.medium.com/cross-architecture-docker-deployment-from-x86-64-to-amd64-on-raspberry-pi-1e097e43b644)
[ephillipe/activitywatch-server-docker - Docker Hub](https://hub.docker.com/r/ephillipe/activitywatch-server-docker)
[Install Docker Engine on Raspberry Pi OS - Docker Docs](https://docs.docker.com/engine/install/raspberry-pi-os/)
[ARM64 Raspberry Pi FAQ - Auvik Support](https://support.auvik.com/hc/en-us/articles/28775790530964-ARM64-Raspberry-Pi-FAQ)
[Dockerize aw-server? · Issue #166 · ActivityWatch/activitywatch - GitHub](https://github.com/ActivityWatch/activitywatch/issues/166)
[Installing Docker on Raspberry Pi: A Step-by-Step Guide - Raspberry Pi Box](https://www.raspberrypibox.com/installing-docker-on-raspberry-pi-a-step-by-step-guide/)
[Hardware Acceleration - Jellyfin Docs](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/)
[Raspberry Pi for hosting - Jellyfin Forum](https://forum.jellyfin.org/t-raspberry-pi-for-hosting)
[Hardware Selection - Jellyfin Docs](https://jellyfin.org/docs/general/administration/hardware-selection/)
[Setup Jellyfin with Hardware Acceleration on Orange Pi 5 (Rockchip RK3558) - Akash Rajpurohit](https://akashrajpurohit.com/blog/setup-jellyfin-with-hardware-acceleration-on-orange-pi-5-rockchip-rk3558/)
[Jellyfin Docker Hardware Acceleration - Armbian community forums](https://forum.armbian.com/topic/29742-jellyfin-docker-hardware-acceleration/)
[Raspberry Pi 5 Jellyfin on Docker lags when transcoding - Reddit](https://www.reddit.com/r/selfhosted/comments/1h2o4zi/raspberry_pi_5_jellyfin_on_docker_lags_when/)
[Setup Jellyfin with Hardware Acceleration on Orange Pi 5 - Reddit](https://www.reddit.com/r/selfhosted/comments/1do6b7x/setup_jellyfin_with_hardware_acceleration_on/)
[Setup Jellyfin with Hardware Acceleration on Orange Pi 5 - Reddit](https://www.reddit.com/r/OrangePI/comments/1do7dpa/setup_jellyfin_with_hardware_acceleration_on/)
[Docker - Kimai](https://www.kimai.org/documentation/docker.html)
[Docker-Compose - Kimai](https://www.kimai.org/documentation/docker-compose.html)
[How to setup Kimai2 Timetracking locally or on your server with Docker-Compose - Medium](https://medium.com/geekculture/how-to-setup-kimai2-timetracking-locally-or-on-your-server-with-docker-compose-1287d9bc3722)
[Kimai - Awesome Docker Compose](https://awesome-docker-compose.com/apps/time-tracking/kimai)
[kimai/kimai2 - Docker Hub](https://hub.docker.com/r/kimai/kimai2)
[L/D Series: Kimai, the Freelancer's Time Management - Medium](https://mpermperpisang.medium.com/l-d-series-kimai-the-freelancers-time-management-a88ab3a26a97)
[Kimai - LinuxServer.io](https://docs.linuxserver.io/images/docker-kimai/)
[Kimai with Traefik and Docker - JKLUG's Blog](https://blog.jklug.work/posts/kimai/)
[Docker - Actual Budget](https://actualbudget.org/docs/install/docker/)
[Installation - Actual Budget](https://actualbudget.org/docs/install/)
[actual-server - GitHub](https://github.com/actualbudget/actual-server)
[Actual Budget - Awesome Docker Compose](https://awesome-docker-compose.com/apps/budgeting/actual-budget)
[ActualBudget - A Self-Hosted Personal Finance Manager - VHBelvadi](https://vhbelvadi.com/actualbudget)
[Docker - Firefly III documentation](https://docs.firefly-iii.org/how-to/firefly-iii/installation/docker/)
[Docker FAQ - Firefly III documentation](https://docs.firefly-iii.org/references/faq/docker/)
[Manage your Finance with Firefly III and Raspberry Pi - peppe8o](https://peppe8o.com/manage-your-finance-with-firefly-iii-and-raspberry-pi/)
[Self-Hosted Finance Management: Setting up Firefly III with Docker - LinuxConfig.org](https://linuxconfig.org/self-hosted-finance-management-setting-up-firefly-iii-with-docker)
[Running Firefly III Personal Finance Manager in Docker - i12bretro](https://i12bretro.wordpress.com/2023/03/11/running-firefly-iii-personal-finance-manager-in-docker/)
[Installing Firefly III with Docker and Portainer - Bits and Bytes](https://bitsandbytes.digital/2025/06/04/installing-firefly-docker-portainer/)
[nicxx2/fireflyiii-quickstart - Docker Hub](https://hub.docker.com/r/nicxx2/fireflyiii-quickstart)
[Struggling to install Firefly3 on Raspberry Pi 4 - Reddit](https://www.reddit.com/r/selfhosted/comments/18427rz/struggling_to_install_firefly3_on_raspberry_pi_4/)
[Self-Host Vaultwarden on a Raspberry Pi - Pi My Life Up](https://pimylifeup.com/vaultwarden-docker/)
[Self-Host Bitwarden on a Raspberry Pi - Pi My Life Up](https://pimylifeup.com/raspberry-pi-bitwarden/)
[Self-hosting Vaultwarden on a Raspberry Pi - Reinhard's Blog](https://blog.reinhard.codes/2021/04/19/self-hosting-vaultwarden-on-a-raspberry-pi/)
[How to Install Bitwarden on Raspberry Pi - Raspberry Tips](https://raspberrytips.com/install-bitwarden-on-raspberry-pi/)
[New installation help - Raspberry Pi 4 with docker-compose - Vaultwarden Discourse](https://vaultwarden.discourse.group/t/new-installation-help-raspberry-pi-4-with-docker-compose/2285)
[Install and Deploy - On-premise - Bitwarden Help Center](https://bitwarden.com/help/article/install-on-premise/)
[Self-Host Bitwarden in Raspberry Pi 4 - The Engineering Projects](https://www.theengineeringprojects.com/2022/09/self-host-bitwarden-in-raspberry-pi-4.html)
[JulianRunnels/Vaultwarden_Self_Host - GitHub](https://github.com/JulianRunnels/Vaultwarden_Self_Host)
[Run Your Own Private Grammarly Clone Using Docker and LanguageTool - How-To Geek](https://www.howtogeek.com/run-your-own-private-grammarly-clone-using-docker-and-languagetool/)
[languagetool-org/languagetool - GitHub](https://github.com/languagetool-org/languagetool)
[A Dockerised LanguageTool - Handtyped](https://handtyped.net/posts/2023/dockerised-languagetool/)
[erikvl87/languagetool - Docker Hub](https://hub.docker.com/r/erikvl87/languagetool)
[Erikvl87/docker-languagetool - GitHub](https://github.com/Erikvl87/docker-languagetool)
[Anyone selfhosting languagetool? - Reddit](https://www.reddit.com/r/selfhosted/comments/ksvmii/anyone_selfhosting_languagetool/)
[ARM64 build · Issue #15 · Erikvl87/docker-languagetool - GitHub](https://github.com/Erikvl87/docker-languagetool/issues/15)
[Lint prose - Grafana Writers' Toolkit](https://grafana.com/docs/writers-toolkit/review/lint-prose/)
[errata-ai/vale - GitHub](https://github.com/errata-ai/vale)
[Vale.sh - A command-line tool that brings code-like linting to prose](https://vale.sh/)
[Vale - MegaLinter](https://megalinter.io/beta/descriptors/spell_vale/)
[Docker build for arm64 fails · Issue #572 · dotenv-linter/dotenv-linter - GitHub](https://github.com/dotenv-linter/dotenv-linter/issues/572)
[Hadolint: A Smarter Dockerfile Linter - InfoQ](https://www.infoq.com/news/2022/04/hadolint-dockerfile-linter/)
[Setting up Vale prose linter on Emacs - Emacs TIL](https://emacstil.com/til/2022/03/05/setting-up-vale-prose-linter-on-emacs/)
[vshn/vale - GitHub](https://github.com/vshn/vale)
[get-convex/convex-backend - GitHub](https://github.com/get-convex/convex-backend)
[Self-hosted: Develop and Deploy - Convex Stack](https://stack.convex.dev/self-hosted-develop-and-deploy)
[patte/convex-backend-docker - GitHub](https://github.com/patte/convex-backend-docker)
[Build with Docker - Docker Docs](https://docs.docker.com/build/building/multi-platform/)
[convex-backend/self-hosted/README.md - GitHub](https://github.com/get-convex/convex-backend/blob/main/self-hosted/README.md)
[Convex | The fullstack platform for web developers](https://www.convex.dev/)
[ARM64 Support - LocalStack](https://docs.localstack.cloud/references/arm64-support/)
[Installation - Docmost](https://docmost.com/docs/installation/)
[Build with Docker - Docker Docs](https://docs.docker.com/build/building/multi-platform/)
[Docmost - The Open Source & Self-Hosted Wiki](https://docmost.com/)
[Docmost: Open-source Self-hosted Knowledge-base and Wiki for Teams - Medevel.com](https://medevel.com/docmost-app/)
[Self-hosting - Docmost](https://docmost.com/docs/category/self-hosting/)
[Docker Compose - Plane](https://developers.plane.so/self-hosting/methods/docker-compose)
[Plane - The open-source project management tool.](https://plane.so/)
[We've been super consistent and are improving our self-hosting experience with every release. - Reddit](https://www.reddit.com/r/selfhosted/comments/1cskhks/weve_been_super_consistent_and_are_improving_our/)
[makeplane/plane-space - Docker Hub](https://hub.docker.com/r/makeplane/plane-space)
[Install Docker Compose - Docker Docs](https://docs.docker.com/compose/install/)
[Project Management Web Platform with Redmine on Raspberry Pi and Docker - peppe8o](https://peppe8o.com/project-management-web-platform-with-redmine-on-raspberry-pi-and-docker/)
[ubudev1397/RPi_Docker-Compose_SetUp - GitHub](https://github.com/ubudev1397/RPi_Docker-Compose_SetUp)
[Installation - NocoDB](https://docs.nocodb.com/0.109.7/getting-started/installation/)
[Docker image for arm64 · Issue #183 · nocodb/nocodb - GitHub](https://github.com/nocodb/nocodb/issues/183)
[nocodb/nocodb - GitHub](https://github.com/nocodb/nocodb)
[Other Installations - NocoDB](https://nocodb.com/docs/self-hosting/installation/other-installations)
[How to install the NocoDB no-code database application with Docker - TechRepublic](https://www.techrepublic.com/article/nocodb-no-code-detabase-application/)
[Docker - NocoDB](https://nocodb.com/docs/self-hosting/installation/docker)
[NocoDB - need help with installation on VPS - Reddit](https://www.reddit.com/r/selfhosted/comments/13wqruj/nocodb_need_help_with_installation_on_vps/)
[nocodb/nocodb-1 - GitHub](https://github.com/nocodb/nocodb-1)
[Frequently Asked Questions - Paperless-ngx](https://docs.paperless-ngx.com/faq/)
[Setup - Paperless-ngx](https://docs.paperless-ngx.com/setup/)
[Create a Paperless Office with a Raspberry Pi - PiCockpit](https://picockpit.com/raspberry-pi/create-a-paperless-office-with-a-raspberry-pi/)
[paperless-ngx/paperless-ngx - GitHub](https://github.com/paperless-ngx/paperless-ngx)
[Paperless-ngx - Deployn](https://deployn.de/en/guides/paperless-ngx/)
[How to Set up Paperless on the Raspberry Pi - Pi My Life Up](https://pimylifeup.com/raspberry-pi-paperless/)
[How to Set up Paperless-ngx with Docker - Pi My Life Up](https://pimylifeup.com/paperless-ngx-docker/)
[Paperless-ngx on Raspberry Pi, am I missing something? - Reddit](https://www.reddit.com/r/selfhosted/comments/1cu11tz/paperlessngx_on_raspberry_pi_am_i_missing/)