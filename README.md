This repository contains a VHDL-based ASIC design for a domain-specific System-on-Chip (SoC). It integrates a RISC-V CPU with a dedicated audio DSP coprocessor designed to process raw audio signals, execute hardware-accelerated filtering, and extract features for word recognition (Keyword Spotting). Built as a personal exploration into open-source ASIC design workflows.

## ASIC Implementation & Physical Signoff (SkyWater 130nm)

The `audio_dsp_apb_wrapper` IP has been fully synthesized, timing-verified, and hardened as a standalone **Hard Macro** targeting the **SkyWater 130nm HD** (`sky130_fd_sc_hd`) process node using **Yosys**, **OpenSTA**, and **LibreLane (OpenLANE v2)**.

---

### 1. Logic Synthesis & Silicon Area (Yosys)

* **Total Hard Macro Area:** $53,897.94 \ \mu\text{m}^2$ ($\approx 0.0539 \ \text{mm}^2$)
* **Total Gate Count:** 6,059 standard cells
* **Sequential Logic:** 268 D-Flip-Flops ($6,706.43 \ \mu\text{m}^2$, $12.44\%$ of total area)

#### Hierarchical Area Budget

| Module | Silicon Area ($\mu\text{m}^2$) | Area Share (%) | Description |
| :--- | :--- | :--- | :--- |
| `fir_filter` | $46,131.74$ | 85.59% | 4-Tap Q1.15 Fixed-Point MAC Engine |
| `audio_dsp_coprocessor` | $5,063.61$ | 9.40% | Coefficient & Control MMIO Registers |
| `audio_dsp_apb_wrapper` | $2,702.59$ | 5.01% | AMBA APB3 State Machine & Bus Interface |

---

### 2. Static Timing Analysis - STA (OpenSTA)

Timing signoff executed at typical operating corner ($25^\circ\text{C}$, $1.80\text{V}$):

| Clock Domain | Target Frequency | Min. Period ($T_{MIN}$) | Max. Frequency ($f_{MAX}$) | Worst Setup Slack | Hold Slack | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`pclk` (AMBA APB)** | $100.0 \ \text{MHz}$ ($10.0 \ \text{ns}$) | $4.510 \ \text{ns}$ | **$221.73 \ \text{MHz}$** | $+5.490 \ \text{ns}$ | $+0.433 \ \text{ns}$ | **MET** |
| **`clk_audio_i`** | $48.0 \ \text{kHz}$ ($20,833 \ \text{ns}$) | $< 0.010 \ \text{ns}$ | $\infty$ | $+19,825.32 \ \text{ns}$ | $+0.695 \ \text{ns}$ | **MET** |

---

### 3. Place & Route and Physical Signoff (LibreLane / OpenLANE v2)

The design was hardened as an internal IP Macro (`DESIGN_IS_CORE: false`) ready for top-level SoC integration.

* **Core Utilization:** $55\%$
* **Target Placement Density:** $60\%$
* **Physical Verification Checks:**
  * **DRC (Design Rule Checking):** PASSED (0 violations) 
  * **LVS (Layout Versus Schematic):** PASSED (0 errors) 
  * **Antenna Checks:** PASSED 
* **Generated Hard IP Deliverables:**
  * `final/gds/audio_dsp_apb_wrapper.gds` — GDSII Physical Layout
  * `final/lef/audio_dsp_apb_wrapper.lef` — Abstract LEF for Top-Level Integration
  * `final/verilog/gl/audio_dsp_apb_wrapper.v` — Post-PnR Gate-Level Netlist
  * `final/spef/audio_dsp_apb_wrapper.spef` — Extracted Parasitics
  * `final/lib/audio_dsp_apb_wrapper.lib` — Characterized Timing Model