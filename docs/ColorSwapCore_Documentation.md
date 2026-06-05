================================================================================
  COLORSWAPCORE - RGB COLOR PROCESSOR WITH SPI CONTROL AND VGA OUTPUT
                    Complete Technical Documentation
                    Tiny Tapeout Submission - SKY130 PDK
                     Author: Mauricio Molina Umana
           Electronics Engineering - UPTC, Tunja, Colombia
================================================================================

1. PROJECT OVERVIEW
-------------------
ColorSwapCore is a hardware RGB color transformation processor designed for
Tiny Tapeout. The chip receives 1-bit RGB pixel data via SPI from an ESP32,
applies one of six selectable real-time color transformation modes, and outputs
the result as a standard VGA signal (640x480 at 60Hz).

The design targets SkyWater SKY130 and fits within a single Tiny Tapeout tile.
All arithmetic uses only shifts, additions, and bitwise logic - no multipliers.

2. SYSTEM ARCHITECTURE
----------------------
  ESP32 (image in RAM)
       |
       | SPI via ui_in[0..2]
       v
  +-----------------------------+
  |      ColorSwapCore          |
  |  [SPI Slave]                |
  |       |-> [Mode Register]   |  3-bit, modes 0-5
  |  [Color Processor] <- R,G,B |  from uio[0..2]
  |  [VGA Controller]           |  640x480 at 25MHz
  +-----------------------------+
       | VGA via uo_out[0..4]
       v
    VGA Monitor

3. PIN MAPPING
--------------
INPUTS ui_in[7:0]:
  ui_in[0]   SPI_CLK    SPI clock from ESP32
  ui_in[1]   SPI_MOSI   SPI data from ESP32
  ui_in[2]   SPI_CS     Chip select, active low
  ui_in[7:3] Reserved

OUTPUTS uo_out[7:0]:
  uo_out[0]  VGA_HSYNC  Horizontal sync, active low
  uo_out[1]  VGA_VSYNC  Vertical sync, active low
  uo_out[2]  VGA_R      Red channel 1-bit
  uo_out[3]  VGA_G      Green channel 1-bit
  uo_out[4]  VGA_B      Blue channel 1-bit
  uo_out[7:5] Reserved, driven low

BIDIRECTIONAL uio[7:0] - all inputs (uio_oe = 0):
  uio[0]     R_IN       Red pixel input
  uio[1]     G_IN       Green pixel input
  uio[2]     B_IN       Blue pixel input
  uio[7:3]   Reserved

SYSTEM PINS:
  clk        25 MHz system clock
  rst_n      Active-low reset
  ena        Chip enable (Tiny Tapeout)

4. MODULE DESCRIPTIONS
----------------------
4.1 TOP-LEVEL: project.v (tt_um_example)
  Connects all submodules to Tiny Tapeout pin interface.
  Sets uio_oe = 0 (all bidirectional as inputs).

4.2 SPI SLAVE: spi_slave.v
  SPI Mode 0 (CPOL=0, CPHA=0) receiver.
  - 2-stage synchronizer on all SPI signals (metastability protection)
  - Rising edge detection on SPI_CLK
  - CS falling edge starts reception, CS rising edge latches mode
  - Receives 8-bit frame, extracts bits[2:0] as mode selector
  - Validates mode range (0-5 only)
  - Max SPI clock: less than 12.5 MHz (half system clock)

4.3 COLOR PROCESSOR: color_processor.v
  Applies color transformation registered on rising clock edge.
  Internal signals:
    luma = r_in | g_in | b_in  (pixel is ON if any channel active)
    gray = r_in & g_in & b_in  (pixel is white if all channels active)

4.4 VGA CONTROLLER: vga_controller.v
  VGA 640x480 at 60Hz timing generator.
  Horizontal: 640 active + 16 FP + 96 sync + 48 BP = 800 total
  Vertical:   480 active + 10 FP +  2 sync + 33 BP = 525 total
  HSYNC and VSYNC active LOW.
  RGB outputs forced to 0 outside active display area.

