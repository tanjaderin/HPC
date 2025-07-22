#!/bin/bash
#SBATCH --job-name=HPC_exam
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=128
#SBATCH --time=01:00:00
#SBATCH --partition=EPYC
#SBATCH --account=dssc
#SBATCH --exclusive
#SBATCH --output=reduce_default_output_%j.out

module purge
module load openMPI/4.1.6

REDUCE_BIN="$HOME/scratch/HPC/osu-micro-benchmarks-7.4/c/mpi/collective/blocking/osu_reduce"
OUTPUT_CSV="reduce_default.csv"
echo "Processes,Size,Algorithm,Latency(us)" > $OUTPUT_CSV

for processes in 2 4 8 16 32 64 128 256; do
    for size in 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576; do
        result=$(mpirun --map-by core -np $processes \
            $REDUCE_BIN -m $size -x 1000 -i 1000 | tail -n 1 | awk '{print $2}')
        
        echo "$processes,$size,default,$result" >> $OUTPUT_CSV
    done
done
