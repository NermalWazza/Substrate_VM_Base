# Architecture

This document describes the infrastructure architecture for the Substrate_Compute repository.

The design separates:
- A minimal, governed infrastructure substrate
- Application and agent layers built on top of that substrate

---

## Infrastructure Substrate

The substrate consists of:

- Azure Virtual Machine
- Ubuntu Server 22.04 LTS
- Disposable OS disk
- Persistent data disk (mounted at `/data`)
- Network Security Group allowing SSH only
- No application logic baked into the base image

The substrate is intentionally minimal.

---

## VM Variants

### vm-Substrate-Compute-Base

The **vm-Substrate-Compute-Base** VM is the authoritative base for all derived compute nodes.

Characteristics:
- Deployed from the Ubuntu 22.04 LTS marketplace image
- Sized for low-end operation (B1s / B2s)
- Tuned for constrained environments:
  - Swapfile (2–4 GB)
  - Reduced swappiness
  - Capped journald logs
  - Unnecessary services disabled
- Generic tooling only:
  - git, curl, wget
  - build-essential
  - htop, tmux
  - Node.js installed via nvm (no global npm installs)

This VM is **not** an application host.

Once validated, it is deprovisioned and captured as an image.

---

### Derived Application VMs

Examples:
- vm-substrate-compute-openclaw-ops-01
- vm-substrate-compute-dev-01

Characteristics:
- Deployed from the vm-Substrate-Compute-Base image
- Application installed via bootstrap scripts or cloud-init
- systemd used for PID and service management
- Additional ports opened only as required
- Safe to destroy and recreate

---

## Image Lifecycle

1. Deploy **vm-Substrate-Compute-Base** using the Ubuntu marketplace image.
2. Apply base tuning and generic tooling.
3. Clean the system (logs, caches, temp files).
4. Deprovision the VM (`waagent -deprovision+user`).
5. Capture the VM as:
   - A managed image, or
   - A Shared Image Gallery version.
6. Update infrastructure code to reference the new image.
7. Destroy the build VM.

This lifecycle is repeated periodically to refresh patches and base dependencies.

---

## Design Contract

- vm-Substrate-Compute-Base:
  - Is never an application host
  - Is disposable after image capture
  - Exists solely to define a clean substrate

- All intelligence, agents, and workloads live above the base layer.

This contract is enforced by design, not convention.
