module synchronous_fifo_controller#(
    ADDRESS_WIDTH = 8
)(
    input logic write_increment, read_increment, clock, reset_n,
    output logic [ADDRESS_WIDTH-1:0] write_address,
    output logic [ADDRESS_WIDTH-1:0] read_address,
    output logic [ADDRESS_WIDTH-1:0] data_count_in_fifo,
    output logic full, empty,
    input logic clear
);

logic full_value;
logic empty_value;
logic [ADDRESS_WIDTH:0] read_address_current;
logic [ADDRESS_WIDTH:0] write_address_current;
logic [ADDRESS_WIDTH:0] read_address_next;
logic [ADDRESS_WIDTH:0] write_address_next;

assign write_address_next = write_address_current + (write_increment & ~full);
assign read_address_next = read_address_current + (read_increment & ~empty);

assign write_address = write_address_current[ADDRESS_WIDTH-1:0];
assign read_address = read_address_current[ADDRESS_WIDTH-1:0];

assign empty_value = (read_address_next == write_address_next);
assign full_value = (write_address_next[ADDRESS_WIDTH] == ~read_address_next[ADDRESS_WIDTH]) & (write_address_next[ADDRESS_WIDTH-1:0] == read_address[ADDRESS_WIDTH-1:0]); 

assign data_count_in_fifo = write_address_current - read_address_current;

always_ff @(posedge clock or negedge reset_n) begin 
    if(!reset_n || (clear == 1'b1))begin
        read_address_current <= {ADDRESS_WIDTH{1'b0}};
        write_address_current <= {ADDRESS_WIDTH{1'b0}};
    end
    else begin
            read_address_current <= read_address_next;
            write_address_current <= write_address_next;
    end
end

always_ff @(posedge clock or negedge reset_n) begin
    if(!reset_n) begin
        full <= 1'b0;
        empty <= 1'b0;
    end
    else begin
        full <= full_value;
        empty <= empty_value;
    end
end

endmodule