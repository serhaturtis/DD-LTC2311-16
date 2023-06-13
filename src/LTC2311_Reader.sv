module LTC2311_Reader(
    // Module ports
    input logic reset_n, clk,
    input logic read, sleep, wake,
    output logic [15:0] data_out,
    output logic data_valid, busy,
    // IC ports
    output logic cnv_n, sck,
    input logic sdo
);

localparam convert_duration = 3; // Convert clock cycles
localparam read_duration = 16; // Read clock cycles

typedef enum logic [1:0] {IDLE_STATE, CONVERT_STATE, READ_STATE} state_t;
state_t state_reg, state_next;

logic [1:0] convert_counter = 0;
logic [5:0] read_counter = 0;

// State change logic
always_ff @(posedge clk, negedge reset_n) begin
    if (reset_n == 1'b0) begin
        state_reg <= IDLE_STATE;
    end
    else begin
        state_reg <= state_next;
    end
end

always_comb begin
    case (state_reg)
        IDLE_STATE: begin
            if (read == 1'b1) begin
                state_next = CONVERT_STATE;
            end
            else begin
                state_next = IDLE_STATE;
            end
        end
        CONVERT_STATE: begin
            if (convert_counter == convert_duration-1) begin
                state_next = READ_STATE;
            end
            else begin
                state_next = CONVERT_STATE;
            end
        end
        READ_STATE: begin
            if (read_counter == read_duration) begin
                state_next = IDLE_STATE;
            end
            else begin
                state_next = READ_STATE;
            end
        end
        default: begin
            state_next = IDLE_STATE;
        end
    endcase
end

// Read logic
always_comb begin
    if ((state_reg == READ_STATE) && (read_counter != read_duration)) begin
        sck = clk;
    end
    else begin
        sck = 1;
    end
end

always_ff @(posedge clk, negedge reset_n) begin
    if (reset_n == 1'b0) begin
        convert_counter <= 0;
        read_counter <= 0;
        data_out <= 0;
        data_valid <= 0;
        cnv_n <= 0;
        busy <= 0;
    end
    else begin
        case (state_reg)
            IDLE_STATE: begin
                convert_counter <= 0;
                read_counter <= 0;
                data_out <= 0;
                data_valid <= 0;
                cnv_n <= 0;
                busy <= 0;
            end
            CONVERT_STATE: begin
                busy <= 1;
                cnv_n <= 1;
                if (convert_counter != convert_duration -1) begin
                    convert_counter <= convert_counter + 1;
                end
                read_counter <= 0;
                data_out <= 0;
                data_valid <= 0;
            end
            READ_STATE: begin
                busy <= 1;
                if (read_counter != read_duration) begin // We need to receive data in the last sck posedge too
                    read_counter <= read_counter + 1;
                    data_valid <= 0;
                    // Shift data in
                    //if(sck == 1'b1) begin
                        data_out <= (data_out << 1) | {15'd0,sdo};
                    //end
                end
                else begin
                    data_valid <= 1;
                end

                convert_counter <= 0;
                cnv_n <= 0;
            end
            default: begin
                convert_counter <= 0;
                read_counter <= 0;
                data_out <= 0;
                data_valid <= 0;
                cnv_n <= 0;
                busy <= 0;
            end
        endcase

    end
end

endmodule
