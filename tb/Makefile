# ============================================================
# Makefile — ColorSwapCore simulation con iverilog + GTKWave
# ============================================================
#
# Uso:
#   make sim     → compila y simula
#   make wave    → abre GTKWave con la simulación
#   make clean   → limpia archivos generados
#   make all     → sim + wave
# ============================================================

# Archivos fuente
SRC = ../src/tt_um_colorswapcore.v \
      ../src/spi_slave.v \
      ../src/color_processor.v \
      ../src/vga_controller.v

TB  = tb_colorswapcore.v

TOP = tb_colorswapcore

OUT = sim_out
VCD = wave.vcd

.PHONY: all sim wave clean

all: sim wave

sim:
	@echo ">>> Compilando con iverilog..."
	iverilog -o $(OUT) -g2012 $(TB) $(SRC)
	@echo ">>> Simulando..."
	vvp $(OUT)
	@echo ">>> Simulacion completada. Archivo: $(VCD)"

wave:
	@echo ">>> Abriendo GTKWave..."
	gtkwave $(VCD) &

clean:
	@echo ">>> Limpiando..."
	rm -f $(OUT) $(VCD)
	@echo ">>> Listo."