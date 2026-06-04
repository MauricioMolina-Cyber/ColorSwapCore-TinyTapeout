/*
 * spi_slave.v — Receptor SPI Mode 0 (CPOL=0, CPHA=0)
 *
 * Recibe 8 bits desde la ESP32. Solo usa los 3 bits bajos
 * como selector de modo (6 modos posibles).
 *
 * Protocolo:
 *   - CS baja → inicio de trama
 *   - Se muestrea MOSI en cada flanco de subida de SPI_CLK
 *   - CS sube → modo_out se actualiza con los 3 bits recibidos
 */

`default_nettype none

module spi_slave (
    input  wire       clk,       // Reloj del sistema
    input  wire       rst_n,     // Reset activo en bajo
    input  wire       spi_clk,   // Reloj SPI (desde ESP32)
    input  wire       spi_mosi,  // Datos SPI (desde ESP32)
    input  wire       spi_cs,    // Chip select (activo en bajo)
    output reg  [2:0] mode_out   // Modo de color activo
);

    // -------------------------------------------------------
    // Sincronizador de 2 etapas para las señales SPI
    // (evita metaestabilidad al cruzar dominios de reloj)
    // -------------------------------------------------------
    reg [1:0] spi_clk_sync;
    reg [1:0] spi_cs_sync;
    reg [1:0] spi_mosi_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_clk_sync  <= 2'b00;
            spi_cs_sync   <= 2'b11;
            spi_mosi_sync <= 2'b00;
        end else begin
            spi_clk_sync  <= {spi_clk_sync[0],  spi_clk};
            spi_cs_sync   <= {spi_cs_sync[0],   spi_cs};
            spi_mosi_sync <= {spi_mosi_sync[0],  spi_mosi};
        end
    end

    // Detección de flancos
    wire spi_clk_rise = (spi_clk_sync == 2'b01);  // flanco subida
    wire spi_cs_rise  = (spi_cs_sync  == 2'b01);  // CS sube = fin trama

    // -------------------------------------------------------
    // Desplazamiento de bits recibidos
    // -------------------------------------------------------
    reg [7:0] shift_reg;
    reg [3:0] bit_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 8'h00;
            bit_count <= 4'd0;
            mode_out  <= 3'd0;
        end else begin

            // CS activo (en bajo) → recibiendo datos
            if (!spi_cs_sync[1]) begin
                if (spi_clk_rise && bit_count < 4'd8) begin
                    shift_reg <= {shift_reg[6:0], spi_mosi_sync[1]};
                    bit_count <= bit_count + 1;
                end
            end

            // CS sube → trama completa, actualizar modo
            if (spi_cs_rise) begin
                if (bit_count == 4'd8) begin
                    // Validar rango: solo modos 0-5 son válidos
                    if (shift_reg[2:0] <= 3'd5)
                        mode_out <= shift_reg[2:0];
                end
                bit_count <= 4'd0;
                shift_reg <= 8'h00;
            end

        end
    end

endmodule