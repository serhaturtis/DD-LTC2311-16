module dual_port_ram#(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 4
)(
    input logic write_increment, full, clock,
    input logic [ADDRESS_WIDTH - 1:0] write_address,
    input logic [ADDRESS_WIDTH - 1:0] read_address,
    input logic [DATA_WIDTH - 1:0] write_data,
    output logic [DATA_WIDTH - 1:0] read_data
);

localparam DEPTH = 1 << ADDRESS_WIDTH;

logic [DATA_WIDTH -1:0] memory [0:DEPTH-1];

assign read_data = memory[read_address];

always_ff @ (posedge clock) begin
    if(write_increment && !full) begin
        memory[write_address] <= write_data;
    end
end

endmodule
