/*
 * tb_colorswapcore.v — Testbench para ColorSwapCore
 *
 * Prueba:
 *   1. Reset del sistema
 *   2. Envío de cada modo por SPI (modos 0 al 5)
 *   3. Verificación visual de salidas RGB en GTKWave
 */

`timescale 1ns/1ps
`default_nettype none

module tb_colorswapcore;

    // -------------------------------------------------------
    // Señales del DUT
    // -------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // -------------------------------------------------------
    // Instancia del diseño bajo prueba (DUT)
    // -------------------------------------------------------
    tt_um_colorswapcore dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .ena     (1'b1),
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_in),
        .uio_out (uio_out),
        .uio_oe  (uio_oe)
    );

    // -------------------------------------------------------
    // Reloj 25 MHz (período = 40 ns)
    // -------------------------------------------------------
    initial clk = 0;
    always #20 clk = ~clk;

    // -------------------------------------------------------
    // Tarea: Enviar 1 byte por SPI a 1 MHz
    // -------------------------------------------------------
    task spi_send_byte;
        input [7:0] data;
        integer i;
        begin
            // CS activo (bajo)
            ui_in[2] = 1'b0;
            #200;

            // Enviar 8 bits MSB primero
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[1] = data[i];  // MOSI
                #250;
                ui_in[0] = 1'b1;     // CLK sube → muestreo
                #250;
                ui_in[0] = 1'b0;     // CLK baja
            end

            #200;
            // CS inactivo (alto) → modo se actualiza
            ui_in[2] = 1'b1;
            #500;
        end
    endtask

    // -------------------------------------------------------
    // Tarea: Aplicar un pixel de prueba
    // -------------------------------------------------------
    task apply_pixel;
        input r, g, b;
        begin
            uio_in[0] = r;
            uio_in[1] = g;
            uio_in[2] = b;
            #100;
        end
    endtask

    // -------------------------------------------------------
    // Secuencia principal de prueba
    // -------------------------------------------------------
    initial begin
        // Volcado de señales para GTKWave
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_colorswapcore);
        $dumpvars(1, dut);

        // Estado inicial
        clk      = 0;
        rst_n    = 0;
        ui_in    = 8'h04;  // CS=1, CLK=0, MOSI=0
        uio_in   = 8'h07;  // R=1, G=1, B=1 (pixel blanco)

        // Reset
        #200;
        rst_n = 1;
        #200;

        $display("=== ColorSwapCore Testbench ===");
        $display("Pixel de entrada: R=1 G=1 B=1 (blanco)");
        $display("");

        // --- Modo 0: Color original ---
        $display(">> Enviando Modo 0: Color original");
        spi_send_byte(8'h00);
        apply_pixel(1, 1, 1);
        $display("   VGA R=%b G=%b B=%b", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        // --- Modo 1: Escala de grises ---
        $display(">> Enviando Modo 1: Escala de grises");
        spi_send_byte(8'h01);
        apply_pixel(1, 0, 0);  // Solo rojo
        $display("   VGA R=%b G=%b B=%b (debe ser igual en todos)", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        // --- Modo 2: Gris selectivo ---
        $display(">> Enviando Modo 2: Gris selectivo");
        spi_send_byte(8'h02);
        apply_pixel(1, 0, 1);  // Rojo + azul
        $display("   VGA R=%b G=%b B=%b", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        // --- Modo 3: Paleta retro ---
        $display(">> Enviando Modo 3: Paleta retro");
        spi_send_byte(8'h03);
        apply_pixel(0, 1, 0);  // Solo verde
        $display("   VGA R=%b G=%b B=%b", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        // --- Modo 4: Negativo ---
        $display(">> Enviando Modo 4: Negativo");
        spi_send_byte(8'h04);
        apply_pixel(1, 1, 1);  // Blanco → debe dar negro
        $display("   VGA R=%b G=%b B=%b (debe ser 0 0 0)", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        // --- Modo 5: Efecto térmico ---
        $display(">> Enviando Modo 5: Efecto termico");
        spi_send_byte(8'h05);
        apply_pixel(1, 0, 0);  // Solo rojo → caliente
        $display("   VGA R=%b G=%b B=%b (R=1 = caliente)", uo_out[2], uo_out[3], uo_out[4]);
        apply_pixel(0, 0, 1);  // Solo azul → frío
        #100;
        $display("   VGA R=%b G=%b B=%b (B=1 = frio)", uo_out[2], uo_out[3], uo_out[4]);
        #1000;

        $display("");
        $display("=== Simulacion completada ===");
        $finish;
    end

endmodule