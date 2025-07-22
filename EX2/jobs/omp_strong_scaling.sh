#!/bin/bash
#SBATCH --job-name=hpcos 
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --time=01:30:00
#SBATCH --partition=EPYC
#SBATCH --exclusive
#SBATCH --output=omp_strong_scaling_%j.out
#SBATCH --error=omp_strong_scaling_%j.err

module purge
module load openMPI/4.1.6

# Paths
EXECUTABLE=../base/mandelbrot
OUTPUT_CSV=../results/omp_strong_scaling_10.csv
PLOT_NAME="../base/mandelbrot.pgm"  # Overwrites the same image every time

# Parameters for Mandelbrot set
WIDTH=10000
HEIGHT=10000
X_LEFT=-2.0
Y_LOWER=-1.0
X_RIGHT=1.0
Y_UPPER=1.0
IMAX=255

# Output header
echo "threads,width,height,compute_time,io_time,total_time" > "$OUTPUT_CSV"

# Run loop for 1 to 128 threads
for THREADS in {1..128}; do
    echo "Running with $THREADS threads..."
    export OMP_NUM_THREADS=$THREADS
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

    OUTPUT=$($EXECUTABLE $WIDTH $HEIGHT $X_LEFT $Y_LOWER $X_RIGHT $Y_UPPER $IMAX $THREADS)

    compute_time=$(echo "$OUTPUT" | grep "Compute time:" | awk '{print $3}')
    io_time=$(echo "$OUTPUT" | grep "I/O time:" | awk '{print $3}')
    total_time=$(echo "$OUTPUT" | grep "Total time:" | awk '{print $3}')

    echo "$THREADS,$WIDTH,$HEIGHT,$compute_time,$io_time,$total_time" >> "$OUTPUT_CSV"
done

echo "OpenMP strong scaling test completed."
echo "Results saved to: $OUTPUT_CSV"
