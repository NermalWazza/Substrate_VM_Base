# Substrate_Compute

This repository defines a governed Azure VM substrate intended for repeatable, low-cost compute nodes that can be safely extended with application layers (e.g. OpenClaw) without compromising base integrity.

---

## Reference VM: vm-Substrate-Compute-Base

**vm-Substrate-Compute-Base** is the canonical golden base VM for this repository.

It is designed to be:
- Low-cost and resource-conscious (e.g. Azure B1s / B2s)
- Ubuntu 22.04 LTS
- Tuned explicitly for low-memory environments
- Rebuilt periodically and captured as a versioned image
- Never used directly for application workloads

This VM exists to be **built → tuned → captured → destroyed**.

All application workloads are deployed from its captured image.

---

## Architecture Overview

### Infrastructure Substrate

- Azure Virtual Machine
- Ubuntu Server 22.04 LTS
- Disposable OS disk
- Persistent data disk (mounted at `/data`)
- NSG restricted to SSH (source IP parameterised)
- No application logic baked into the base image

### VM Variants

#### vm-Substrate-Compute-Base
- Deployed from the Ubuntu marketplace image
- Tuned for low-end hardware:
  - Swapfile configured (2–4 GB)
  - Reduced swappiness
  - Journald/log rotation caps
  - Unnecessary services disabled
- Generic tooling installed only:
  - git, curl, wget
  - build-essential
  - htop, tmux
  - Node.js via nvm (no global npm installs)
- Deprovisioned and captured as a managed image or SIG image

#### Derived Application VMs
Examples:
- vm-substrate-compute-openclaw-ops-01
- vm-substrate-compute-dev-01

Characteristics:
- Deployed **from the vm-Substrate-Compute-Base image**
- Application installed via bootstrap scripts or cloud-init
- Use systemd for PID/service management
- May expose additional ports as required
- Can be safely destroyed and recreated

---

## Image Lifecycle

1. Deploy **vm-Substrate-Compute-Base** from the Ubuntu 22.04 LTS marketplace image using this template.
2. Apply low-end tuning:
   - OS updates
   - Swapfile creation and tuning
   - Service trimming
   - Basic hardening and observability tooling
3. Clean the VM:
   - Remove temp files and logs
   - Ensure no secrets or personal SSH keys remain
4. Deprovision the VM (`waagent -deprovision+user`)
5. Capture the VM as:
   - A managed image, or
   - A Shared Image Gallery version
6. Update IaC to reference the new image ID
7. Destroy the build VM

This process is repeated periodically to refresh patches and base tooling.

---

## Bicep Design Contract

The Bicep template supports two modes:

- **Base build mode**
  - `sourceImageId` left empty
  - Ubuntu marketplace image used
  - Produces vm-Substrate-Compute-Base

- **Application mode**
  - `sourceImageId` provided
  - VM created from the captured base image
  - Application bootstrap applied

### Required Parameters (conceptual)

- `vmName`
- `vmSize` (default: Standard_B2s)
- `sourceImageId` (optional)
- `sshSourceAddressPrefix`

This keeps infrastructure deterministic and prevents snowflake VMs.

---

## Application Layer: OpenClaw (Out of Scope for Base)

OpenClaw is treated as a **first-class application layer**, not part of the base substrate.

Responsibilities of the application layer:
- Install OpenClaw and dependencies
- Register systemd services
- Manage its own processes and logs
- Observe host health and resource usage
- Interact with IaC, GitHub Actions, and future DAO workflows

OpenClaw is installed only on VMs derived from the **vm-Substrate-Compute-Base** image.

---

## Naming Conventions

### Base Build
- Resource Group: `rg-substrate-compute-base`
- Build VM: `vm-substrate-compute-base-build`
- Image: `img-substrate-compute-base`

### Derived VMs
- `vm-substrate-compute-openclaw-ops-01`
- `vm-substrate-compute-openclaw-dev-01`

---

## Design Contract (Non-Negotiable)

- vm-Substrate-Compute-Base:
  - Is never an application host
  - Is disposable after image capture
  - Exists solely to define a clean substrate

- All intelligence, agents, and workloads live **above** the base.

This preserves auditability, reversibility, and long-term maintainability.
