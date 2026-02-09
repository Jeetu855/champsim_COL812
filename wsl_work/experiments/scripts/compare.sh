#!/bin/bash

RESULTS_DIR="$HOME/champsim_fresh/ChampSim/experiments/results/baseline"
ANALYSIS_DIR="$HOME/champsim_fresh/ChampSim/experiments/analysis"

mkdir -p $ANALYSIS_DIR
SUMMARY_FILE="$ANALYSIS_DIR/trace_summary.txt"

cat > $SUMMARY_FILE << 'EOF'
================================================================================
                    CHAMPSIM TRACE CHARACTERIZATION SUMMARY
================================================================================

PERFORMANCE OVERVIEW
===================================================================================
Trace                               IPC       Cycles        Instr  Classification
===================================================================================
EOF

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    
    # Extract performance metrics - get the actual numbers after the labels
    IPC=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*IPC: //' | awk '{print $1}')
    INSTR=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*instructions: //' | awk '{print $1}')
    CYCLES=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*cycles: //' | awk '{print $1}')
    
    # Extract L1D stats - get numbers from the LOAD line
    L1D_ACCESS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L1D_MISS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    # Calculate miss rate
    if [ -n "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ] 2>/dev/null; then
        L1D_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L1D_MISS * 100.0 / $L1D_ACCESS)}")
    else
        L1D_MISS_RATE="0.00"
    fi
    
    # Classify
    if [ -n "$IPC" ] && [ -n "$L1D_MISS_RATE" ]; then
        IS_LOW_IPC=$(awk "BEGIN {print ($IPC < 0.8) ? 1 : 0}")
        IS_HIGH_MISS=$(awk "BEGIN {print ($L1D_MISS_RATE > 20) ? 1 : 0}")
        IS_HIGH_IPC=$(awk "BEGIN {print ($IPC > 1.5) ? 1 : 0}")
        IS_LOW_MISS=$(awk "BEGIN {print ($L1D_MISS_RATE < 5) ? 1 : 0}")
        
        if [ "$IS_LOW_IPC" -eq 1 ] || [ "$IS_HIGH_MISS" -eq 1 ]; then
            CLASS="Memory-bound"
        elif [ "$IS_HIGH_IPC" -eq 1 ] && [ "$IS_LOW_MISS" -eq 1 ]; then
            CLASS="Compute-bound"
        else
            CLASS="Balanced"
        fi
    else
        CLASS="Unknown"
    fi
    
    printf "%-30s %8s %12s %12s %15s\n" "$trace_name" "$IPC" "$CYCLES" "$INSTR" "$CLASS" >> $SUMMARY_FILE
done

cat >> $SUMMARY_FILE << 'EOF'

CACHE HIERARCHY ANALYSIS
===================================================================================
Trace                           L1D Miss%  L2C Miss%  LLC Miss%     DRAM Acc
===================================================================================
EOF

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    
    # L1D
    L1D_ACCESS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L1D_MISS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    [ -n "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ] 2>/dev/null && \
        L1D_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L1D_MISS * 100.0 / $L1D_ACCESS)}") || L1D_MISS_RATE="0.00"
    
    # L2C
    L2C_ACCESS=$(grep "^cpu0->cpu0_L2C LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L2C_MISS=$(grep "^cpu0->cpu0_L2C LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    [ -n "$L2C_ACCESS" ] && [ "$L2C_ACCESS" -gt 0 ] 2>/dev/null && \
        L2C_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L2C_MISS * 100.0 / $L2C_ACCESS)}") || L2C_MISS_RATE="0.00"
    
    # LLC
    LLC_ACCESS=$(grep "^cpu0->LLC LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    LLC_MISS=$(grep "^cpu0->LLC LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    [ -n "$LLC_ACCESS" ] && [ "$LLC_ACCESS" -gt 0 ] 2>/dev/null && \
        LLC_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($LLC_MISS * 100.0 / $LLC_ACCESS)}") || LLC_MISS_RATE="0.00"
    
    DRAM_ACC=${LLC_MISS:-"0"}
    
    printf "%-30s %9s%% %9s%% %9s%% %12s\n" "$trace_name" "$L1D_MISS_RATE" "$L2C_MISS_RATE" "$LLC_MISS_RATE" "$DRAM_ACC" >> $SUMMARY_FILE
