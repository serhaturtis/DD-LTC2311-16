module synchronous_fifo#(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 4
)(
    input logic write_increment, read_increment, clock, reset_n,
    input logic [DATA_WIDTH - 1:0] write_data,
    output logic [DATA_WIDTH - 1:0] read_data,
    output logic [ADDRESS_WIDTH -1:0] data_count,
    output logic full,
    output logic empty,
    input logic clear
);

logic [ADDRESS_WIDTH - 1:0] write_address;
logic [ADDRESS_WIDTH - 1:0] read_address;

dual_port_ram #(DATA_WIDTH, ADDRESS_WIDTH) fifo_memory(.write_increment(write_increment), .full(full), .clock(clock), .write_address(write_address), .read_address(read_address), .write_data(write_data), .read_data(read_data));
synchronous_fifo_controller #(ADDRESS_WIDTH) fifo_controller(.write_increment(write_increment), .read_increment(read_increment), .clock(clock), .reset_n(reset_n), .write_address(write_address), .read_address(read_address), .data_count_in_fifo(data_count), .full(full), .empty(empty), .clear(clear));

endmodule