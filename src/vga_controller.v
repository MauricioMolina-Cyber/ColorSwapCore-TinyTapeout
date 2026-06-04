/*
 * vga_controller.v — Controlador VGA 640x480 @ 60Hz
 *
 * Asume clk = 25.175 MHz (estándar VGA pixel clock)
 * TinyTapeout provee hasta 50 MHz; se puede usar con PLL
 * o simplemente dividir el reloj por 2.
 *
 * Parámetros VGA 640x480:
 *   Horizontal: 640 activo + 16 fp + 96 sync + 48 bp = 800 total
 *   Vertical:   480 activo + 10 fp + 2  sync + 33 bp = 525 total
 *   HSYNC y VSYNC activos en BAJO
 */

`default_nettype none

module vga_controller (
    input  wire clk,      // 25 MHz pixel clock
    input  wire rst_n,
    input  wire r_in,
    input  wire g_in,
    input  wire b_in,
    output wire hsync,
    output wire vsync,
    output wire r_out,
    output wire g_out,
    output wire b_out
);

    // -------------------------------------------------------
    // Parámetros de temporización VGA 640x480 @ 60Hz
    // -------------------------------------------------------
    localparam H_ACTIVE = 640;
    localparam H_FP     = 16;
    localparam H_SYNC   = 96;
    localparam H_BP     = 48;
    localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 800

    localparam V_ACTIVE = 480;
    localparam V_FP     = 10;
    localparam V_SYNC   = 2;
    localparam V_BP     = 33;
    localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 525

    // -------------------------------------------------------
    // Contadores de pixel
    // -------------------------------------------------------
    reg [9:0] h_count;  // 0..799
    reg [9:0] v_count;  // 0..524

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // -------------------------------------------------------
    // Generación de sync (activos en BAJO)
    // -------------------------------------------------------
    assign hsync = ~((h_count >= (H_ACTIVE + H_FP)) &&
                     (h_count <  (H_ACTIVE + H_FP + H_SYNC)));

    assign vsync = ~((v_count >= (V_ACTIVE + V_FP)) &&
                     (v_count <  (V_ACTIVE + V_FP + V_SYNC)));

    // -------------------------------------------------------
    // Zona activa: solo mostrar color en región visible
    // -------------------------------------------------------
    wire active = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

    assign r_out = active ? r_in : 1'b0;
    assign g_out = active ? g_in : 1'b0;
    assign b_out = active ? b_in : 1'b0;

endmodule