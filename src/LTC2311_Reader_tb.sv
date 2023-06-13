module LTC2311_Reader_tb;

  // Inputs
  reg reset_n;
  reg clk;
  reg read;
  reg sleep;
  reg wake;
  
  // Outputs
  wire [15:0] data_out;
  wire data_valid;
  wire busy;
  wire cnv_n;
  wire sck;
  reg sdo;

  logic [63:0] data = 64'hDEADBEEFDEADC0DE;
  logic [7:0] i = 63;

  // Instantiate the module under test
  LTC2311_Reader dut (
    .reset_n(reset_n),
    .clk(clk),
    .read(read),
    .sleep(sleep),
    .wake(wake),
    .data_out(data_out),
    .data_valid(data_valid),
    .busy(busy),
    .cnv_n(cnv_n),
    .sck(sck),
    .sdo(sdo)
  );

  // Clock generation
always begin
  #5 clk = ~clk;
end
  
always @(negedge sck) begin
    sdo = data[i];
    i = i - 1;
  end

  // Stimulus
initial begin
  clk = 0;
  reset_n = 0;
  read = 0;
  #10 reset_n = 1; read = 1;
  
  // Wait for convert
  #30;

end
  
initial begin
  $dumpfile("dump.vcd");
  $dumpvars;
  #10000 $finish;
end

  // Monitor
  always @(posedge clk) begin
    $display("data_out = %h, data_valid = %b, busy = %b", data_out, data_valid, busy);
  end

endmodule
