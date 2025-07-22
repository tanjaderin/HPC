#!/bin/bash
#SBATCH --job-name=hpc
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --output=output_mpi_weak_alt.%j.out
#SBATCH --error=error_mpi_weak_alt.%j.err
#SBATCH --time=02:00:00
#SBATCH --partition=EPYC
#SBATCH --exclusive

module load openMPI/4.1.6

# Check if module loaded successfully
if [ $? -ne 0 ]; then
    echo "Error: Failed to load OpenMPI module"
    exit 1
fi

# Create results directory if needed
mkdir -p ../results

# Paths and filenames
executable="../src/mandelbrot"
output_file="../results/mpi_weak_scaling_alt.csv"

# Check if executable exists
if [ ! -f "$executable" ]; then
    echo "Error: Executable $executable not found!"
    exit 1
fi

# Constants
C=1000000
X_LEFT=-2.0
Y_LOWER=-1.5
X_RIGHT=1.0
Y_UPPER=1.5
MAX_ITERATIONS=255
THREADS=1

# CSV header
echo "MPI_Processes,ImageSize,ComputeTime,IOTime,TotalTime" > $output_file

# Full scan from 1 to 256
for ((procs=1; procs<=256; procs++)); do
    n=$(echo "sqrt($procs * $C)" | bc -l | xargs printf "%.0f")
    echo "Running with $procs processes, image size ${n}x${n}"

    timeout 3600 mpirun -np $procs \
        --map-by core --bind-to core \
        $executable \
        $n $n $X_LEFT $Y_LOWER $X_RIGHT $Y_UPPER $MAX_ITERATIONS $THREADS || {
            echo "Error: MPI run failed for $procs processes"
            continue
        }

    # Extract timing info from output
    compute_time=$(grep "Compute time:" output_mpi_weak_alt.${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $3}')
    io_time=$(grep "I/O time:" output_mpi_weak_alt.${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $3}')
    total_time=$(grep "Total time:" output_mpi_weak_alt.${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $3}')

    echo "$procs,${n}x${n},$compute_time,$io_time,$total_time" >> $output_file
    sleep 1

    # Optional: delete generated .pgm file to save space
    rm -f *.pgm

done

# Summary
echo "\nResults written to $output_file"
