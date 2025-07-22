
This repository contains the code, benchmarks, and reports for the two assignments completed as part of the **High Performance Computing** course.

## Structure

* `EX1/`: Materials for Exercise 1 (MPI Collectives)
* `EX2/`: Materials for Exercise 2 (Mandelbrot Parallelization)


## Exercise 1: MPI Collective Communication Analysis

This exercise focuses on benchmarking and modeling the performance of MPI collective operations using the **OSU Micro-Benchmarks** on the ORFEO cluster (AMD EPYC architecture).
* Evaluation of `MPI_Bcast` (mandatory) and `MPI_Reduce` (selected)
* Tested multiple OpenMPI algorithmic variants: binomial, linear, pipeline, chain, and Rabenseifner
* Benchmarks conducted on **two full EPYC nodes** (256 total processes)
* Developed latency-based performance models using point-to-point measurements to interpret topology-aware communication costs
* Analysis includes architectural bottlenecks (CCX, CCD, NUMA, inter-node)

The final report compares measured and modeled latencies and discusses algorithmic scalability on modern multi-core systems.


## Exercise 2: Mandelbrot Parallelization and Scaling

The second assignment involves parallelizing the Mandelbrot set computation using:

* **OpenMP** for intra-node shared memory parallelism
* **MPI** for inter-node distributed memory parallelism
* **Hybrid MPI + OpenMP** approach

### Scaling Experiments:
* Strong and weak scaling tests on the ORFEO cluster
* Visual output generation (`.pgm` images)
* Plots for speedup and efficiency with fitted Amdahl curves

