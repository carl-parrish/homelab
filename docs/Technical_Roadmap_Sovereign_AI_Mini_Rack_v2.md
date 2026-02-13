### **Technical Roadmap: The Sovereign AI Mini-Rack**

#### **Project Vision**
To develop a high-performance, energy-independent, and **Sovereign Local-First** digital infrastructure. This "Sovereign Stack" utilizes an immutable **Talos Linux** control plane, a high-speed **10GbE SFP+** interconnect, and **Automerge/libSQL** state management to provide private AI inference and automated data governance without cloud dependency.

#### **Milestone 1: The Sovereign Foundation & Identity (Months 1-2)**
*   **Objective:** Establish the "Zero-Trust" hardware root of trust and reproducible bootstrap.
*   **Key Work:**
    *   **Identity & Access:** Implementing **Teleport** as the unified access plane for the cluster, anchored by **YubiKey** hardware MFA to eliminate static SSH keys and centralized identity providers.
    *   **Bootstrap:** Finalizing the immutable **Talos Linux** configuration and `chezmoi`/`mise` templates for a 1-click, distro-agnostic deployment.
    *   **Secrets:** Implementing **Infisical** for centralized, audited secret injection across the ARM64/x86 hybrid cluster.
*   **Deliverable:** Public GitHub repository containing the `chezmoi` templates, Talos machine configs, and a security whitepaper on "Hardware-Backed Sovereign Identity via YubiKey and Teleport."

#### **Milestone 2: Local-First Data Fabric & Solar-Awareness (Months 3-4)**
*   **Objective:** Implement the **Automerge/libSQL** state layer and energy-aware scaling for off-grid resilience.
*   **Key Work:**
    *   **Data Fabric:** Implementing **Automerge (Rust)** with **Go/Gin** wrappers to handle conflict-free state sync, persisted via **libSQL** (SQLite-based) for high-performance local querying.
    *   **Storage:** Configuring **TrueNAS Scale** on the **LincStation N2** to provide ZFS-protected NFS shares for the cluster.
    *   **Scale-to-Zero:** Deploying **KEDA** to scale resource-heavy pods (LLMs, OCR) to zero based on real-time **Sodium-ion** battery telemetry.
*   **Deliverable:** A Go/Rust reference implementation of a local-first document store and a KEDA configuration set optimized for solar-harvest cycles.

#### **Milestone 3: 10GbE Backplane & Private AI (Months 4-5)**
*   **Objective:** Integrate high-compute nodes and long-range mesh connectivity.
*   **Key Work:**
    *   **Networking:** Configuring the **BPI-R4 (SFP+)** and **MikroTik** backplane to support 10Gbps data paths between the NAS and the **Framework Desktop** GPU.
    *   **RF Mesh:** Integrating **Morse Micro MM8108 (Wi-Fi HaLow)** for low-power, long-range (1km+) connectivity in maritime/rural environments.
    *   **Private RAG:** Deploying a **Local LLM (70B+)** for private Retrieval-Augmented Generation over the ZFS-resident document store.
*   **Deliverable:** Performance benchmarks for "10GbE Local-First AI Data Paths" and a functional Wi-Fi HaLow mesh prototype.

#### **Milestone 4: Turnkey Physical Spec & Release (Month 6)**
*   **Objective:** Release the physical blueprints and automated installer for the turnkey "Sovereign Unit."
*   **Key Work:**
    *   **Physical Design:** Finalizing **3D-printed enclosure designs** for the 3x CM5 + Framework + LincStation rack.
    *   **Backup:** Implementing **Kopia** for encrypted, deduplicated snapshots from the cluster to the TrueNAS ZFS core.
    *   **Installer:** Creating a "Mobile-Ready" installer that handles network handovers and automated Talos node joining.
*   **Deliverable:** A comprehensive "Sovereign Build Guide" including STL files, a full Bill of Materials (BOM), and the automated deployment script for the entire hardware stack.
