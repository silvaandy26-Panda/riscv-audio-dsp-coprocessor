# Load Liberty library of SkyWater 130nm HD (Typical Corner: 25°C, 1.8V)
read_liberty /foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Load the synthesized netlist
read_verilog audio_dsp_apb_wrapper_netlist_sky130.v

# Link the design to the top-level
link_design audio_dsp_apb_wrapper

# Read  the constraints.sdc
read_sdc constraints.sdc

# Generate critical path reports (Setup time)
report_checks -path_delay max -fields {slew cap input fanout} -digits 3

# Generate reports (Hold time)
report_checks -path_delay min -fields {slew cap input fanout} -digits 3

# Print summary of frequency and slack
report_clock_min_period