# Load GHDL plugin with VHDL-2008 in Yosys
plugin -i ghdl

# Analize and elaborate the VHDL hierarchy with VHDL-2008
ghdl --std=08 rtl/fir_filter.vhd rtl/audio_dsp_coprocessor.vhd -e audio_dsp_coprocessor

# Synth generic RTL to generic netlist
synth -top audio_dsp_coprocessor

# Mapping of Flip-Flops to the Sky130   
dfflibmap -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#Map combinational logic to the Sky130
abc -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

#Clean up of non-used cells and wires
opt_clean -purge

# Print the statistics and cell report
stat -liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Generate the final netlist in Verilog format
# 8. Exportar el netlist a nivel de puertas (Gate-Level Netlist)
write_verilog -noattr audio_dsp_coprocessor_netlist_sky130.v