5. COLOR TRANSFORMATION MODES
------------------------------
MODE 0 - Original Color
  r_out=r_in, g_out=g_in, b_out=b_in
  Passthrough - no transformation applied.

MODE 1 - Grayscale
  r_out=g_out=b_out = r_in | g_in | b_in
  Pixel is bright if any channel is active (luminance approximation).

MODE 2 - Selective Grayscale (Red Isolation)
  If r_in active: passthrough (keep original color)
  Else: r_out=g_out=b_out = luma
  Red pixels keep their color; all others become grayscale.

MODE 3 - Retro Palette
  r_out = r_in | b_in
  g_out = g_in & ~r_in
  b_out = b_in | ~r_in
  Quantizes to 4-color retro palette (black, cyan, magenta, white).

MODE 4 - Negative
  r_out=~r_in, g_out=~g_in, b_out=~b_in
  Classic photographic negative inversion.

MODE 5 - Thermal Effect
  r_out = r_in         (hot = red)
  g_out = 0            (no green)
  b_out = ~r_in & luma (cold = blue, only if pixel on and not red)
  Simulates thermal camera view.

6. SPI PROTOCOL
---------------
Frame format: 8 bits MSB first
  Bits[7:3]: Ignored
  Bits[2:0]: Color mode (0-5)

Mode bytes:
  0x00 = Mode 0 (Original)
  0x01 = Mode 1 (Grayscale)
  0x02 = Mode 2 (Selective)
  0x03 = Mode 3 (Retro)
  0x04 = Mode 4 (Negative)
  0x05 = Mode 5 (Thermal)

Sequence: Assert CS -> Send 8-bit mode byte -> Deassert CS
After mode is set, stream pixel R,G,B bits on uio[0..2] synchronized
with the VGA horizontal scan.

7. HARDWARE SETUP
-----------------
VGA connector (DB-15):
  Pin 1  (Red)   <- uo_out[2] via 270-ohm resistor
  Pin 2  (Green) <- uo_out[3] via 270-ohm resistor
  Pin 3  (Blue)  <- uo_out[4] via 270-ohm resistor
  Pin 13 (HSYNC) <- uo_out[0] direct
  Pin 14 (VSYNC) <- uo_out[1] direct
  Pin 5,6,7,8,10 (GND) <- GND

ESP32 wiring:
  ESP32 SCK  -> ui_in[0]
  ESP32 MOSI -> ui_in[1]
  ESP32 CS   -> ui_in[2]
  ESP32 R    -> uio[0]
  ESP32 G    -> uio[1]
  ESP32 B    -> uio[2]

8. DESIGN CONSTRAINTS
---------------------
  - 1-bit per channel (8 possible colors: 2^3)
  - No framebuffer (all pixels streamed from ESP32 in real time)
  - SPI clock must be less than 12.5 MHz
  - Single Tiny Tapeout tile (~167x108 micrometers)
  - No multipliers used

9. ELECTRICAL SPECIFICATIONS
-----------------------------
  Supply voltage:  1.8V (SKY130 core)
  Clock:           25 MHz
  Reset:           Active low synchronous
  Technology:      SkyWater SKY130 HD standard cells

10. FILE STRUCTURE
------------------
  src/project.v          Top-level module
  src/spi_slave.v        SPI receiver
  src/color_processor.v  Color transformer
  src/vga_controller.v   VGA timing generator
  docs/info.md           Tiny Tapeout documentation
  info.yaml              Project metadata and pinout
  README.md              Repository documentation

11. REVISION HISTORY
--------------------
  v1.0 - June 2026
    Initial design, 6 color modes, SPI receiver, VGA controller.
    Submitted to Tiny Tapeout (SKY130 PDK).

================================================================================
                         END OF DOCUMENTATION
================================================================================
