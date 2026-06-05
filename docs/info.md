# ColorSwapCore — RGB Color Processor via SPI with VGA Output

## How it works

ColorSwapCore is a digital ASIC designed for real-time RGB color transformation. It receives pixel data through bidirectional pins and outputs the processed color to a VGA display. The active color effect mode is selected dynamically via SPI communication, allowing a connected microcontroller (such as an ESP32) to switch between six distinct visual effects without interrupting the video stream.

The design is composed of three main functional blocks:

**SPI Slave (`spi_slave.v`)**  
Implements a Mode 0 SPI receiver (CPOL=0, CPHA=0) that captures an 8-bit command byte from the master device. The three least significant bits are extracted and stored as the active color mode register. A two-stage synchronizer is included on all SPI input signals to prevent metastability when crossing clock domains. The mode register is updated on the rising edge of the chip select signal, ensuring atomic updates.

**Color Processor (`color_processor.v`)**  
A fully combinational-registered block that applies one of six color transformations to the incoming 1-bit R, G, B pixel channels based on the current mode register:

| Mode | Effect | Description |
|------|--------|-------------|
| 0 | Original color | Pass-through — no transformation applied |
| 1 | Global grayscale | All channels set equal to the luminance (OR of R, G, B) |
| 2 | Selective grayscale | Red channel preserved; non-red pixels converted to grayscale |
| 3 | Reduced palette (retro) | Quantizes to a 4-color palette with cyan/magenta bias |
| 4 | Negative | Bitwise inversion of all channels |
| 5 | Thermal effect | Red channel maps to warm, blue to cold; green suppressed |

**VGA Controller (`vga_controller.v`)**  
Generates standard VGA 640×480 @ 60 Hz timing signals. Horizontal and vertical counters track the pixel position across the full raster (800×525 total). HSYNC and VSYNC pulses are generated as active-low signals according to the VGA specification. Pixel data is blanked to zero outside the active display region.

## How to test

### RTL Simulation

The design includes a complete testbench (`tb/tb_colorswapcore.v`) compatible with Icarus Verilog. To run the simulation:

```bash
cd tb
make sim
```

The testbench performs the following verification sequence:
1. Applies system reset
2. Sends each mode byte (0x00 through 0x05) via simulated SPI transactions
3. Applies representative pixel combinations (black, red, green, blue, white) for each mode
4. Prints the expected vs. obtained RGB output for visual inspection

Waveforms are dumped to `wave.vcd` and can be viewed with GTKWave:

```bash
make wave
```

### SPI Protocol

To change the color mode, send a single byte over SPI (Mode 0) with the desired mode in bits [2:0]:

| Byte | Mode selected |
|------|--------------|
| 0x00 | Original color |
| 0x01 | Grayscale |
| 0x02 | Selective grayscale |
| 0x03 | Retro palette |
| 0x04 | Negative |
| 0x05 | Thermal effect |

### Pin Description

| Pin | Direction | Description |
|-----|-----------|-------------|
| `ui_in[0]` | Input | SPI Clock (from ESP32) |
| `ui_in[1]` | Input | SPI MOSI (data from ESP32) |
| `ui_in[2]` | Input | SPI CS (active low) |
| `uio_in[0]` | Input | Red pixel input (1-bit) |
| `uio_in[1]` | Input | Green pixel input (1-bit) |
| `uio_in[2]` | Input | Blue pixel input (1-bit) |
| `uo_out[0]` | Output | VGA HSYNC |
| `uo_out[1]` | Output | VGA VSYNC |
| `uo_out[2]` | Output | VGA Red output |
| `uo_out[3]` | Output | VGA Green output |
| `uo_out[4]` | Output | VGA Blue output |
| `clk` | Input | System clock (25 MHz recommended) |
| `rst_n` | Input | Active-low reset |

### Hardware Demo Setup

For a live demonstration:
1. Connect an ESP32 to the SPI pins (`ui_in[0:2]`)
2. Connect a VGA monitor to `uo_out[0:4]` through appropriate resistors
3. Provide a 1-bit RGB source to `uio_in[0:2]`
4. Program the ESP32 to cycle through modes 0–5 on button press

The result is a real-time visual demonstration of six distinct color effects applied to the same image source, all controlled by a single SPI command.

## Design verification results

The design was synthesized and hardened using LibreLane on the SKY130A PDK:

- **LVS**: Passed — layout matches schematic exactly
- **DRC**: Passed — no design rule violations
- **Setup timing**: No violations
- **Hold timing**: No violations
- **Standard cells used**: ~230 logic cells + fill/decap
- **Die area**: 200 × 200 μm

## External hardware

- ESP32 or any SPI-capable microcontroller for mode control
- VGA monitor with standard 15-pin connector
- Current-limiting resistors for VGA color signals (68 Ω recommended per channel)
