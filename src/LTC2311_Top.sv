module LTC2311_Top
#(
    REGISTER_SIZE = 32
)(
    input logic reset_n, clk,
    output logic cnv_n, sck,
    input logic sdo,
    input logic fifo_read_enable,
    // Register ports
    output logic [REGISTER_SIZE-1:0] status_register_out,
    input logic [REGISTER_SIZE-1:0] control_register_in,
    output logic [REGISTER_SIZE-1:0] fifo_data_out
);

// Register bits
localparam STATUS_REG_BUSY_BIT = 0;
localparam STATUS_REG_SLEEP_BIT = 1;
localparam STATUS_REG_CONTINUOUS_BIT = 2;
localparam STATUS_REG_FIFO_FULL_BIT = 3;
localparam STATUS_REG_FIFO_EMPTY_BIT = 4;

localparam CONTROL_REG_READ_ADC_BIT = 0;
localparam CONTROL_REG_CONTINOUS_MODE_ENABLE_BIT = 1;
localparam CONTROL_REG_CONTINOUS_MODE_DISABLE_BIT = 2;
localparam CONTROL_REG_SLEEP_BIT = 3;
localparam CONTROL_REG_WAKE_BIT = 4;
localparam CONTROL_REG_CLEAR_FIFO_BIT = 5;

// Internal regs
logic [REGISTER_SIZE-1:0] status_register;

// Internal signals
logic reader_busy_s;
logic reader_read_s;
logic reader_sleep_s;
logic reader_sleep_v;
logic reader_wake_s;
logic reader_continuous_v;
logic reader_read_single_v;
logic fifo_full_s;
logic fifo_empty_s;
logic fifo_write_enable_s;
logic fifo_clear_s;
logic [15:0] fifo_data_in_s;
logic [15:0] fifo_data_out_s;
logic [3:0] data_count; // We can later add this to status register

// Register bit assignments
assign status_register[STATUS_REG_BUSY_BIT] = reader_busy_s;
assign status_register[STATUS_REG_SLEEP_BIT] = reader_sleep_v;
assign status_register[STATUS_REG_CONTINUOUS_BIT] = reader_continuous_v;
assign status_register[STATUS_REG_FIFO_FULL_BIT] = fifo_full_s;
assign status_register[STATUS_REG_FIFO_EMPTY_BIT] = fifo_empty_s;

// Assign FIFO data output
assign fifo_data_out = {{REGISTER_SIZE-16{1'b0}}, fifo_data_out_s};

// Reader
LTC2311_Reader reader(
    .reset_n(reset_n),
    .clk(clk),
    .read(reader_read_s),
    .sleep(reader_sleep_s),
    .wake(reader_wake_s),
    .data_out(fifo_data_in_s),
    .data_valid(fifo_write_enable_s),
    .busy(reader_busy_s),
    .cnv_n(cnv_n),
    .sck(sck),
    .sdo(sdo)
    );

// FIFO
synchronous_fifo #(16, 4) dut (
    .write_increment(fifo_write_enable_s),
    .read_increment(fifo_read_enable),
    .clock(clk),
    .reset_n(reset_n),
    .write_data(fifo_data_in_s),
    .read_data(fifo_data_out_s),
    .data_count(data_count),
    .full(fifo_full_s),
    .empty(fifo_empty_s),
    .clear(fifo_clear_s)
    );

// Read signal logic
always_comb begin
    reader_read_s = reader_continuous_v | reader_read_single_v;
end

// Update status register
always_ff @(posedge clk, negedge reset_n) begin
    if (reset_n == 1'b0) begin
        status_register_out <= 0;
    end
    else begin
        status_register_out <= status_register;
    end
end

// Control register logic
always_ff @(posedge clk, negedge reset_n) begin
    reader_sleep_s <= 0;
    reader_wake_s <= 0;
    fifo_clear_s <= 0;
    reader_read_single_v <= 0;

    if(control_register_in[CONTROL_REG_SLEEP_BIT] == 1'b1) begin
        reader_sleep_v <= 1'b1;
        reader_sleep_s <= 1'b1;
    end
    else if (control_register_in[CONTROL_REG_WAKE_BIT] == 1'b1) begin
        reader_sleep_v <= 0;
        reader_wake_s <= 1'b1;
    end
    else if (control_register_in[CONTROL_REG_CONTINOUS_MODE_ENABLE_BIT] == 1'b1) begin
        reader_continuous_v <= 1'b1;
    end
    else if (control_register_in[CONTROL_REG_CONTINOUS_MODE_DISABLE_BIT] == 1'b1) begin
        reader_continuous_v <= 0;
    end
    else if (control_register_in[CONTROL_REG_CLEAR_FIFO_BIT] == 1'b1) begin
        fifo_clear_s <= 1'b1;
    end
    else if (control_register_in[CONTROL_REG_READ_ADC_BIT] == 1'b1) begin
        reader_read_single_v <= 1'b1;
    end
    else begin
        reader_sleep_s <= 0;
        reader_wake_s <= 0;
        fifo_clear_s <= 0;
        reader_read_single_v <= 0;
    end

end

endmodule