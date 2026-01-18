# Combination Logic

A collection of digital design projects implementing fundamental combinational and sequential logic circuits in SystemVerilog with comprehensive verification testbenches.

## 📁 Project Structure

```
Week-01/
├── src/
│   ├── adder32.sv
│   ├── encoder_8to3.sv
│   └── barrel_shifter.sv
└── testbench/
    ├── adder32_tb.sv
    ├── encoder_tb.sv
    └── barrel_shifter_tb.sv
```


## Modules Implemented

### 1. 32-bit Adder (`adder32.sv`)
A 32-bit full adder with carry-in and carry-out.

**Features:**
- Adds two 32-bit numbers with carry input
- Produces 32-bit sum and carry output
- Efficient synthesis-friendly implementation

**Interface:**
```systemverilog
module adder32(
    input  logic [31:0] a, b,
    input  logic        cin,
    output logic [31:0] s,
    output logic        cout
);
```

---

### 2. 8-to-3 Priority Encoder (`encoder_8to3.sv`)
A priority encoder that converts 8-bit input to 3-bit binary output.

**Features:**
- Priority encoding from MSB to LSB
- Handles multiple active inputs
- Default output for all-zero input

**Interface:**
```systemverilog
module encoder_8to3(
    input  logic [7:0] in,
    output logic [2:0] out
);
```

---

### 3. 32-bit Barrel Shifter (`barrel_shifter.sv`)
A logarithmic barrel shifter for efficient bit shifting operations.

**Features:**
- Logical left and right shifts
- Variable shift amount (0-31 bits)
- Single-cycle operation
- Five-stage logarithmic architecture

**Interface:**
```systemverilog
module barrel_shifter(
    input  logic [31:0] data_in,
    input  logic [4:0]  shift_amt,
    input  logic        dir,        // 0 = left, 1 = right
    output logic [31:0] data_out
);
```

---

## ✅ Verification

Each module includes a comprehensive self-checking testbench that:

- Applies both directed and randomized test vectors
- Computes expected outputs automatically
- Compares DUT output with expected results
- Prints PASS/FAIL for each test case
- Provides test summary statistics

### Test Coverage

| Module | Directed Tests | Random Tests | Total Tests | Pass Rate |
|--------|---------------|--------------|-------------|-----------|
| Adder | 4 | 3 | 7 | 100% |
| Encoder | 8 | 3 | 11 | 100% |
| Barrel Shifter | 64 | 3 | 67 | 100% |

---

## 📊 Sample Output

### Adder Testbench
```
PASS: a=00000000 b=00000000 cin=0 | s=00000000 cout=0 | exp=000000000
PASS: a=ffffffff b=ffffffff cin=0 | s=fffffffe cout=1 | exp=1fffffffe
PASS: a=ffffffff b=00000001 cin=0 | s=00000000 cout=1 | exp=100000000
PASS: a=80000000 b=80000000 cin=0 | s=00000000 cout=1 | exp=100000000
Adder Test Summary: PASS=7 FAIL=0
```

### Barrel Shifter Testbench
```
PASS: data=a5a5a5a5 shift=0 dir=0 | out=a5a5a5a5 | exp=a5a5a5a5
PASS: data=a5a5a5a5 shift=1 dir=0 | out=4b4b4b4a | exp=4b4b4b4a
PASS: data=a5a5a5a5 shift=1 dir=1 | out=52d2d2d2 | exp=52d2d2d2
...
Barrel Shifter Test Summary: PASS=67 FAIL=0
```

---

## 🛠️ Design Highlights

### Adder
- Uses concatenation for clean carry-out assignment
- Synthesis tools can optimize for area or speed
- Fully combinational design

### Encoder
- Priority chain using if-else structure
- Deterministic behavior for invalid inputs
- Minimal logic depth

### Barrel Shifter
- Logarithmic architecture reduces delay
- Only 5 multiplexer stages for 32-bit shift
- Direction control for left/right shifts
- Zero-fill for logical shifts

---

## 📝 Learning Objectives

- [x] Design combinational logic in SystemVerilog
- [x] Implement self-checking testbenches
- [x] Use directed and random test vectors
- [x] Verify edge cases and corner cases
- [x] Generate automated test reports
- [x] Follow RTL coding best practices

---

## 🔮 Future Enhancements

- [ ] Add functional coverage collection
- [ ] Implement SystemVerilog assertions (SVA)
- [ ] Add waveform generation scripts
- [ ] Create constrained random stimulus
- [ ] Add code coverage analysis
- [ ] Implement arithmetic right shift in barrel shifter
- [ ] Add rotation functionality to barrel shifter

---


**Note:** This is an educational project for learning hardware design and verification concepts.
