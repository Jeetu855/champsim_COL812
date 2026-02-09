#!/bin/bash

RESULTS_DIR="$HOME/champsim_fresh/ChampSim/experiments/results"
ANALYSIS_DIR="$HOME/champsim_fresh/ChampSim/experiments/analysis"

# Create CSV header
echo "Experiment,Trace,IPC,L1D_Miss_Rate,L2C_Miss_Rate,LLC_Miss_Rate,DRAM_Accesses,Cycles,Instructions" > $ANALYSIS_DIR/summary.csv

# Function to extract metrics from a result file
extract_metrics() {
    local file=$1
    local exp_name=$2
    local trace_name=$3
    
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return
    fi
    
    # Extract IPC
    IPC=$(grep "cumulative IPC:" $file | tail -1 | awk '{print $4}')
    
    # Extract cycles and instructions
    CYCLES=$(grep "cumulative IPC:" $file | tail -1 | awk '{print $6}')
    INSTRUCTIONS=$(grep "cumulative IPC:" $file | tail -1 | awk '{print $3}')
    
    # Extract L1D stats
    L1D_ACCESS=$(grep "cpu0->cpu0_L1D LOAD" $file | awk '{print $3}')
    L1D_MISS=$(grep "cpu0->cpu0_L1D LOAD" $file | awk '{print $5}')
    
    # Calculate L1D miss rate
    if [ ! -z "$L1D_ACCESS" ] && [ "$L1D_ACCESS" -gt 0 ]; then
        L1D_MISS_RATE=$(echo "scale=4; $L1D_MISS / $L1D_ACCESS * 100" | bc)
    else
        L1D_MISS_RATE="N/A"
    fi
    
    # Extract L2C stats
    L2C_ACCESS=$(grep "cpu0->cpu0_L2C LOAD" $file | awk '{print $3}')
    L2C_MISS=$(grep "cpu0->cpu0_L2C LOAD" $file | awk '{print $5}')
    
    if [ ! -z "$L2C_ACCESS" ] && [ "$L2C_ACCESS" -gt 0 ]; then
        L2C_MISS_RATE=$(echo "scale=4; $L2C_MISS / $L2C_ACCESS * 100" | bc)
    else
        L2C_MISS_RATE="N/A"
    fi
    
    # Extract LLC stats
    LLC_ACCESS=$(grep "cpu0->LLC LOAD" $file | awk '{print $3}')
    LLC_MISS=$(grep "cpu0->LLC LOAD" $file | awk '{print $5}')
    
    if [ ! -z "$LLC_ACCESS" ] && [ "$LLC_ACCESS" -gt 0 ]; then
        LLC_MISS_RATE=$(echo "scale=4; $LLC_MISS / $LLC_ACCESS * 100" | bc)
    else
        LLC_MISS_RATE="N/A"
    fi
    
    # Extract DRAM accesses (from LLC misses)
    DRAM_ACCESSES=${LLC_MISS:-"N/A"}
    
    # Write to CSV
    echo "$exp_name,$trace_name,$IPC,$L1D_MISS_RATE,$L2C_MISS_RATE,$LLC_MISS_RATE,$DRAM_ACCESSES,$CYCLES,$INSTRUCTIONS" >> $ANALYSIS_DIR/summary.csv
}

# Process all result files
for exp_dir in $RESULTS_DIR/*/; do
    exp_name=$(basename $exp_dir)
    echo "Processing experiment: $exp_name"
    
    for result_file in $exp_dir/*.txt; do
        if [ -f "$result_file" ]; then
            trace_name=$(basename $result_file .txt)
            echo "  Extracting: $trace_name"
            extract_metrics $result_file $exp_name $trace_name
        fi
    done
done

echo ""
echo "Summary saved to: $ANALYSIS_DIR/summary.csv"
echo ""
echo "Quick view:"
column -t -s',' $ANALYSIS_DIR/summary.csv | head -20