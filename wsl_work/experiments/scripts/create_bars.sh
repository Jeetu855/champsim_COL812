#!/bin/bash

ANALYSIS_DIR="$HOME/champsim_fresh/ChampSim/experiments/analysis"
RESULTS_DIR="$HOME/champsim_fresh/ChampSim/experiments/results/baseline"

echo "================================================================================"
echo "                         VISUAL TRACE COMPARISON"
echo "================================================================================"
echo ""

# IPC Comparison
echo "IPC COMPARISON (Instructions Per Cycle - Higher is Better)"
echo "--------------------------------------------------------------------------------"

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    IPC=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*IPC: //' | awk '{print $1}')
    
    if [ -n "$IPC" ]; then
        # Scale IPC to bar length (multiply by 20 for visualization)
        bar_length=$(awk "BEGIN {printf \"%.0f\", ($IPC * 20)}")
        bar=$(printf '█%.0s' $(seq 1 $bar_length 2>/dev/null))
        printf "%-30s %6s |%-60s|\n" "$trace_name" "$IPC" "$bar"
    fi
done | sort -k2 -rn

echo ""
echo "L1D MISS RATE COMPARISON (Lower is Better)"
echo "--------------------------------------------------------------------------------"

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    
    L1D_ACCESS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L1D_MISS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    if [ -n "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ] 2>/dev/null; then
        L1D_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L1D_MISS * 100.0 / $L1D_ACCESS)}")
        # Scale miss rate (divide by 2 for better visualization)
        bar_length=$(awk "BEGIN {printf \"%.0f\", ($L1D_MISS_RATE / 2)}")
        bar=$(printf '█%.0s' $(seq 1 $bar_length 2>/dev/null))
        printf "%-30s %6s%% |%-60s|\n" "$trace_name" "$L1D_MISS_RATE" "$bar"
    fi
done | sort -k2 -rn

echo ""
echo "DRAM ACCESS INTENSITY (Number of DRAM Accesses)"
echo "--------------------------------------------------------------------------------"

# First pass: find max DRAM accesses for scaling
max_dram=0
for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    LLC_MISS=$(grep "^cpu0->LLC LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    if [ -n "$LLC_MISS" ] && [ "$LLC_MISS" -gt "$max_dram" ] 2>/dev/null; then
        max_dram=$LLC_MISS
    fi
done

# Second pass: create bars
for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    LLC_MISS=$(grep "^cpu0->LLC LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    if [ -n "$LLC_MISS" ] && [ "$max_dram" -gt 0 ] 2>/dev/null; then
        # Scale to 60 characters max
        bar_length=$(awk "BEGIN {printf \"%.0f\", ($LLC_MISS * 60.0 / $max_dram)}")
        bar=$(printf '█%.0s' $(seq 1 $bar_length 2>/dev/null))
        printf "%-30s %10s |%-60s|\n" "$trace_name" "$LLC_MISS" "$bar"
    fi
done | sort -k2 -rn

echo ""
echo "CYCLES COMPARISON (Lower is Better for same instruction count)"
echo "--------------------------------------------------------------------------------"

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    CYCLES=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*cycles: //' | awk '{print $1}')
    
    if [ -n "$CYCLES" ]; then
        # Scale cycles (divide by 2M for visualization)
        bar_length=$(awk "BEGIN {printf \"%.0f\", ($CYCLES / 2000000)}")
        bar=$(printf '█%.0s' $(seq 1 $bar_length 2>/dev/null))
        printf "%-30s %12s |%-60s|\n" "$trace_name" "$CYCLES" "$bar"
    fi
done | sort -k2 -rn

echo ""
echo "================================================================================"
echo "Legend:"
echo "  █ = Visual representation scaled for comparison"
echo "  Sorted from highest to lowest value in each category"
echo "================================================================================"