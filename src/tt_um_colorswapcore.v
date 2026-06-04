/*
 * ColorSwapCore — Procesador de color RGB vía SPI con salida VGA
 * TinyTapeout Top-Level Module
 *
 * Pinout TinyTapeout (8 in / 8 out / 8 bidir):
 *
 * ENTRADAS  (ui_in[7:0]):
 *   ui_in[0] = SPI_CLK   (reloj SPI desde ESP32)
 *   ui_in[1] = SPI_MOSI  (datos SPI desde ESP32)
 *   ui_in[2] = SPI_CS    (chip select SPI, activo en bajo)
 *   ui_in[7:3] = reservado / futuro uso
 *
 * SALIDAS (uo_out[7:0]):
 *   uo_out[0] = VGA_HSYNC
 *   uo_out[1] = VGA_VSYNC
 *   uo_out[2] = VGA_R    (1 bit rojo)
 *   uo_out[3] = VGA_G    (1 bit verde)
 *   uo_out[4] = VGA_B    (1 bit azul)
 *   uo_out[7:5] = reservado
 *
 * BIDIRECCIONALES (uio[7:0]):
 *   uio[2:0] = RGB entrada (R, G, B — 1 bit cada uno, modo demo)
 *   uio[7:3] = reservado
 *
 * MODOS DE COLOR (seleccionados por SPI):
 *   3'b000 = Modo 0: Color original
 *   3'b001 = Modo 1: Escala de grises
 *   3'b010 = Modo 2: Detección de color + gris selectivo
 *   3'b011 = Modo 3: Paleta reducida (retro)
 *   3'b100 = Modo 4: Negativo
 *   3'b101 = Modo 5: Efecto térmico
 */

`default_nettype none

module tt_um_colorswapcore (
    input  wire [7:0] ui_in,    // Entradas dedicadas
    output wire [7:0] uo_out,   // Salidas dedicadas
    input  wire [7:0] uio_in,   // Pines bidir — entrada
    output wire [7:0] uio_out,  // Pines bidir — salida
    output wire [7:0] uio_oe,   // Pines bidir — dirección (1=salida)
    input  wire       ena,      // Habilitador del chip
    input  wire       clk,      // Reloj del sistema
    input  wire       rst_n     // Reset activo en bajo
);

    // -------------------------------------------------------
    // Señales internas
    // -------------------------------------------------------
    wire spi_clk  = ui_in[0];
    wire spi_mosi = ui_in[1];
    wire spi_cs   = ui_in[2];

    wire [2:0] color_mode;      // Modo activo (salida del SPI slave)

    wire r_in = uio_in[0];      // Rojo entrada
    wire g_in = uio_in[1];      // Verde entrada
    wire b_in = uio_in[2];      // Azul entrada

    wire r_out, g_out, b_out;   // Color procesado
    wire hsync, vsync;          // Señales VGA

    // Pines bidir: los 3 bajos son entrada, el resto no usado
    assign uio_oe  = 8'b00000000;  // Todos bidir como entrada
    assign uio_out = 8'b00000000;

    // -------------------------------------------------------
    // Instancia: Receptor SPI (lee el modo desde ESP32)
    // -------------------------------------------------------
    spi_slave u_spi (
        .clk      (clk),
        .rst_n    (rst_n),
        .spi_clk  (spi_clk),
        .spi_mosi (spi_mosi),
        .spi_cs   (spi_cs),
        .mode_out (color_mode)
    );

    // -------------------------------------------------------
    // Instancia: Procesador de color (aplica el efecto)
    // -------------------------------------------------------
    color_processor u_proc (
        .clk       (clk),
        .rst_n     (rst_n),
        .mode      (color_mode),
        .r_in      (r_in),
        .g_in      (g_in),
        .b_in      (b_in),
        .r_out     (r_out),
        .g_out     (g_out),
        .b_out     (b_out)
    );

    // -------------------------------------------------------
    // Instancia: Controlador VGA
    // -------------------------------------------------------
    vga_controller u_vga (
        .clk   (clk),
        .rst_n (rst_n),
        .r_in  (r_out),
        .g_in  (g_out),
        .b_in  (b_out),
        .hsync (hsync),
        .vsync (vsync),
        .r_out (uo_out[2]),
        .g_out (uo_out[3]),
        .b_out (uo_out[4])
    );

    // -------------------------------------------------------
    // Salidas VGA sync
    // -------------------------------------------------------
    assign uo_out[0] = hsync;
    assign uo_out[1] = vsync;
    assign uo_out[7:5] = 3'b000;

endmodule