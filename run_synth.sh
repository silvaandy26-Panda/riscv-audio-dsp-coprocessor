#!/bin/bash
echo "=========================================="
echo " Starting Logic Synthesis with Yosys "
echo "=========================================="

# Ejecutar Yosys cargando synth.tcl y guardando la salida en synth.log
yosys -s synth.tcl -l synth.log

echo "=========================================="
echo " Synthesis finished! Log saved to synth.log "
echo "=========================================="

