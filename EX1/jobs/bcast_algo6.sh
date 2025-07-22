#!/bin/bash
#SBATCH --job-name=hpc_exam
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --time=01:30:00
#SBATCH --partition=EPYC
#SBATCH --account=dssc
#SBATCH --exclusive
#SBATCH --output=bcast_algo6_full_%j.out

module purge
module load openMPI/4.1.6

# Binary path
BCAST_BIN="$HOME/scratch/HPC/osu-micro-benchmarks-7.4/c/mpi/collective/blocking/osu_bcast"
OUTPUT_CSV="bcast_algo6.csv"
ALGO=6

# Header
echo "Processes,Size,Algorithm,Latency(us)" > $OUTPUT_CSV

# Message sizes in bytes (you can adjust or expand this list)
SIZES=(2)

# Process sweep
for np in $(seq 2 2 256); do
    for size in "${SIZES[@]}"; do
        result=$(mpirun --map-by core -np $np \
            --mca coll_tuned_use_dynamic_rules true \
            --mca coll_tuned_bcast_algorithm $ALGO \
            $BCAST_BIN -m $size -x 100 -i 1000 | tail -1 | awk '{print $2}')
        echo "$np,$size,$ALGO,$result" >> $OUTPUT_CSV
    done
done
