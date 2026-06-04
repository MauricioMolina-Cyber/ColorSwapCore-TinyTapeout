/*
 * color_processor.v — Procesador de color RGB con 6 modos
 *
 * Nota: TinyTapeout tiene pines limitados. Trabajamos con
 * 1 bit por canal (R, G, B) en esta versión base.
 * Esto es suficiente para demostrar todos los efectos.
 *
 * MODOS:
 *   0 → Color original      : pasa R, G, B sin cambio
 *   1 → Escala de grises    : gray = R & G & B (aprox)
 *   2 → Gris selectivo      : mantiene rojo, resto en gris
 *   3 → Paleta retro        : solo 4 combinaciones posibles
 *   4 → Negativo            : invierte cada canal
 *   5 → Efecto térmico      : azul=frío (solo B), rojo=caliente (solo R)
 */

`default_nettype none

module color_processor (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] mode,    // Modo de color activo
    input  wire       r_in,    // Rojo entrada (1 bit)
    input  wire       g_in,    // Verde entrada (1 bit)
    input  wire       b_in,    // Azul entrada (1 bit)
    output reg        r_out,   // Rojo procesado
    output reg        g_out,   // Verde procesado
    output reg        b_out    // Azul procesado
);

    // Señal de gris aproximada (AND de canales en 1 bit)
    wire gray = r_in & g_in & b_in;
    // Señal de luminancia alternativa (OR — pixel encendido si alguno activo)
    wire luma = r_in | g_in | b_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_out <= 1'b0;
            g_out <= 1'b0;
            b_out <= 1'b0;
        end else begin
            case (mode)

                // ----------------------------------------
                3'd0: begin  // Modo 0: Color original
                    r_out <= r_in;
                    g_out <= g_in;
                    b_out <= b_in;
                end

                // ----------------------------------------
                3'd1: begin  // Modo 1: Escala de grises global
                    // Con 1 bit: encendido si cualquier canal activo
                    r_out <= luma;
                    g_out <= luma;
                    b_out <= luma;
                end

                // ----------------------------------------
                3'd2: begin  // Modo 2: Detección rojo + gris selectivo
                    // Si el canal rojo está activo → mantener color
                    // Si no → convertir a gris
                    if (r_in) begin
                        r_out <= r_in;
                        g_out <= g_in;
                        b_out <= b_in;
                    end else begin
                        r_out <= luma;
                        g_out <= luma;
                        b_out <= luma;
                    end
                end

                // ----------------------------------------
                3'd3: begin  // Modo 3: Paleta reducida (retro)
                    // Cuantiza a paleta de 4 colores:
                    // 00=negro, 01=cyan, 10=magenta, 11=blanco
                    r_out <= r_in | b_in;
                    g_out <= g_in & ~r_in;
                    b_out <= b_in | ~r_in;
                end

                // ----------------------------------------
                3'd4: begin  // Modo 4: Negativo
                    r_out <= ~r_in;
                    g_out <= ~g_in;
                    b_out <= ~b_in;
                end

                // ----------------------------------------
                3'd5: begin  // Modo 5: Efecto térmico
                    // Pixel "frío" (B activo, R inactivo) → azul puro
                    // Pixel "caliente" (R activo) → rojo puro
                    // Intermedio → magenta
                    r_out <= r_in;
                    g_out <= 1'b0;           // Sin verde en modo térmico
                    b_out <= ~r_in & luma;   // Azul cuando no hay rojo
                end

                // ----------------------------------------
                default: begin  // Seguridad: igual a modo 0
                    r_out <= r_in;
                    g_out <= g_in;
                    b_out <= b_in;
                end

            endcase
        end
    end

endmodule