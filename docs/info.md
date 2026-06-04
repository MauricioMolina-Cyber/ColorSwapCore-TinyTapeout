## How it works

ColorSwapCore is a real-time RGB color transformation processor. An ESP32 stores an image in RAM and streams pixel data to the chip via SPI, synchronized with the VGA horizontal scan. The chip receives each pixel (R, G, B), applies one of six selectable color transformations, and outputs the result through a VGA signal.

The six modes are selected by sending a configuration byte over SPI before streaming pixel data:
- Mode 0: Original color passthrough
- Mode 1: Grayscale conversion using bit-shift approximation
- Mode 2: Selective color detection — target color range converted to grayscale
- Mode 3: Reduced palette retro effect
- Mode 4: Negative — color inversion per channel
- Mode 5: Thermal effect — brightness mapped to blue-red gradient

All transformations use only shifts, additions, and comparisons — no multipliers — to remain within the tile area budget.

## How to test

Connect an ESP32 to the SPI pins (ui[0]=CLK, ui[1]=MOSI, ui[2]=CS) and a VGA monitor to the output pins. The ESP32 sends a mode byte followed by continuous RGB pixel data synchronized with the VGA scan. Change the mode byte to switch between color effects in real time.

## External hardware

- ESP32 or RP2040 as SPI master and image source
- VGA monitor
- VGA resistor DAC (1-bit per channel)
