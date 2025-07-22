#!/bin/bash
#SBATCH --job-name=hpc
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --output=output_strong_%j.out
#SBATCH --error=error_strong_%j.err
#SBATCH --time=02:00:00
#SBATCH --partition=EPYC
#SBATCH --exclusive

module purge
module load openMPI/4.1.6

# Ensure executable and directories exist
mkdir -p ../results ../plots
executable="../base/mandelbrot"
output_file="../results/mpi_strong_scaling.csv"

if [ ! -f "$executable" ]; then
    echo "Error: Executable not found at $executable"
    exit 1
fi

# Mandelbrot parameters
N=10000
X_LEFT=-2.0
Y_LOWER=-1.5
X_RIGHT=1.0
Y_UPPER=1.5
MAX_ITERATIONS=255
OMP_THREADS=1

echo "MPI_Processes,Size,ComputeTime,IOTime,TotalTime" > "$output_file"

for PROCS in {1..256}; do
    echo "Running with $PROCS processes"

    export OMP_NUM_THREADS=$OMP_THREADS

    timeout 1800 mpirun -np $PROCS \
        --map-by core --bind-to core \
        $executable $N $N $X_LEFT $Y_LOWER $X_RIGHT $Y_UPPER $MAX_ITERATIONS $OMP_THREADS || {
            echo "Warning: MPI run failed for $PROCS processes"
            continue
        }

    compute_time=$(grep "Compute time:" output_strong_${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $3}')
    io_time=$(grep "I/O time:" output_strong_${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $4}')
    total_time=$(grep "Total time:" output_strong_${SLURM_JOB_ID}.out | tail -n 1 | awk '{print $3}')

    echo "$PROCS,$N,$compute_time,$io_time,$total_time" >> "$output_file"
    sleep 2
done

echo -e "\nResults saved in: $output_file"
