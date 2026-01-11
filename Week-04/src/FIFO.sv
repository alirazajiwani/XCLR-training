module FIFO#(parameter DEPTH = 8)(
    input logic clk, rst, write_en, read_en,
    input logic [15:0] data_in,
    output logic [15:0] data_out,
    output logic full, empty
);

    logic [15:0] fifo_reg [DEPTH-1:0];
    logic [$clog2(DEPTH):0] W_Pointer, R_Pointer;  // Extra bit to detect full
    logic [$clog2(DEPTH):0] count;
    
    // Flag generation
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    
    // Write and Read control signals
    logic do_write, do_read;
    assign do_write = write_en && !full;
    assign do_read = read_en && !empty;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            W_Pointer <= 0;
            R_Pointer <= 0;
            count <= 0;
            data_out <= 16'h0000;
        end
        else begin
            // Write operation
            if (do_write) begin
                fifo_reg[W_Pointer[$clog2(DEPTH)-1:0]] <= data_in;
                W_Pointer <= W_Pointer + 1;
            end
            
            // Read operation
            if (do_read) begin
                data_out <= fifo_reg[R_Pointer[$clog2(DEPTH)-1:0]];
                R_Pointer <= R_Pointer + 1;
            end
            
            // Count update
            case ({do_write, do_read})
                2'b10: count <= count + 1;  // Write only
                2'b01: count <= count - 1;  // Read only
                default: count <= count;
            endcase
        end
    end

endmodule