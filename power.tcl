# 1. Load Liberty library (Corner Nominal: 25C, 1.80V)
read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 2. Load Gate-Level Netlist
read_verilog designs/audio_dsp_apb_wrapper/runs/RUN_2026-10-31_12-25-00/final/nl/audio_dsp_apb_wrapper.nl.v

# 3. Link design
link_design audio_dsp_apb_wrapper

# 4. Load extracted parasitics (SPEF nominal)
read_spef designs/audio_dsp_apb_wrapper/runs/RUN_2026-10-31_12-25-00/final/spef/nom/audio_dsp_apb_wrapper.nom.spef

# 5. Define main clocks
create_clock -name pclk -period 10.0 [get_ports pclk]
create_clock -name clk_audio_i -period 20833.33 [get_ports clk_audio_i]

# 6. Read switching activity from GLS VCD file
read_vcd -scope tb_audio_dsp_apb/u_dut gls_output.vcd

# 7. Generate detailed power report
report_power
report_power -hierarchy