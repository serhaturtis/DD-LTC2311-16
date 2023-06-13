module synchronous_fifo_tb;

parameter DATA_WIDTH = 32;
parameter ADDRESS_WIDTH = 8;

logic [DATA_WIDTH-1:0] read_data;
logic full;
logic empty;
logic [DATA_WIDTH-1:0] write_data;
logic write_increment, clock, reset_n;
logic read_increment;
logic clear;

logic [DATA_WIDTH-1:0] verify_data_queue[$];
logic [DATA_WIDTH-1:0] verify_write_data;

logic [ADDRESS_WIDTH-1:0]   data_count;

synchronous_fifo #(DATA_WIDTH, ADDRESS_WIDTH) dut (.write_increment(write_increment), .read_increment(read_increment), .clock(clock), .reset_n(reset_n), .write_data(write_data), .read_data(read_data), .data_count(data_count), .full(full), .empty(empty), .clear(clear));


//Asynchronous clock generation
initial begin
    clock = 1'b0;

    fork
      forever #10ns clock = ~clock;
    join
end

//Write generation
initial begin
    write_increment = 1'b0;
    write_data = '0;
    reset_n = 1'b0;
    repeat(5) @(posedge clock);
    reset_n = 1'b1;

    for (int iter=0; iter<2; iter++) begin
      for (int i=0; i<(1<<ADDRESS_WIDTH); i++) begin
        @(posedge clock iff !full);
        write_increment = (i%2 == 0)? 1'b1 : 1'b0;
        if (write_increment) begin
          write_data = $urandom;
          verify_data_queue.push_front(write_data);
          $display("Data count: %d", data_count);
        end
      end
      #1us;
    end
end

initial begin
    read_increment = 1'b0;

    reset_n = 1'b0;
    repeat(8) @(posedge clock);
    reset_n = 1'b1;

    for (int iter=0; iter<2; iter++) begin
      for (int i=0; i<(1<<ADDRESS_WIDTH); i++) begin
        @(posedge clock iff !empty)
        read_increment = (i%2 == 0)? 1'b1 : 1'b0;
        if (read_increment) begin
          verify_write_data = verify_data_queue.pop_back();
          $display("Checking read_data: expected write_data = %h, read_data = %h", verify_write_data, read_data);
          assert(read_data === verify_write_data) else $error("Checking failed: expected write_data = %h, read_data = %h", verify_write_data, read_data);
          $display("Data count: %d", data_count);
        end
      end
      #1us;
    end

    $finish;
end

endmodule