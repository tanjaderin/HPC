#!/bin/bash
#SBATCH --job-name=hpc 
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --time=01:30:00
#SBATCH --partition=EPYC
#SBATCH --account=dssc
#SBATCH --exclusive
#SBATCH --output=reduce_algo4_full_%j.out

module purge
module load openMPI/4.1.6

# Path to the binary
REDUCE_BIN="$HOME/scratch/HPC/osu-micro-benchmarks-7.4/c/mpi/collective/blocking/osu_reduce"
OUTPUT_CSV="reduce_algo4_all.csv"
ALGO=4

# CSV header
echo "Processes,Size,Algorithm,Latency(us)" > $OUTPUT_CSV

# Message sizes (Bytes)
SIZES=(2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576)

# Loop through processes and sizes
for np in 2 4 8 16 32 64 128 256; do
    for size in "${SIZES[@]}"; do
        result=$(mpirun --map-by core -np $np \
            --mca coll_tuned_use_dynamic_rules true \
            --mca coll_tuned_reduce_algorithm $ALGO \
            $REDUCE_BIN -m $size -x 100 -i 1000 | tail -1 | awk '{print $2}')
        echo "$np,$size,$ALGO,$result" >> $OUTPUT_CSV
    done
done