done

cat >> $SUMMARY_FILE << 'EOF'

DETAILED BREAKDOWN
===================================================================================
EOF

for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    
    echo "" >> $SUMMARY_FILE
    echo "Trace: $trace_name" >> $SUMMARY_FILE
    echo "-------------------" >> $SUMMARY_FILE
    
    IPC=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*IPC: //' | awk '{print $1}')
    L1D_ACCESS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L1D_MISS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    LLC_MISS=$(grep "^cpu0->LLC LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    [ -n "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ] 2>/dev/null && \
        L1D_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L1D_MISS * 100.0 / $L1D_ACCESS)}") || L1D_MISS_RATE="0.00"
    
    echo "  IPC: $IPC" >> $SUMMARY_FILE
    echo "  L1D: $L1D_ACCESS accesses, $L1D_MISS misses ($L1D_MISS_RATE% miss rate)" >> $SUMMARY_FILE
    echo "  DRAM accesses: $LLC_MISS" >> $SUMMARY_FILE
done

cat >> $SUMMARY_FILE << 'EOF'

===================================================================================
CLASSIFICATION & RECOMMENDATIONS
===================================================================================

EOF

# Classify and recommend
for result in $RESULTS_DIR/*.txt; do
    [ ! -f "$result" ] && continue
    
    trace_name=$(basename "$result" .txt)
    
    IPC=$(grep "CPU 0 cumulative IPC:" "$result" | tail -1 | sed 's/.*IPC: //' | awk '{print $1}')
    L1D_ACCESS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*ACCESS: *//' | awk '{print $1}')
    L1D_MISS=$(grep "^cpu0->cpu0_L1D LOAD" "$result" | sed 's/.*MISS: *//' | awk '{print $1}')
    
    [ -n "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ] 2>/dev/null && \
        L1D_MISS_RATE=$(awk "BEGIN {printf \"%.2f\", ($L1D_MISS * 100.0 / $L1D_ACCESS)}") || L1D_MISS_RATE="0.00"
    
    if [ -n "$IPC" ]; then
        IS_LOW_IPC=$(awk "BEGIN {print ($IPC < 0.8) ? 1 : 0}")
        IS_HIGH_MISS=$(awk "BEGIN {print ($L1D_MISS_RATE > 20) ? 1 : 0}")
        IS_HIGH_IPC=$(awk "BEGIN {print ($IPC > 1.5) ? 1 : 0}")
        IS_LOW_MISS=$(awk "BEGIN {print ($L1D_MISS_RATE < 5) ? 1 : 0}")
        
        if [ "$IS_LOW_IPC" -eq 1 ] || [ "$IS_HIGH_MISS" -eq 1 ]; then
            echo "$trace_name: MEMORY-BOUND (IPC=$IPC, L1D Miss=$L1D_MISS_RATE%)" >> $SUMMARY_FILE
            echo "  → Use for: Cache latency, DRAM timing, prefetcher studies" >> $SUMMARY_FILE
        elif [ "$IS_HIGH_IPC" -eq 1 ] && [ "$IS_LOW_MISS" -eq 1 ]; then
            echo "$trace_name: COMPUTE-BOUND (IPC=$IPC, L1D Miss=$L1D_MISS_RATE%)" >> $SUMMARY_FILE
            echo "  → Use for: Pipeline, port restrictions, branch prediction" >> $SUMMARY_FILE
        else
            echo "$trace_name: BALANCED (IPC=$IPC, L1D Miss=$L1D_MISS_RATE%)" >> $SUMMARY_FILE
            echo "  → Use for: General studies, shows both effects" >> $SUMMARY_FILE
        fi
        echo "" >> $SUMMARY_FILE
    fi
done

echo "====================================================================================" >> $SUMMARY_FILE

echo ""
echo "Summary created: $SUMMARY_FILE"
echo ""
cat $SUMMARY_FILE