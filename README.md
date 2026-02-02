# Substrate_Compute

This repository defines a governed Azure VM substrate intended for repeatable, low-cost compute nodes that can be safely extended with application layers (e.g. OpenClaw) without compromising base integrity.

The design prioritises:
- Determinism
- Auditability
- Low operational cost
- Clear separation between infrastructure substrate and application logic

---

## Reference VM: vm-Substrate-Compute-Base

**vm-Substrate-Compute-Base** is the canonical golden base VM defined by this repository.

It is designed to be:
- Low-cost and resource-conscious (e.g. Azure B1s / B2s)
- Ubuntu 22.04 LTS
- Tuned explicitly for low-memory environments
- Rebuilt periodically and captured as a versioned image
- Never used directly for application workloads

This VM exists to be **built → tuned → captured → destroyed**.

All application workloads are deployed from its captured image.

---

## Scope

This repository defines:
- Core Azure infrastructure (VM, disks, network, NSG)
- A clean, reproducible base operating system
- Image lifecycle and governance contract

This repository does **not** define:
- Application logic
- Agent behaviour
- Long-running business processes

Those belong in downstream layers.

---

## Intended Usage

1. Deploy **vm-Substrate-Compute-Base** from the Ubuntu marketplace image.
2. Apply low-end tuning and generic tooling.
3. Capture the VM as an image.
4. Deploy application VMs from that image.
5. Periodically rebuild the base image to refresh patches and tooling.

This pattern prevents snowflake VMs and enables controlled evolution.
