package fifo_package;

//------------------------------------------------------------------------------------------
// Transaction Class
//------------------------------------------------------------------------------------------
class transaction;
    rand bit write_en;
    rand bit read_en;
    rand bit [15:0] data_in;
    bit [15:0] data_out;
    bit full;
    bit empty;
    
    // Constraints for realistic FIFO operations
    constraint valid_ops {
        write_en dist {1 := 60, 0 := 40};
        read_en dist {1 := 60, 0 := 40};
    }

    function void display_test(string tag);
       $display("[%0t] [%s]: WR=%b RD=%b DIN=%h", $time, tag, write_en, read_en, data_in);
    endfunction
    
    function void display_trans(string tag);
        $display("[%0t] [%s]: WR=%b RD=%b DIN=%h DOUT=%h FULL=%b EMPTY=%b",
                 $time, tag, write_en, read_en, data_in, data_out, full, empty);
    endfunction
endclass

//------------------------------------------------------------------------------------------
// Coverage Class
//------------------------------------------------------------------------------------------
class coverage;
    transaction tr;
    
    // Covergroup for functional coverage
    covergroup fifo_cg;
        // Coverpoint for write enable
        cp_write_en: coverpoint tr.write_en {
            bins write_disabled = {1'b0};
            bins write_enabled  = {1'b1};
        }
        
        // Coverpoint for read enable
        cp_read_en: coverpoint tr.read_en {
            bins read_disabled = {1'b0};
            bins read_enabled  = {1'b1};
        }
        
        // Coverpoint for full flag
        cp_full: coverpoint tr.full {
            bins not_full = {1'b0};
            bins is_full  = {1'b1};
        }
        
        // Coverpoint for empty flag
        cp_empty: coverpoint tr.empty {
            bins not_empty = {1'b0};
            bins is_empty  = {1'b1};
        }
        
        // Coverpoint for data patterns
        cp_data_in: coverpoint tr.data_in {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins low      = {[16'h0001:16'h7FFF]};
            bins high     = {[16'h8000:16'hFFFE]};
        }
        
        cp_data_out: coverpoint tr.data_out {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins others   = default;
        }
        
        // Cross coverage: Write when full
        cross_write_full: cross cp_write_en, cp_full {
            bins write_when_full = binsof(cp_write_en.write_enabled) && 
                                   binsof(cp_full.is_full);
            bins write_when_not_full = binsof(cp_write_en.write_enabled) && 
                                        binsof(cp_full.not_full);
        }
        
        // Cross coverage: Read when empty
        cross_read_empty: cross cp_read_en, cp_empty {
            bins read_when_empty = binsof(cp_read_en.read_enabled) && 
                                   binsof(cp_empty.is_empty);
            bins read_when_not_empty = binsof(cp_read_en.read_enabled) && 
                                        binsof(cp_empty.not_empty);
        }
        
        // Cross coverage: Simultaneous operations
        cross_wr_rd: cross cp_write_en, cp_read_en {
            bins both_active = binsof(cp_write_en.write_enabled) && 
                              binsof(cp_read_en.read_enabled);
            bins only_write = binsof(cp_write_en.write_enabled) && 
                             binsof(cp_read_en.read_disabled);
            bins only_read = binsof(cp_write_en.write_disabled) && 
                            binsof(cp_read_en.read_enabled);
            bins both_idle = binsof(cp_write_en.write_disabled) && 
                            binsof(cp_read_en.read_disabled);
        }
        
        // Cross coverage: Operation states
        cross_op_state: cross cp_write_en, cp_read_en, cp_full, cp_empty;
        
        option.per_instance = 1;
        option.goal = 100;
        option.comment = "FIFO Functional Coverage";
    endgroup
    
    function new();
        fifo_cg = new();
    endfunction
    
    task sample(transaction t);
        tr = t;
        fifo_cg.sample();
    endtask
    
    function void report();
        real coverage_percent;
        coverage_percent = $get_coverage();
        $display("========================================");
        $display("      COVERAGE REPORT");
        $display("========================================");
        $display("Overall Coverage: %.2f%%", coverage_percent);
        $display("========================================");
    endfunction
endclass

//------------------------------------------------------------------------------------------
// Generator Class
//------------------------------------------------------------------------------------------
class generator;
    mailbox #(transaction) gen2drv;
    int num_transactions;
    
    function new(mailbox #(transaction) mb, int n);
        this.gen2drv = mb;
        this.num_transactions = n;
    endfunction
    
    task directed_test();
        transaction tr;
        $display("[%t] ====== Directed Edge Case Testing ======", $time);
        
        // Test 1: Fill FIFO completely
        $display("[%t] Test: Filling FIFO", $time);
        repeat(10) begin
            tr = new();
            tr.write_en = 1'b1;
            tr.read_en = 1'b0;
            assert(tr.randomize(data_in)) else $error("Randomization failed");
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
        
        // Test 2: Try writing when full
        $display("[%t] Test: Write when full", $time);
        repeat(2) begin
            tr = new();
            tr.write_en = 1'b1;
            tr.read_en = 1'b0;
            assert(tr.randomize(data_in)) else $error("Randomization failed");
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
        
        // Test 3: Empty FIFO completely
        $display("[%t] Test: Emptying FIFO", $time);
        repeat(10) begin
            tr = new();
            tr.write_en = 1'b0;
            tr.read_en = 1'b1;
            tr.data_in = 16'h0000;
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
        
        // Test 4: Try reading when empty
        $display("[%t] Test: Read when empty", $time);
        repeat(2) begin
            tr = new();
            tr.write_en = 1'b0;
            tr.read_en = 1'b1;
            tr.data_in = 16'h0000;
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
        
        // Test 5: Simultaneous read/write
        $display("[%t] Test: Simultaneous operations", $time);
        repeat(5) begin
            tr = new();
            tr.write_en = 1'b1;
            tr.read_en = 1'b1;
            assert(tr.randomize(data_in)) else $error("Randomization failed");
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
        
        // Test 6: Corner case data values
        $display("[%t] Test: Corner case data", $time);
        tr = new();
        tr.write_en = 1'b1;
        tr.read_en = 1'b0;
        tr.data_in = 16'h0000;
        tr.display_test("GEN");
        gen2drv.put(tr);
        
        tr = new();
        tr.write_en = 1'b1;
        tr.read_en = 1'b0;
        tr.data_in = 16'hFFFF;
        tr.display_test("GEN");
        gen2drv.put(tr);
        
        tr = new();
        tr.write_en = 1'b1;
        tr.read_en = 1'b0;
        tr.data_in = 16'hAAAA;
        tr.display_test("GEN");
        gen2drv.put(tr);
        
        tr = new();
        tr.write_en = 1'b1;
        tr.read_en = 1'b0;
        tr.data_in = 16'h5555;
        tr.display_test("GEN");
        gen2drv.put(tr);
    endtask
    
    task random_test();
        transaction tr;
        $display("[%t] ====== Random Testing ======", $time);
        repeat(num_transactions) begin
            tr = new();
            assert(tr.randomize()) else $error("Randomization failed!");
            tr.display_test("GEN");
            gen2drv.put(tr);
        end
    endtask
    
    task run();
        $display("[%t] ====== GENERATOR STARTED ======", $time);
        directed_test();
        random_test();
        $display("[%t] ====== GENERATOR FINISHED ======", $time);
    endtask
endclass

//------------------------------------------------------------------------------------------
// Driver Class
//------------------------------------------------------------------------------------------
class driver;
    mailbox #(transaction) gen2drv;
    virtual fifo_if vif;
    int num_transactions;
    
    function new(virtual fifo_if vif, mailbox #(transaction) mb_gen, int n);
        this.vif = vif;
        this.gen2drv = mb_gen;
        this.num_transactions = n;
    endfunction
    
    task run();
        transaction tr;
        $display("[%t] ====== DRIVER STARTED ======", $time);
        repeat(num_transactions) begin
            gen2drv.get(tr);
            @(posedge vif.clk);
            vif.write_en <= tr.write_en;
            vif.read_en <= tr.read_en;
            vif.data_in <= tr.data_in;
            tr.display_trans("DRV");
        end
        $display("[%t] ====== DRIVER FINISHED ======", $time);
    endtask
endclass

//------------------------------------------------------------------------------------------
// Monitor Class
//------------------------------------------------------------------------------------------
class monitor;
    virtual fifo_if vif;
    mailbox #(transaction) mon2scb;
    int num_transactions;
    
    function new(virtual fifo_if vif, mailbox #(transaction) mb, int n);
        this.vif = vif;
        this.mon2scb = mb;
        this.num_transactions = n;
    endfunction
    
    task run();
        transaction tr;
        $display("[%t] ====== MONITOR STARTED ======", $time);
        repeat(num_transactions) begin
            @(posedge vif.clk);
            #1; // Small delay to ensure outputs are stable
            tr = new();
            tr.write_en = vif.write_en;
            tr.read_en = vif.read_en;
            tr.data_in = vif.data_in;
            tr.data_out = vif.data_out;
            tr.full = vif.full;
            tr.empty = vif.empty;
            mon2scb.put(tr);
            tr.display_trans("MON");
        end
        $display("[%t] ====== MONITOR FINISHED ======", $time);
    endtask
endclass

//------------------------------------------------------------------------------------------
// Scoreboard Class
//------------------------------------------------------------------------------------------
class scoreboard;
    mailbox #(transaction) mon2scb;
    int num_transactions;
    int pass_count, fail_count;
    coverage cov;
    
    // Reference model
    bit [15:0] fifo_queue[$];
    bit [15:0] output_register;  // Model the output register
    bit [15:0] last_read_data;   // Track what was read last cycle
    parameter DEPTH = 8;
    
    function new(mailbox #(transaction) mb, int n);
        this.mon2scb = mb;
        this.num_transactions = n;
        this.pass_count = 0;
        this.fail_count = 0;
        this.cov = new();
        this.output_register = 16'h0000;
        this.last_read_data = 16'h0000;
    endfunction
    
    // Golden reference model with registered output
    function void check_result(transaction tr);
        bit expected_full;
        bit expected_empty;
        bit [15:0] expected_data_out;
        bit full_match, empty_match, data_match;
        bit test_passed = 1;
        
        // Calculate expected full/empty flags BEFORE operations
        expected_full = (fifo_queue.size() == DEPTH);
        expected_empty = (fifo_queue.size() == 0);
        
        // Expected output is what was read LAST cycle (registered output)
        expected_data_out = output_register;
        
        // Process write operation
        if (tr.write_en && !expected_full) begin
            fifo_queue.push_back(tr.data_in);
        end
        
        // Process read operation - update output register for NEXT cycle
        if (tr.read_en && !expected_empty) begin
            output_register = fifo_queue.pop_front();
        end
        // If no valid read, output_register maintains its value
        
        // Compare flags
        full_match = (tr.full === expected_full);
        empty_match = (tr.empty === expected_empty);
        data_match = (tr.data_out === expected_data_out);
        
        if (full_match && empty_match && data_match) begin
            pass_count++;
            $display("[%t] [SCB PASS] Test Passed | Queue Size: %0d", $time, fifo_queue.size());
        end else begin
            fail_count++;
            $display("[%t] [SCB FAIL] Test Failed | Queue Size: %0d", $time, fifo_queue.size());
            $display("    Expected: FULL=%b EMPTY=%b DOUT=%h", 
                     expected_full, expected_empty, expected_data_out);
            $display("    Got:      FULL=%b EMPTY=%b DOUT=%h", 
                     tr.full, tr.empty, tr.data_out);
            if (!full_match) $display("    --> Full flag mismatch!");
            if (!empty_match) $display("    --> Empty flag mismatch!");
            if (!data_match) $display("    --> Data mismatch!");
        end
    endfunction
    
    task run();
        transaction tr;
        $display("[%t] ====== SCOREBOARD STARTED ======", $time);
        repeat (num_transactions) begin
            mon2scb.get(tr);
            check_result(tr);
            cov.sample(tr);
        end
        $display("[%t] ====== SCOREBOARD FINISHED ======", $time);
        $display("========================================");
        $display("         TEST SUMMARY");
        $display("========================================");
        $display("Total Tests: %0d", num_transactions);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        if (num_transactions > 0)
            $display("Pass Rate:   %.2f%%", (pass_count * 100.0) / num_transactions);
        $display("Final Queue Size: %0d", fifo_queue.size());
        $display("========================================");
        cov.report();
    endtask
endclass

//------------------------------------------------------------------------------------------
// Environment Class
//------------------------------------------------------------------------------------------
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    
    virtual fifo_if vif;
    int num_transactions;
    
    function new(virtual fifo_if vif, int n = 10);
        this.vif = vif;
        this.num_transactions = n + 33; // Adding directed tests
        
        gen2drv = new();
        mon2scb = new();
        
        gen = new(gen2drv, n);
        drv = new(vif, gen2drv, this.num_transactions);
        mon = new(vif, mon2scb, this.num_transactions);
        scb = new(mon2scb, this.num_transactions);
    endfunction
    
    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join
    endtask
endclass

endpackage

//==========================================================================================
// INTERFACE
//==========================================================================================
interface fifo_if(input logic clk);
    logic rst;
    logic write_en;
    logic read_en;
    logic [15:0] data_in;
    logic [15:0] data_out;
    logic full;
    logic empty;
endinterface

//==========================================================================================
// TOP MODULE / TESTBENCH
//==========================================================================================
module FIFO_tb;
    import fifo_package::*;
    
    // Clock generation
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period, 100MHz clock
    end
    
    // Interface instantiation
    fifo_if vif(clk);
    
    // DUT instantiation
    FIFO #(.DEPTH(8)) dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .write_en(vif.write_en),
        .read_en(vif.read_en),
        .data_in(vif.data_in),
        .data_out(vif.data_out),
        .full(vif.full),
        .empty(vif.empty)
    );
    
    // Environment instantiation
    environment env;
    
    initial begin
        // Create environment with random transactions
        env = new(vif, 10);
        
        // Display simulation start
        $display("========================================");
        $display("   FIFO VERIFICATION TESTBENCH");
        $display("========================================");
        $display("Simulation started at time %0t", $time);
        
        // Reset sequence
        vif.rst = 1'b1;
        vif.write_en = 1'b0;
        vif.read_en = 1'b0;
        vif.data_in = 16'h0000;
        
        repeat(3) @(posedge clk);
        vif.rst = 1'b0;
        repeat(2) @(posedge clk);
        
        // Run the test
        env.run();
        
        // Wait for completion
        repeat(5) @(posedge clk);
        
        $display("========================================");
        $display("Simulation ended at time %0t", $time);
        $display("========================================");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000; // 100us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule
