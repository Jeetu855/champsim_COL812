# ChampSim Complete Learning Guide

**Author:** Created for understanding ChampSim microarchitecture simulation  
**Date:** February 2026  
**Purpose:** Comprehensive guide from basics to advanced experimentation

---

## Table of Contents

1. [What is ChampSim?](#what-is-champsim)
2. [How ChampSim Works - The Big Picture](#how-champsim-works)
3. [Understanding Trace-Based Simulation](#understanding-traces)
4. [ChampSim Architecture Components](#architecture-components)
5. [Configuration Files - Every Parameter Explained](#configuration-parameters)
6. [Reading ChampSim Output](#reading-output)
7. [What You Can Modify and Study](#what-to-modify)
8. [Performance Metrics Explained](#performance-metrics)
9. [Common Experiments and Their Purpose](#common-experiments)
10. [Advanced Topics: sLDM and Custom Instrumentation](#advanced-topics)
11. [Troubleshooting and Tips](#troubleshooting)

---

## What is ChampSim?

ChampSim (Championship Simulator) is a trace-based microarchitecture simulator created for computer architecture research and education. Think of it as a virtual testing ground where you can experiment with different processor designs without building actual hardware.

### Why ChampSim Exists

Imagine you want to test what happens if you make the L1 data cache twice as big, or if you change the cache replacement policy from LRU to a smarter algorithm. Building actual hardware to test these ideas would cost millions of dollars and take years. ChampSim lets you test these ideas in hours or days on a regular computer.

### What Makes ChampSim Special

ChampSim was specifically designed to be:
- **Fast enough** to run realistic workloads (simulating billions of instructions in reasonable time)
- **Accurate enough** to give meaningful performance predictions
- **Simple enough** for students and researchers to understand and modify
- **Modular enough** to easily swap different components (branch predictors, prefetchers, etc.)

### The Trade-off

ChampSim is not a cycle-accurate simulator. It models the major performance effects (cache behavior, branch prediction, instruction-level parallelism) but simplifies some details. This is intentional - it lets ChampSim run much faster while still providing useful insights.

---

## How ChampSim Works - The Big Picture

### The Simulation Loop

ChampSim operates in a continuous loop that mimics how a real processor works:

1. **Fetch**: Read the next instruction from the trace file
2. **Decode**: Determine what type of instruction it is (load, store, branch, arithmetic, etc.)
3. **Execute**: Simulate the instruction executing in the processor pipeline
4. **Memory Access**: If the instruction accesses memory, simulate the cache hierarchy
5. **Commit**: Retire the instruction and update architectural state
6. **Repeat**: Move to the next instruction

### From Trace to Performance Metrics

Here is how a single instruction flows through ChampSim:
```
Trace File: "LOAD from address 0x7fff1000"
     ↓
ChampSim reads: PC=0x400100, Type=LOAD, Address=0x7fff1000
     ↓
Simulates: Is this address in L1D cache?
     ↓
If HIT: Fast! (4-5 cycles latency)
If MISS: Check L2C → Check LLC → Maybe DRAM (200+ cycles)
     ↓
Track: How many cycles did this take?
     ↓
Update: Total cycles counter, cache statistics, etc.
```

After simulating all instructions, ChampSim calculates:
- **IPC** (Instructions Per Cycle) = Total Instructions / Total Cycles
- **Cache Miss Rates** = Misses / Accesses for each cache level
- **Branch Prediction Accuracy**
- And many more metrics...

### The Two-Phase Approach

ChampSim runs in two phases:

**Warmup Phase** (e.g., 10 million instructions):
- Simulates instructions but doesn't collect statistics
- Purpose: Fill caches and branch predictors with realistic data
- Why: If you start with empty caches, the first few million instructions will have unrealistically high miss rates

**Simulation Phase** (e.g., 50 million instructions):
- Continues simulation AND collects all statistics
- Purpose: Measure performance in a realistic steady state
- Why: This gives you accurate performance metrics

---

## Understanding Traces

### What is a Trace?

A trace is a recording of a program's execution. Think of it like a flight recorder - it captures what the program did, not how the hardware executed it.

For each instruction, a ChampSim trace records:
- **Instruction address** (PC - Program Counter): Where in the program is this instruction?
- **Instruction type**: Is it a load, store, branch, or computation?
- **Memory address** (if applicable): What address did it access?
- **Branch outcome** (if applicable): Was the branch taken or not taken?

### What a Trace Does NOT Contain

The trace does not record:
- How long each instruction took (ChampSim simulates this)
- Which pipeline stage each instruction was in (ChampSim models this)
- Cache hits or misses (ChampSim determines this based on your cache configuration)

This is the power of trace-based simulation - the same trace can be run with different cache sizes, different branch predictors, or different processor configurations, and you will get different performance results.

### Trace Types You Encountered

Looking at your traces:

**603.bwaves_s-891B**: 
- From SPEC CPU2017 benchmark suite
- Scientific computing (computational fluid dynamics)
- Characteristic: Regular memory access patterns, very memory-intensive
- Real-world equivalent: Weather simulation, physics modeling

**410.bwaves-945B**:
- SPEC CPU2006 benchmark
- Quantum chromodynamics simulation
- Characteristic: Excellent cache locality, compute-intensive
- Real-world equivalent: Scientific computation with good data reuse

**400.perlbench, 401.bzip2, 416.gamess**:
- Various workloads from SPEC suites
- Range from scripting languages to compression to chemistry simulation
- Purpose: Represent diverse real-world application behaviors

### How Traces Are Created

Traces are created using binary instrumentation tools like Intel Pin. The tool:
1. Intercepts a running program
2. Records every instruction and memory access
3. Compresses the recording (64 bytes per instruction → ~1 byte after compression)
4. Saves as a .champsimtrace.xz file

For a 1 billion instruction trace:
- Uncompressed: ~64 GB
- Compressed: ~200-400 MB

---

## Architecture Components

ChampSim models a modern out-of-order processor. Let me explain each major component:

### 1. Out-of-Order CPU Core

The core is the "brain" of the processor. ChampSim models an out-of-order execution pipeline with these stages:

**Fetch**:
- Reads instructions from the trace
- Controlled by `fetch_width` (how many instructions per cycle)
- Limited by instruction cache (L1I) performance

**Decode**:
- Determines instruction type and operands
- Controlled by `decode_width` and `decode_latency`
- Builds dependency information

**Dispatch/Schedule**:
- Sends instructions to execution units when operands are ready
- Uses the Register File and Reservation Stations
- Controlled by `dispatch_width`, `scheduler_size`

**Execute**:
- Performs the actual computation
- Controlled by `execute_width` (execution ports/units)
- Different operations may have different latencies

**Memory**:
- Handles loads and stores through the Load Queue (LQ) and Store Queue (SQ)
- Interacts with the cache hierarchy
- Controlled by `lq_size`, `sq_size`, `lq_width`, `sq_width`

**Retire**:
- Commits instructions in program order
- Updates architectural state
- Controlled by `retire_width` and `rob_size` (Reorder Buffer)

### 2. Branch Prediction

Branch predictors try to guess which direction a branch will go before it executes. This is critical because modern processors need to fetch instructions ahead of time.

**Why it matters**: If the processor waits for every branch to resolve, it would stall constantly. Good branch prediction keeps the pipeline full.

**Types available in ChampSim**:
- `bimodal`: Simple 2-bit saturating counter per branch
- `gshare`: Uses global history XORed with PC
- `hashed_perceptron`: Neural network-based predictor
- `perceptron`: Perceptron learning algorithm

**Your configuration**: Uses `bimodal` (simplest, good baseline)

**Metrics to watch**:
- Branch prediction accuracy: >90% is good, >95% is excellent
- MPKI (Mispredictions Per Kilo Instructions): Lower is better

### 3. Cache Hierarchy

The cache hierarchy is where most performance is won or lost for memory-intensive programs.

**L1 Instruction Cache (L1I)**:
- Stores recently used instructions
- Very small and very fast (typically 4-5 cycles)
- Your config: 64 sets × 8 ways = 512 cache lines × 64 bytes = 32 KB

**L1 Data Cache (L1D)**:
- Stores recently used data
- Your config: 64 sets × 12 ways = 768 lines × 64 bytes = 48 KB
- Latency: 5 cycles
- This is where most loads and stores go first

**L2 Cache (L2C)**:
- Unified (holds both instructions and data)
- Larger but slower than L1
- Your config: 1024 sets × 8 ways = 8192 lines × 64 bytes = 512 KB
- Latency: 10 cycles

**Last Level Cache (LLC)**:
- Shared across all cores (in multi-core systems)
- Much larger, even slower
- Your config: 2048 sets × 16 ways = 32768 lines × 64 bytes = 2 MB
- Latency: 20 cycles

**Why multiple levels?**: This is the memory hierarchy principle:
- Smaller caches are faster but hold less data
- Larger caches hold more data but are slower
- Multi-level design balances speed and capacity

### 4. TLBs (Translation Lookaside Buffers)

TLBs cache virtual-to-physical address translations. Every memory access needs an address translation, and doing a full page table walk is expensive (hundreds of cycles).

**ITLB**: For instruction addresses
**DTLB**: For data addresses  
**STLB**: Second-level TLB, larger but slower

**Why they matter**: If you have TLB misses, you pay for page table walks on top of cache misses, making performance even worse.

### 5. DRAM (Main Memory)

When data is not in any cache level, you must go to DRAM. This is expensive:
- L1 hit: ~5 cycles
- DRAM access: ~200-300 cycles (60x slower!)

**Your DRAM configuration**:
- Data rate: 3200 MT/s (DDR4 speed)
- 1 channel, 1 rank
- Bank organization for modeling row buffer hits/misses

**Row buffer hits vs misses**:
- Row buffer hit: Data is in the currently open DRAM row (~faster)
- Row buffer miss: Must close current row and open new one (~slower)

For 603.bwaves_s, you saw only 7.56% row buffer hits, meaning very random memory access patterns.

---

## Configuration Parameters

Let me explain every parameter in your `champsim_config.json`:

### Block and Page Sizes
```json
"block_size": 64,
"page_size": 4096,
```

**block_size** (64 bytes):
- This is your cache line size
- All caches transfer data in 64-byte chunks
- Even if you load 1 byte, the cache fetches the entire 64-byte line
- Why 64? It is a good balance between spatial locality and wasted bandwidth

**page_size** (4096 bytes = 4 KB):
- Virtual memory page size
- Operating system manages memory in 4 KB pages
- This affects TLB design (each TLB entry covers 4 KB of address space)

### CPU Core Parameters
```json
"frequency": 4000,
```
- Clock frequency in MHz (4000 MHz = 4 GHz)
- Doesn't affect simulation much (ChampSim models cycles, not real time)
- Used for calculating time-based metrics

**Pipeline Widths**:
```json
"fetch_width": 6,
"decode_width": 6,
"dispatch_width": 6,
"execute_width": 4,
"retire_width": 5,
```

These control how many instructions can move through each pipeline stage per cycle:
- `fetch_width: 6`: Can fetch up to 6 instructions per cycle from L1I
- `decode_width: 6`: Can decode up to 6 instructions per cycle
- `execute_width: 4`: Can execute up to 4 instructions per cycle (4 execution ports)
- `retire_width: 5`: Can retire up to 5 instructions per cycle

**Why different widths?**: Real processors have different bottlenecks at different stages. Execution is often narrower because functional units are expensive.

**Structure Sizes**:
```json
"rob_size": 352,
"lq_size": 128,
"sq_size": 72,
"scheduler_size": 128,
```

- `rob_size`: Reorder Buffer - tracks up to 352 in-flight instructions
- `lq_size`: Load Queue - can track 128 pending loads
- `sq_size`: Store Queue - can track 72 pending stores
- `scheduler_size`: Reservation stations - 128 instructions waiting for execution

**Larger structures**:
- Pro: Can hold more in-flight instructions (more parallelism)
- Con: More expensive in real hardware, slightly slower

### Cache Configuration Parameters

For each cache level (L1I, L1D, L2C, LLC), you have:
```json
"sets": 64,
"ways": 12,
```

**Understanding sets and ways**:
- A cache is organized as a 2D array
- `sets`: Number of rows in the array
- `ways`: Number of columns (also called associativity)
- Total cache lines = sets × ways
- Total cache size = sets × ways × block_size

Example for your L1D:
- 64 sets × 12 ways = 768 cache lines
- 768 × 64 bytes = 49,152 bytes = 48 KB

**Why sets and ways matter**:

With 1-way (direct-mapped):
- Each memory address maps to exactly one location
- Simple and fast, but conflict misses are common

With 12-way (set-associative):
- Each memory address can go in any of 12 locations within its set
- Fewer conflict misses, but slightly slower to search

**Queue Sizes**:
```json
"rq_size": 64,
"wq_size": 64,
"pq_size": 8,
"mshr_size": 16,
```

- `rq_size`: Read queue - pending read requests
- `wq_size`: Write queue - pending write requests
- `pq_size`: Prefetch queue - pending prefetch requests
- `mshr_size`: Miss Status Holding Registers - track outstanding cache misses

**MSHR is critical**: If you have more simultaneous cache misses than MSHRs, additional misses must wait. This creates serialization.

**Latencies**:
```json
"latency": 5,
```

- How many cycles it takes to access this cache level (on a hit)
- L1D latency: 5 cycles
- L2C latency: 10 cycles  
- LLC latency: 20 cycles

**These are what you can modify for latency experiments!**

**Port Limits**:
```json
"max_tag_check": 2,
"max_fill": 2,
```

- `max_tag_check`: How many tag checks (cache lookups) per cycle
- `max_fill`: How many cache fills per cycle

**These are what you can modify for port restriction experiments!**

### Prefetcher and Replacement
```json
"prefetcher": "no",
"replacement": "lru"
```

**prefetcher**: 
- `"no"`: No prefetching (what you are using)
- Could be: `"next_line"`, `"ip_stride"`, etc.
- Prefetchers try to predict which cache lines you will need next and fetch them early

**replacement**: 
- `"lru"`: Least Recently Used (evict the line accessed longest ago)
- Could be: `"srrip"`, `"drrip"`, `"ship"`, etc.
- Determines which cache line to evict when the cache is full

### DRAM Parameters
```json
"tCAS": 24,
"tRCD": 24,
"tRP": 24,
"tRAS": 52,
```

These are DRAM timing parameters (in cycles):
- `tCAS`: CAS latency - time to access data within a row
- `tRCD`: RAS to CAS delay - time to open a row
- `tRP`: Row precharge time - time to close a row
- `tRAS`: Row active time - minimum time row must stay open

**Row buffer dynamics**:
- If accessing same row: Just pay tCAS (~24 cycles)
- If accessing different row: Pay tRP + tRCD + tCAS (~72 cycles)

This is why row buffer hit rate matters!

---

## Reading ChampSim Output

Let me teach you how to read every section of the output:

### Header Section
```
*** ChampSim Multicore Out-of-Order Simulator ***
Warmup Instructions: 10000000
Simulation Instructions: 50000000
```

This just confirms your simulation parameters. Make sure these match what you intended.

### Performance Summary
```
CPU 0 cumulative IPC: 1.276 instructions: 50000004 cycles: 39184107
```

**IPC (Instructions Per Cycle)**: The single most important metric
- Formula: IPC = Instructions / Cycles = 50,000,004 / 39,184,107 = 1.276
- Higher is better (means more work done per cycle)
- Theoretical maximum depends on core width (your execute_width is 4, so max IPC ≈ 4)

**Why 50,000,004 instead of 50,000,000?**: Rounding in the simulator. Close enough.

**Interpreting IPC**:
- IPC > 2.0: Excellent, processor is highly utilized
- IPC 1.0-2.0: Good, decent parallelism
- IPC 0.5-1.0: Moderate, some bottlenecks
- IPC < 0.5: Poor, severe bottlenecks (usually memory)

### Branch Prediction
```
CPU 0 Branch Prediction Accuracy: 94.94% MPKI: 10.44
```

**Accuracy**: Percentage of branches predicted correctly
- 94.94% means 1 in 20 branches are mispredicted
- This is quite good for the simple bimodal predictor

**MPKI**: Mispredictions Per Kilo Instructions
- 10.44 means 10.44 mispredictions per 1000 instructions
- Or about 1 misprediction per 96 instructions

**Impact on performance**:
- Each misprediction costs cycles (pipeline flush)
- Your config has `mispredict_penalty: 1` (very optimistic)
- Real processors: 15-20 cycle penalty

### Cache Statistics Format

Every cache level reports in this format:
```
cpu0->cpu0_L1D TOTAL    ACCESS:  15773301 HIT:  15628558 MISS:  144743
cpu0->cpu0_L1D LOAD     ACCESS:   8873576 HIT:   8774289 MISS:   99287
```

**Understanding the lines**:
- **TOTAL**: All accesses (loads + stores + other)
- **LOAD**: Just load instructions
- **RFO**: Read-For-Ownership (atomic operations, rare)
- **WRITE**: Store instructions
- **PREFETCH**: Prefetch requests
- **TRANSLATION**: TLB translation requests

**The math**:
```
Miss Rate = MISS / ACCESS = 99,287 / 8,873,576 = 1.12%
Hit Rate = HIT / ACCESS = 8,774,289 / 8,873,576 = 98.88%
```

**MSHR_MERGE**:
```
MSHR_MERGE: 17546
```
- These are requests that merged with existing outstanding misses
- Example: Two loads to the same cache line happen while the first is still pending
- The second "merges" - doesn't create a new DRAM request
- Higher merge counts = better (saves bandwidth)

**Average Miss Latency**:
```
cpu0->cpu0_L1D AVERAGE MISS LATENCY: 84.59 cycles
```
- When L1D misses, it takes on average 84.59 cycles to get the data
- This includes time spent in L2C, LLC, and possibly DRAM
- Compare to L1D hit latency (5 cycles): misses are 17x more expensive!

### DRAM Statistics
```
Channel 0 RQ ROW_BUFFER_HIT:        372
  ROW_BUFFER_MISS:      38076
```

**Row Buffer Hits**: 
- Data was in the currently open DRAM row
- Faster access (~tCAS = 24 cycles)

**Row Buffer Misses**:
- Had to close old row and open new row  
- Slower access (~tRP + tRCD + tCAS = 72 cycles)

**Hit Rate**: 372 / (372 + 38,076) = 0.97%
- Very low! This trace has very random memory access

**Sequential vs Random**:
- Sequential access (like streaming): High row buffer hit rate (>50%)
- Random access (like pointer chasing): Low row buffer hit rate (<5%)

### What the Numbers Tell You

Let's analyze your 400.perlbench trace:
```
IPC: 1.276 → Moderate performance
L1D Miss Rate: 1.12% → Excellent cache locality  
L2C Miss Rate: 27.53% → Fair (of the L1D misses, many also miss in L2)
LLC Miss Rate: 76.48% → Poor (of the L2C misses, most also miss in LLC)
DRAM Accesses: 31,950 → Moderate (0.064% of all loads go to DRAM)
```

**The story**: 
This program has good L1D locality (98.88% hit rate), so most memory accesses are fast. However, when it does miss in L1D, there is a good chance it will cascade all the way to DRAM (76.48% LLC miss rate). But since L1D misses are rare (only 1.12%), the overall impact on IPC is moderate.

**Contrast with 603.bwaves_s**:
```
IPC: 0.421 → Very poor performance
L1D Miss Rate: 58.86% → Terrible cache locality
LLC Miss Rate: 99.99% → Almost everything goes to DRAM
DRAM Accesses: 1,159,391 → Massive (15% of all loads!)
```

**The story**:
This program has terrible cache locality. Nearly 60% of loads miss in L1D, and almost all of those go all the way to DRAM. With 1.1 million DRAM accesses at ~250 cycles each, you are spending ~275 million cycles just waiting for DRAM out of 119 million total cycles. The processor is idle most of the time waiting for memory.

---

## What You Can Modify and Study

### 1. Cache Sizes

**What to change**:
```json
"L1D": {
    "sets": 64,    // Change to 128 to double cache size
    "ways": 12,    // Or change to 24 to double cache size
```

**Effect**: 
- Larger cache → Lower miss rate → Better performance (for memory-bound workloads)
- Diminishing returns: First doubling helps most

**How to measure impact**:
- Compare miss rates and IPC before/after
- Calculate: (IPC_new - IPC_old) / IPC_old × 100 = Performance improvement %

**Best workloads to test**: Memory-bound traces (603.bwaves_s)

### 2. Cache Latency

**What to change**:
```json
"L1D": {
    "latency": 5,    // Change to 10 to make L1D slower
```

**Effect**:
- Higher latency → Every cache access takes longer → Lower IPC
- Impact depends on hit rate: High hit rate × high latency = big impact

**Best workloads to test**: 
- High impact: Compute-bound traces with high L1D hit rates (410.bwaves)
- Low impact: Memory-bound traces already waiting on DRAM (603.bwaves_s)

### 3. Cache Associativity

**What to change**:
```json
"L1D": {
    "ways": 12,    // Change to 8 (less associative) or 16 (more associative)
```

**Effect**:
- Lower ways → More conflict misses → Higher miss rate
- Higher ways → Fewer conflicts, but slower lookup, more expensive hardware

**Study question**: "What is the sweet spot for associativity?"

### 4. Cache Ports (max_tag_check, max_fill)

**What to change**:
```json
"L1D": {
    "max_tag_check": 2,    // Change to 1 to limit ports
    "max_fill": 2,         // Change to 1 to limit ports
```

**Effect**:
- Lower values → Can service fewer requests per cycle → Creates bottleneck
- Especially impacts high-IPC workloads that make many cache accesses per cycle

**Best workloads**: Compute-bound traces with high IPC (410.bwaves, 416.gamess)

### 5. Pipeline Width and Structures

**What to change**:
```json
"execute_width": 4,    // Execution ports (try 2, 4, 8)
"rob_size": 352,       // Reorder buffer (try 128, 256, 512)
"lq_size": 128,        // Load queue
"sq_size": 72,         // Store queue
```

**Effects**:
- Narrower pipeline → Lower max IPC
- Smaller structures → Less in-flight instructions → Less parallelism
- Larger structures → Can exploit more parallelism (if present in code)

### 6. Prefetchers

**What to change**:
```json
"prefetcher": "no"    // Try: "next_line", "ip_stride", "spp_dev"
```

**Effect**:
- Prefetchers predict what data you will need and fetch it early
- Good prefetchers → Lower effective miss rate → Better performance
- Bad prefetchers → Waste bandwidth → Worse performance

**Study questions**:
- Which traces benefit from prefetching?
- Which prefetcher is best for which access pattern?

### 7. Replacement Policies

**What to change**:
```json
"replacement": "lru"    // Try: "srrip", "drrip", "ship"
```

**Effect**:
- Determines which cache line to evict when cache is full
- Better policies → Keep more useful data → Lower miss rate

**Advanced replacement policies**:
- LRU: Evict least recently used (simple, often good)
- SRRIP: Scan-Resistant Insertion Policy (better for streaming)
- SHIP: Signature-based Hit Predictor (adaptive)

### 8. DRAM Timing

**What to change**:
```json
"tCAS": 24,    // Try higher values to simulate slower DRAM
```

**Effect**:
- Higher timing → DRAM accesses take longer → Worse performance
- Impact depends on DRAM access frequency

**Best workloads**: Memory-bound traces with many DRAM accesses

---

## Performance Metrics Explained

### IPC (Instructions Per Cycle)

**Formula**: IPC = Instructions Executed / Cycles Taken

**Interpretation**:
- IPC = 4.0: Perfect! Using all 4 execution ports every cycle
- IPC = 2.0: Good parallelism, using half the ports on average
- IPC = 1.0: Executing one instruction per cycle (serial execution)
- IPC = 0.5: Processor idle half the time (waiting for something)

**What limits IPC?**
1. **Data dependencies**: Instruction B needs result of instruction A
2. **Memory latency**: Waiting for cache misses
3. **Branch mispredictions**: Flushing wrong-path instructions
4. **Structural hazards**: Not enough execution ports or queue slots

**Your traces**:
- 410.bwaves (IPC=3.08): Lots of parallelism, minimal dependencies
- 603.bwaves_s (IPC=0.42): Waiting on memory most of the time

### Miss Rate

**Formula**: Miss Rate = Misses / Total Accesses × 100%

**L1D Miss Rates**:
- <1%: Excellent locality
- 1-5%: Good locality
- 5-20%: Moderate locality
- >20%: Poor locality

**Why miss rate matters more than miss count**:
- 1000 misses out of 1,000,000 accesses (0.1%) → Minimal impact
- 1000 misses out of 10,000 accesses (10%) → Huge impact

### CPI (Cycles Per Instruction)

**Formula**: CPI = Cycles / Instructions = 1 / IPC

**Interpretation**: 
- How many cycles each instruction costs on average
- CPI = 0.5 means 0.5 cycles per instruction (same as IPC = 2.0)

**CPI is often used in academic papers, IPC is more intuitive for students.**

### MPKI (Misses Per Kilo Instructions)

**Formula**: MPKI = (Misses / Instructions) × 1000

**Example**: 
- 50,000 cache misses in 10,000,000 instructions
- MPKI = (50,000 / 10,000,000) × 1000 = 5.0

**Interpretation**:
- MPKI = 5.0 means 5 misses per 1000 instructions
- Lower is better

**Why useful?**: 
- Normalizes across different trace lengths
- Easy to compare different benchmarks

### Memory Level Parallelism (MLP)

**Not directly reported but inferable**:
- Look at MSHR_MERGE counts
- High merges → Multiple outstanding misses → High MLP
- Low merges → Misses happen serially → Low MLP

**Why it matters**:
- High MLP: Processor can overlap multiple DRAM accesses
- Low MLP: Processor waits for each DRAM access serially

### Bandwidth Utilization

**Inferred from**:
- DRAM row buffer hits/misses
- Total DRAM accesses
- Average access size

**Your 603.bwaves_s**:
- 1.1M DRAM accesses × 64 bytes = ~70 MB of data transferred
- Over 119M cycles at 4 GHz = ~30 milliseconds
- Bandwidth used: ~2.3 GB/s

---

## Common Experiments and Their Purpose

### Experiment 1: Cache Sensitivity Study

**Goal**: Understand how cache size affects performance

**Method**:
1. Run baseline with current cache sizes
2. Double L1D size (sets: 64→128)
3. Double L2C size (sets: 1024→2048)
4. Double LLC size (sets: 2048→4096)
5. Compare IPC and miss rates

**Expected results**:
- Memory-bound traces: Large IPC improvement
- Compute-bound traces: Minimal IPC improvement

**Why this matters**: 
- Real hardware: Caches are expensive (area, power)
- Need to find sweet spot: Best performance per dollar

### Experiment 2: Latency Impact Study

**Goal**: Quantify sensitivity to memory latency

**Method**:
1. Baseline: L1D latency=5, L2C latency=10
2. Config 1: L1D latency=10 (2x slower)
3. Config 2: L2C latency=20 (2x slower)
4. Config 3: Both increased

**Expected results**:
- High L1D hit rate workloads: Very sensitive to L1D latency
- High L1D miss rate workloads: More sensitive to L2C/LLC latency

**Real-world application**:
- New technology might have higher latency (e.g., new materials)
- Need to understand performance impact before adopting

### Experiment 3: Port Restriction Study

**Goal**: Study impact of cache port limitations

**Method**:
1. Baseline: max_tag_check=2, max_fill=2
2. Restricted: max_tag_check=1, max_fill=1
3. Compare high-IPC vs low-IPC workloads

**Expected results**:
- High-IPC workloads (410.bwaves): Significant slowdown
- Low-IPC workloads (603.bwaves_s): Minimal impact

**Why this matters**:
- More cache ports = more expensive hardware
- Understand: Is the extra cost worth it?

### Experiment 4: Prefetcher Effectiveness

**Goal**: Evaluate different prefetcher designs

**Method**:
1. Baseline: no prefetcher
2. Config 1: next_line prefetcher
3. Config 2: ip_stride prefetcher
4. Measure: Miss rate reduction, bandwidth increase

**Expected results**:
- Sequential access patterns: next_line helps
- Stride patterns: ip_stride helps
- Random patterns: Prefetching may hurt (wasted bandwidth)

### Experiment 5: Replacement Policy Comparison

**Goal**: Find best replacement policy for different workloads

**Method**:
1. LRU baseline
2. Try SRRIP, DRRIP, SHIP
3. Compare miss rates

**Expected results**:
- LRU: Good for most workloads
- SRRIP: Better for scan-resistant (streaming) workloads
- SHIP: Best for mixed access patterns

---

## Advanced Topics: sLDM and Custom Instrumentation

### What is sLDM?

**sLDM** = Store-Load Dependence Management

This refers to how the processor handles situations where a load instruction needs data that a previous store instruction is writing.

### The Problem

Consider this code:
```c
store: memory[0x1000] = 42;    // Write 42 to address 0x1000
load:  x = memory[0x1000];      // Read from address 0x1000
```

**If executed in order**: No problem, load gets the correct value (42)

**In an out-of-order processor**:
- Load might execute before the store finishes
- Load might read old value (wrong!)
- Processor must detect and prevent this

### How Processors Handle This

**Store Queue (SQ)**:
- Holds pending stores that haven't committed to memory yet
- Stores sit here until they are safe to commit

**Load Queue (LQ)**:
- Holds pending loads
- Each load checks: "Is there a pending store to my address?"

**Store-to-Load Forwarding**:
- If load address matches pending store address → Forward data directly from SQ
- Fast! Bypasses cache
- Your config: `sq_size: 72` can hold 72 pending stores

**Memory Ordering Violations**:
- Sometimes processor guesses wrong about dependencies
- Load executes, then older store to same address is discovered
- Must replay the load (flush pipeline, re-execute)
- Expensive! (~20+ cycle penalty)

### What to Instrument for sLDM Study

To understand sLDM behavior, track:

1. **Store-to-load forwards**: 
   - Count: How many loads got data from store queue?
   - Latency: How long did forwarding take?

2. **Load replays**:
   - Count: How many loads had to replay due to dependency violations?
   - Cause: Why did the violation happen?

3. **Store queue occupancy**:
   - Average: How full is the store queue?
   - Max: What is the peak occupancy?

4. **Forwarding distance**:
   - How many instructions between the store and dependent load?

### Where to Add Instrumentation

**In ChampSim source code**, you would modify:

**File: `src/ooo_cpu.cc`**
- Look for load/store queue operations
- Add counters for forwards and replays

**File: `inc/ooo_cpu.h`**  
- Add member variables for statistics

**Example pseudo-code**:
```cpp
// In ooo_cpu.h
class O3_CPU {
    uint64_t store_to_load_forwards = 0;
    uint64_t memory_order_violations = 0;
    uint64_t total_sq_occupancy = 0;
    uint64_t sq_samples = 0;
};

// In ooo_cpu.cc, when processing a load
if (load_forwarded_from_store_queue) {
    store_to_load_forwards++;
    // Track latency, distance, etc.
}

if (memory_ordering_violation_detected) {
    memory_order_violations++;
    // Replay the load
}

// Periodically sample store queue
total_sq_occupancy += current_sq_size;
sq_samples++;

// At end of simulation
cout << "Store-to-load forwards: " << store_to_load_forwards << endl;
cout << "Avg SQ occupancy: " << (total_sq_occupancy / sq_samples) << endl;
```

### Experiments with sLDM

**Experiment idea**:
1. Vary store queue size (sq_size: 36, 72, 144)
2. Measure impact on forwards and violations
3. Determine: What is the optimal SQ size?

**Expected findings**:
- Larger SQ → More forwarding opportunities
- But: Diminishing returns after a point
- Trade-off: Hardware cost vs. performance

---

## Troubleshooting and Tips

### Common Build Errors

**Error: "fatal error: cache.h: No such file or directory"**

**Cause**: Configuration didn't generate header files

**Solution**:
```bash
make clean
rm -rf .csconfig
./config.sh champsim_config.json
make
```

**Error: "vcpkg not found"**

**Cause**: Dependency manager not set up

**Solution**:
```bash
git submodule update --init
./vcpkg/bootstrap-vcpkg.sh
./vcpkg/vcpkg install
```

### Simulation Running Slow

**If your simulation is taking forever**:

1. **Reduce instruction count**:
   - Warmup: 1M instead of 10M
   - Simulation: 10M instead of 50M
   - Still gives directional results

2. **Use smaller traces**:
   - Look for traces with smaller numbers (e.g., 400.perlbench-41B instead of 400.perlbench-210B)

3. **Disable detailed output**:
   - ChampSim prints heartbeats every 10M instructions
   - This is just for monitoring, doesn't affect results

### Understanding Unexpected Results

**IPC didn't change when you modified something**:

Possible reasons:
1. **Different bottleneck**: Changed cache size, but workload is compute-bound
2. **Already sufficient**: L1D already big enough, making it bigger doesn't help
3. **Simulation variance**: Try longer simulation (more instructions)

**Miss rate increased when you made cache bigger**:

This shouldn't happen! Check:
1. Did you rebuild? (`make clean && make`)
2. Did you use the right config file?
3. Is the trace the same?

### Best Practices

**Always**:
1. Save your results with descriptive names
2. Document what config you used
3. Run baseline first, then compare changes
4. Keep warmup instructions (don't skip warmup!)

**Never**:
1. Compare results from different traces directly
2. Modify config without rebuilding
3. Draw conclusions from just one trace
4. Ignore the warmup phase

### Making Good Comparisons

**Good comparison**:
```
Baseline: 603.bwaves_s, L1D=48KB, IPC=0.421
Modified: 603.bwaves_s, L1D=96KB, IPC=0.512
Conclusion: Doubling L1D improved IPC by 21.6%
```

**Bad comparison**:
```
Trace A: IPC=1.5
Trace B: IPC=0.8
Conclusion: Trace A is "better"
```

**Why bad?**: Different traces have different characteristics. IPC comparison only meaningful for same trace with different configs.

### Interpreting Results

**When cache latency matters**:
- Workload has high cache hit rate
- Latency directly impacts many instructions
- Example: 410.bwaves (99.999% L1D hit rate, so L1D latency critical)

**When cache latency doesn't matter**:
- Workload already waiting on DRAM
- Cache latency is tiny compared to DRAM latency
- Example: 603.bwaves_s (58% L1D miss rate, DRAM latency dominates)

**When cache size matters**:
- Workload has moderate miss rate (5-30%)
- Working set slightly bigger than cache
- Example: 401.bzip2 (5.91% miss rate, could benefit from larger cache)

**When cache size doesn't matter**:
- Working set much smaller than cache (already fits)
- Or working set much larger than cache (won't fit even if doubled)

---

## Conclusion and Next Steps

You have now learned:
- ✅ What ChampSim simulates and why
- ✅ How trace-based simulation works
- ✅ Every component of the simulated processor
- ✅ How to read and interpret output
- ✅ What parameters you can modify
- ✅ How to design meaningful experiments
- ✅ How to troubleshoot issues

### Your Journey So Far

1. ✅ Set up ChampSim from scratch
2. ✅ Downloaded and ran multiple traces
3. ✅ Characterized traces (memory-bound vs compute-bound)
4. ✅ Created analysis scripts
5. ✅ Learned to read output deeply

### Suggested Next Experiments

**Week 1**: Cache size sensitivity
- Run baseline
- Run with 2x L1D, 2x L2C, 2x LLC
- Analyze which traces are most sensitive

**Week 2**: Latency impact
- Test different latency values
- Compare memory-bound vs compute-bound responses

**Week 3**: Advanced (sLDM)
- Add instrumentation to track store-load forwarding
- Vary store queue size
- Analyze impact on performance

### Going Deeper

**To learn more**:
1. Read the ChampSim GitHub wiki
2. Study SPEC CPU benchmark descriptions
3. Read papers that use ChampSim (check PUBLICATIONS_USING_CHAMPSIM.bib)
4. Look at source code in `src/` and `inc/` directories

**To contribute**:
1. Implement a new prefetcher
2. Implement a new replacement policy
3. Add new instrumentation
4. Share your findings!

### Remember

ChampSim is a tool for learning and exploration. Don't be afraid to:
- Modify things and see what happens
- Break things (you can always re-clone)
- Ask "what if?" questions
- Compare your results with others

**The best way to learn computer architecture is to experiment!**

---

**End of Guide**

*This guide was created as a comprehensive learning resource. Keep it handy, refer to it often, and use it as a springboard for your own experiments and discoveries.*