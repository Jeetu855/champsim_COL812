#!/bin/bash

# Configuration
CHAMPSIM_DIR="$HOME/champsim_fresh/ChampSim"
TRACE_DIR="$HOME/traces"
RESULTS_DIR="$CHAMPSIM_DIR/experiments/results"
CONFIGS_DIR="$CHAMPSIM_DIR/experiments/configs"

# Simulation parameters
WARMUP=10000000      # 10M instructions
SIM=50000000         # 50M instructions

# List of traces
TRACES=(
    "400.perlbench-41B.champsimtrace.xz"
    "401.bzip2-226B.champsimtrace.xz"
    "410.bwaves-945B.champsimtrace.xz"
    "416.gamess-875B.champsimtrace.xz"
    "603.bwaves_s-891B.champsimtrace.xz"
)

# List of experiments
EXPERIMENTS=(
    "baseline"
    # Add more as we create configs
)

echo "========================================="
echo "ChampSim Experiment Runner"
echo "========================================="
echo ""
echo "Traces to run: ${#TRACES[@]}"
echo "Experiments: ${#EXPERIMENTS[@]}"
echo "Warmup: $WARMUP instructions"
echo "Simulation: $SIM instructions"
echo ""

# Function to run a single experiment
run_experiment() {
    local exp_name=$1
    local trace_file=$2
    local trace_name=$(basename $trace_file .champsimtrace.xz)
    
    echo "-----------------------------------"
    echo "Experiment: $exp_name"
    echo "Trace: $trace_name"
    echo "-----------------------------------"
    
    # Configure and build
    cd $CHAMPSIM_DIR
    ./config.sh $CONFIGS_DIR/${exp_name}.json
    make clean > /dev/null 2>&1
    make -j4
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed for $exp_name"
        return 1
    fi
    
    # Run simulation
    OUTPUT_FILE="$RESULTS_DIR/${exp_name}/${trace_name}.txt"
    START_TIME=$(date +%s)
    
    echo "Running simulation..."
    ./bin/champsim \
        --warmup-instructions $WARMUP \
        --simulation-instructions $SIM \
        $TRACE_DIR/$trace_file > $OUTPUT_FILE 2>&1
    
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    
    echo "Completed in ${ELAPSED} seconds"
    echo "Output saved to: $OUTPUT_FILE"
    echo ""
}

# Main execution loop
for exp in "${EXPERIMENTS[@]}"; do
    echo "========================================"
    echo "Starting experiment: $exp"
    echo "========================================"
    echo ""
    
    for trace in "${TRACES[@]}"; do
        run_experiment $exp $trace
    done
done

echo "========================================="
echo "All experiments completed!"
echo "========================================="