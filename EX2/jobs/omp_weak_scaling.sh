#!/bin/bash
#SBATCH --job-name=omp_weak_scaling
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=01:40:00
#SBATCH --partition=EPYC
#SBATCH --exclusive
#SBATCH --output=omp_weak_scaling_%j.out
#SBATCH --error=omp_weak_scaling_%j.err

module purge
module load openMPI/4.1.6

# Paths
EXECUTABLE=../base/mandelbrot
OUTPUT_CSV=../results/omp_weak_scaling.csv

# Image output (only one, overwritten)
PLOT="../base/mandelbrot.pgm"

# Constants
X_LEFT=-2.0
Y_LOWER=-1.0
X_RIGHT=1.0
Y_UPPER=1.0
IMAX=255
C=1000000

# Prepare CSV
echo "threads,width,height,compute_time,io_time,total_time" > "$OUTPUT_CSV"

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export OMP_WAIT_POLICY=active

# Loop from 1 to 128 threads
for THREADS in {1..128}; do
    export OMP_NUM_THREADS=$THREADS
    n=$(echo "scale=0; sqrt($THREADS * $C)" | bc)
    
    echo "Running with $THREADS threads on ${n}x${n} image..."

    OUTPUT=$($EXECUTABLE $n $n $X_LEFT $Y_LOWER $X_RIGHT $Y_UPPER $IMAX $THREADS)

    compute_time=$(echo "$OUTPUT" | grep "Compute time:" | awk '{print $3}')
    io_time=$(echo "$OUTPUT" | grep "I/O time:" | awk '{print $3}')
    total_time=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}')

    echo "$THREADS,$n,$n,$compute_time,$io_time,$total_time" >> "$OUTPUT_CSV"
    
    sleep 1  # Optional: short delay to stabilize
done

echo "OMP weak scaling test complete."
echo "Results saved to: $OUTPUT_CSV"
