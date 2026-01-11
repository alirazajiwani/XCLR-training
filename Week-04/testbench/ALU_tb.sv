package alu_package;

typedef enum logic [2:0]{
    ADD = 0, SUB = 1, AND = 2, OR = 3, XOR = 4, SHIFT_LEFT = 5, SHIFT_RIGHT = 6
} alu_op_t;

//------------------------------------------------------------------------------------------
class transaction;
    rand bit [15:0] A, B;
    rand bit [2:0] OP;
    bit [15:0] Result;
    bit Carry, Zero;
    
    // Constraint to ensure OP is within valid range (0-6)
    constraint valid_op {
        OP inside {[0:6]};
    }
    
    function void display_trans(string tag);
        $display("[%t] [%s]: A = %h, B = %h, OP = %0d, Result = %h, Carry = %b, Zero = %b",
                 $time, tag, A, B, OP, Result, Carry, Zero);
    endfunction
endclass

//------------------------------------------------------------------------------------------
// Coverage Class
//------------------------------------------------------------------------------------------
class coverage;
    transaction tr;
    
    // Covergroup for functional coverage
    covergroup alu_cg;
        // Coverpoint for all operations
        cp_operation: coverpoint tr.OP {
            bins add         = {3'b000};
            bins sub         = {3'b001};
            bins and_op      = {3'b010};
            bins or_op       = {3'b011};
            bins xor_op      = {3'b100};
            bins shift_left  = {3'b101};
            bins shift_right = {3'b110};
            illegal_bins invalid = {3'b111};
        }
        
        // Coverpoint for operand A - corner cases
        cp_operand_A: coverpoint tr.A {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins random    = default;
        }
        
        // Coverpoint for operand B - corner cases
        cp_operand_B: coverpoint tr.B {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins random    = default;
        }
        
        // Coverpoint for Result
        cp_result: coverpoint tr.Result {
            bins zero     = {16'h0000};
            bins all_ones = {16'hFFFF};
            bins others   = default;
        }
        
        // Coverpoint for Carry flag
        cp_carry: coverpoint tr.Carry {
            bins no_carry  = {1'b0};
            bins carry_set = {1'b1};
        }
        
        // Coverpoint for Zero flag
        cp_zero: coverpoint tr.Zero {
            bins not_zero = {1'b0};
            bins is_zero  = {1'b1};
        }
        
        // Cross coverage: Operation with Carry
        cross_op_carry: cross cp_operation, cp_carry {
            ignore_bins and_with_carry = binsof(cp_operation.and_op) && binsof(cp_carry.carry_set);
            ignore_bins or_with_carry  = binsof(cp_operation.or_op) && binsof(cp_carry.carry_set);
            ignore_bins xor_with_carry = binsof(cp_operation.xor_op) && binsof(cp_carry.carry_set);
        }
        
        // Cross coverage: Operation with Zero flag
        cross_op_zero: cross cp_operation, cp_zero;
        
        // Option to set coverage goals
        option.per_instance = 1;
        option.goal = 100;
        option.comment = "ALU Functional Coverage";
    endgroup
    
    function new();
        alu_cg = new();
    endfunction
    
    task sample(transaction t);
        tr = t;
        alu_cg.sample();
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
class generator;
    mailbox #(transaction) gen2drv;
    int num_transactions;
    
    function new(mailbox #(transaction) mb, int n);
        this.gen2drv = mb;
        this.num_transactions = n;
    endfunction
    
    task directed_test();
        transaction tr;
        $display("[%t] ====== Edge Case Testing ======", $time);
        
        // Test 1: Zeros
        tr = new();
        tr.A = 16'h0000;
        tr.B = 16'h0000;
        assert(tr.randomize(OP)) else $error("Failed");
        tr.display_trans("GEN");
        gen2drv.put(tr);
        
        // Test 2: Max Values
        tr = new();
        tr.A = 16'hFFFF;
        tr.B = 16'hFFFF;
        assert(tr.randomize(OP)) else $error("Failed");
        tr.display_trans("GEN");
        gen2drv.put(tr);
    endtask
    
    task random_test();
        transaction tr;
        $display("[%t] ====== Random Testing ======", $time);
        repeat(num_transactions) begin
            tr = new();
            assert(tr.randomize()) else $error("Randomization failed!");
            tr.display_trans("GEN");
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
class driver;
    mailbox #(transaction) gen2drv;
    virtual alu_if vif;
    int num_transactions;
    
    function new(virtual alu_if vif, mailbox #(transaction) mb_gen, int n);
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
            vif.A <= tr.A;
            vif.B <= tr.B;
            vif.OP <= tr.OP;
            tr.display_trans("DRV");
        end
        $display("[%t] ====== DRIVER FINISHED ======", $time);
    endtask
endclass

//------------------------------------------------------------------------------------------
class monitor;
    virtual alu_if vif;
    mailbox #(transaction) mon2scb;
    int num_transactions;
    
    function new(virtual alu_if vif, mailbox #(transaction) mb, int n);
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
            tr.A = vif.A;
            tr.B = vif.B;
            tr.OP = vif.OP;
            tr.Result = vif.Result;
            tr.Carry = vif.Carry;
            tr.Zero = vif.Zero;
            mon2scb.put(tr);
            tr.display_trans("MON");
        end
        $display("[%t] ====== MONITOR FINISHED ======", $time);
    endtask
endclass

//------------------------------------------------------------------------------------------
class scoreboard;
    mailbox #(transaction) mon2scb;
    int num_transactions;
    int pass_count, fail_count;
    coverage cov;
    
    function new(mailbox #(transaction) mb, int n);
        this.mon2scb = mb;
        this.num_transactions = n;
        this.pass_count = 0;
        this.fail_count = 0;
        this.cov = new();
    endfunction
    
    // Golden reference model
    function void check_result(transaction tr);
        bit [16:0] expected_result_extended;
        bit [15:0] expected_result;
        bit expected_carry;
        bit expected_zero;
        bit result_match, carry_match, zero_match;
        
        // Calculate expected values based on operation
        case (tr.OP)
            3'b000: begin // ADD
                expected_result_extended = tr.A + tr.B;
                expected_result = expected_result_extended[15:0];
                expected_carry = expected_result_extended[16];
            end
            3'b001: begin // SUB
                expected_result = tr.A - tr.B;
                expected_carry = (tr.A < tr.B);
            end
            3'b010: begin // AND
                expected_result = tr.A & tr.B;
                expected_carry = 1'b0;
            end
            3'b011: begin // OR
                expected_result = tr.A | tr.B;
                expected_carry = 1'b0;
            end
            3'b100: begin // XOR
                expected_result = tr.A ^ tr.B;
                expected_carry = 1'b0;
            end
            3'b101: begin // SHIFT_LEFT
                expected_result = tr.A << tr.B;
                expected_carry = tr.A[15];
            end
            3'b110: begin // SHIFT_RIGHT
                expected_result = tr.A >> tr.B;
                expected_carry = tr.A[0];
            end
            default: begin
                expected_result = 16'h0000;
                expected_carry = 1'b0;
                $error("[SCB] Invalid OP code: %0d", tr.OP);
            end
        endcase
        
        expected_zero = (expected_result == 16'h0000);
        
        // Compare expected with actual
        result_match = (tr.Result === expected_result);
        carry_match = (tr.Carry === expected_carry);
        zero_match = (tr.Zero === expected_zero);
        
        if (result_match && carry_match && zero_match) begin
            pass_count++;
            $display("[%t] [SCB PASS] Test Passed", $time);
        end else begin
            fail_count++;
            $display("[%t] [SCB FAIL] Test Failed", $time);
            $display("    Expected: Result = %h, Carry = %b, Zero = %b", 
                     expected_result, expected_carry, expected_zero);
            $display("    Got:      Result = %h, Carry = %b, Zero = %b", 
                     tr.Result, tr.Carry, tr.Zero);
            if (!result_match) $display("    --> Result mismatch!");
            if (!carry_match) $display("    --> Carry mismatch!");
            if (!zero_match) $display("    --> Zero mismatch!");
        end
    endfunction
    
    task run();
        transaction tr;
        $display("[%t] ====== SCOREBOARD STARTED ======", $time);
        repeat (num_transactions) begin
            mon2scb.get(tr);
            check_result(tr);
            cov.sample(tr);  // Sample coverage
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
        $display("========================================");
        cov.report();  // Display coverage report
    endtask
endclass

//------------------------------------------------------------------------------------------
class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    mailbox #(transaction) gen2drv;
    mailbox #(transaction) mon2scb;
    
    virtual alu_if vif;
    int num_transactions;
    
    function new(virtual alu_if vif, int n = 10);
        this.vif = vif;
        this.num_transactions = n + 2; // Adding 2 directed tests
        
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
interface alu_if(input logic clk);
    logic [15:0] A, B;
    logic [2:0] OP;
    logic [15:0] Result;
    logic Carry, Zero;
    
endinterface

//==========================================================================================
// ALU DUT
//==========================================================================================
typedef enum logic [2:0]{
    ADD = 0, SUB = 1, AND = 2, OR = 3, XOR = 4, SHIFT_LEFT = 5, SHIFT_RIGHT = 6
} alu_op_t;

module ALU #(parameter N = 16)(
    input logic [N-1:0] A, B,
    input alu_op_t OP,
    output logic [N-1:0] Result,
    output logic Carry, Zero 
);
    always_comb begin 
        case (OP)
            ADD: begin
                {Carry, Result} = A + B;
            end
            SUB: begin
                Carry = (A < B);
                Result = A - B;
            end
            AND: begin
                Result = A & B;
                Carry = 1'b0;
            end
            OR: begin
                Result = A | B;
                Carry = 1'b0;
            end
            XOR: begin
                Result = A ^ B;
                Carry = 1'b0;
            end
            SHIFT_LEFT: begin
                Carry = A[N-1];
                Result = A << B;   
            end
            SHIFT_RIGHT: begin
                Carry = A[0];
                Result = A >> B;  
            end
            default: begin
                Result = 16'h0000;
                Carry = 1'b0;
            end
        endcase
        
        Zero = (Result == 0);
    end
endmodule

//==========================================================================================
// TOP MODULE / TESTBENCH
//==========================================================================================
module ALU_tb;
    import alu_package::*;
    
    // Clock generation
    logic clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns period, 100MHz clock
    end
    
    // Interface instantiation
    alu_if vif(clk);
    
    // DUT instantiation
    ALU #(.N(16)) dut (
        .A(vif.A),
        .B(vif.B),
        .OP(alu_op_t'(vif.OP)),
        .Result(vif.Result),
        .Carry(vif.Carry),
        .Zero(vif.Zero)
    );
    
    // Environment instantiation
    environment env;
    
    initial begin
        // Create environment with 20 random transactions
        env = new(vif, 50);
        
        // Display simulation start
        $display("========================================");
        $display("   ALU VERIFICATION TESTBENCH");
        $display("========================================");
        $display("Simulation started at time %0t", $time);
        
        // Reset signals
        vif.A = 16'h0000;
        vif.B = 16'h0000;
        vif.OP = 3'b000;
        
        // Wait for a few clock cycles
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
    
    // Timeout watchdog (reduced timeout)
    initial begin
        #10000; // 10us timeout
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
endmodule