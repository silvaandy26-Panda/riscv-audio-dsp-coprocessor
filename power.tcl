# 1. Cargar librerías Liberty (Corner Nominal: 25C, 1.80V)
read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# 2. Cargar Netlist de Puertas
read_verilog designs/audio_dsp_apb_wrapper/runs/RUN_2026-10-31_12-25-00/final/nl/audio_dsp_apb_wrapper.nl.v

# 3. Vincular el diseño
link_design audio_dsp_apb_wrapper

# 4. Cargar parasitarios extraídos (SPEF nominal)
read_spef designs/audio_dsp_apb_wrapper/runs/RUN_2026-10-31_12-25-00/final/spef/nom/audio_dsp_apb_wrapper.nom.spef

# 5. Definir Relojes principales
create_clock -name pclk -period 10.0 [get_ports pclk]
create_clock -name clk_audio_i -period 20833.33 [get_ports clk_audio_i]

# 6. Leer la actividad de conmutación desde el VCD de simulación GLS
read_vcd -scope tb_audio_dsp_apb/u_dut gls_output.vcd

# 7. Generar reporte detallado de potencia
report_power
report_power -hierarchy