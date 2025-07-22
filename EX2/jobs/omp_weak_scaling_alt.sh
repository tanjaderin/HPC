#!/bin/bash
#SBATCH --job-name=hpc
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=128
#SBATCH --output=omp_weak_alt.%j.out
#SBATCH --error=omp_weak_alt.%j.err
#SBATCH --time=02:00:00
#SBATCH --partition=EPYC
#SBATCH --exclusive

module load openMPI/4.1.6

# Check if module loaded successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to load OpenMPI module"
    exit 1
fi

# Parameters
executable="../src/mandelbrot"
output_file="../results/omp_weak_scaling_alt.csv"
X_LEFT=-2.0
Y_LOWER=-1.5
X_RIGHT=1.0
Y_UPPER=1.5
MAX_ITERATIONS=255
C=1000000

# Header
echo "Threads,ImageSize,ComputeTime,IOTime,TotalTime" > "$output_file"

# Loop over thread counts
for threads in {1..128}; do
    size=$(echo "scale=2; sqrt($threads * $C)" | bc | awk '{printf "%d", $1}')

    export OMP_NUM_THREADS=$threads
    export OMP_PLACES=cores
    export OMP_PROC_BIND=close

    echo "Running with $threads threads, image size ${size}x${size}"

    output=$(./${executable} $size $size $X_LEFT $Y_LOWER $X_RIGHT $Y_UPPER $MAX_ITERATIONS $threads)

    compute_time=$(echo "$output" | grep "Compute time" | awk '{print $3}')
    io_time=$(echo "$output" | grep "I/O time" | awk '{print $4}')
    total_time=$(echo "$output" | grep "Total time" | awk '{print $3}')

    echo "$threads,${size}x${size},$compute_time,$io_time,$total_time" >> "$output_file"

    sleep 1
done
