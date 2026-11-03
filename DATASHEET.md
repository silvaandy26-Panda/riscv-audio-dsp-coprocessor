# IP Datasheet: audio_dsp_apb_wrapper

4-Tap Q1.15 Fixed-Point FIR Filter IP Macro with AMBA APB3 Target Interface.

---

## 1. Key Specifications

| Parameter | Value | Unit | Notes |
| :--- | :--- | :--- | :--- |
| **Process Node** | SkyWater 130nm HD (`sky130_fd_sc_hd`) | — | Single 1.8V Core Supply |
| **Macro Area** | $53,897.94 \ \mu\text{m}^2$ ($0.0539 \ \text{mm}^2$) | $\mu\text{m}^2$ | 55% Core Utilization |
| **Gate Count** | 6,059 standard cells | cells | 268 DFFs |
| **Max. System Clock ($f_{MAX}$)** | $221.73$ | MHz | Nominal Corner ($25^\circ\text{C}, 1.80\text{V}$) |
| **Audio Sampling Rate** | Up to $192$ | kHz | $48 \ \text{kHz}$ Nominal |
| **Total Power Consumption** | $1.44$ | mW | Active @ $100 \ \text{MHz}$ APB / $48 \ \text{kHz}$ Audio |
| **Leakage Power** | $36.1$ | nW | Static Standby |
| **Signoff Checks** | DRC: PASSED (0) \| LVS: PASSED (0) \| Antenna: PASSED | — | Hardened IP Core |

---

## 2. Pinout & Interface Description

### System & APB3 Interface
| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `pclk` | Input | 1 | APB Bus System Clock (100 MHz target) |
| `presetn` | Input | 1 | APB Active-Low Asynchronous Reset |
| `paddr` | Input | 32 | APB Address Bus |
| `psel` | Input | 1 | APB Slave Select |
| `penable` | Input | 1 | APB Strobe Enable |
| `pwrite` | Input | 1 | APB Access Direction (1: Write, 0: Read) |
| `pwdata` | Input | 32 | APB Write Data Bus |
| `prdata` | Output | 32 | APB Read Data Bus |
| `pready` | Output | 1 | APB Slave Ready Signal |
| `pslverr` | Output | 1 | APB Slave Transfer Error Signal |

### DSP & Audio Data Stream Interface
| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk_audio_i` | Input | 1 | Audio Sampling Clock (48 kHz) |
| `rst_audio_ni` | Input | 1 | Audio Domain Active-Low Reset |
| `audio_in_data_i` | Input | 16 | Audio Input Sample (Signed Q1.15) |
| `audio_in_valid_i` | Input | 1 | Audio Input Strobe Valid |
| `audio_out_data_o` | Output | 16 | Filtered Audio Output Sample (Signed Q1.15) |
| `audio_out_valid_o` | Output | 1 | Audio Output Strobe Valid |
| `irq_o` | Output | 1 | Active-High Interrupt Line |

---

## 3. MMIO Register Map

Base Address: Subsystem-dependent (Aligned to 32-bit boundary).

| Offset | Register Name | Access | Reset Value | Bitfields & Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | `CR` (Control Register) | R/W | `0x00000000` | **[0]:** `DSP_EN` (1: Enable DSP core)<br>**[1]:** `IRQ_EN` (1: Enable Interrupts) |
| `0x04` | `SR` (Status Register) | R | `0x00000000` | **[0]:** `DATA_READY` (1: Output sample available)<br>**[1]:** `OVERFLOW` (1: Math overflow detected) |
| `0x10` | `COEF_H0` | R/W | `0x00000000` | **[15:0]:** Coefficient $h_0$ (Signed Q1.15 Fixed-Point) |
| `0x14` | `COEF_H1` | R/W | `0x00000000` | **[15:0]:** Coefficient $h_1$ (Signed Q1.15 Fixed-Point) |
| `0x18` | `COEF_H2` | R/W | `0x00000000` | **[15:0]:** Coefficient $h_2$ (Signed Q1.15 Fixed-Point) |
| `0x1C` | `COEF_H3` | R/W | `0x00000000` | **[15:0]:** Coefficient $h_3$ (Signed Q1.15 Fixed-Point) |