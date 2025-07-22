#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>
#include <omp.h>
#include <string.h>

int compute_mandelbrot(double cx, double cy, int max_iter) {
    double x = 0, y = 0;
    double x2 = 0, y2 = 0;
    int iter = 0;

    while (x2 + y2 <= 4 && iter < max_iter) {
        y = 2 * x * y + cy;
        x = x2 - y2 + cx;
        x2 = x * x;
        y2 = y * y;
        iter++;
    }

    return iter;
}

int write_pgm_image_mpi(void *image, int maxval, int xsize, int ysize,
                        const char *image_name, int rank, int size, int local_rows) {
    MPI_File file;
    MPI_Status status;
    int result;
    char header[1024];
    int header_size = 0;

    result = MPI_File_open(MPI_COMM_WORLD, image_name,
                           MPI_MODE_CREATE | MPI_MODE_WRONLY,
                           MPI_INFO_NULL, &file);
    if (result != MPI_SUCCESS) return 0;

    if (rank == 0) {
        header_size = snprintf(header, sizeof(header),
                               "P5\n%d %d\n%d\n",
                               xsize, ysize, maxval);
        MPI_File_write(file, header, header_size, MPI_CHAR, &status);
    }

    MPI_Bcast(&header_size, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Barrier(MPI_COMM_WORLD);

    MPI_Offset offset = header_size + (MPI_Offset)(rank * local_rows * xsize);
    MPI_File_write_at(file, offset, image, local_rows * xsize, MPI_UNSIGNED_CHAR, &status);

    MPI_File_close(&file);
    return 1;
}

int main(int argc, char** argv) {
    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);

    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc != 9) {
        if (rank == 0)
            fprintf(stderr, "Usage: %s nx ny xL yL xR yR Imax num_threads\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    int nx = atoi(argv[1]);
    int ny = atoi(argv[2]);
    double xL = atof(argv[3]);
    double yL = atof(argv[4]);
    double xR = atof(argv[5]);
    double yR = atof(argv[6]);
    int Imax = atoi(argv[7]);
    int num_threads = atoi(argv[8]);

    omp_set_dynamic(0);
    omp_set_num_threads(num_threads);

    MPI_Barrier(MPI_COMM_WORLD);
    double start_total = MPI_Wtime();

    double dx = (xR - xL) / nx;
    double dy = (yR - yL) / ny;

    int rows_per_process = ny / size;
    int remainder = ny % size;
    int start_row = rank * rows_per_process + (rank < remainder ? rank : remainder);
    int local_rows = rows_per_process + (rank < remainder ? 1 : 0);

    unsigned char* local_image = (unsigned char*)malloc(local_rows * nx);
    if (local_image == NULL) {
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double start_compute = MPI_Wtime();

    #pragma omp parallel for schedule(dynamic)
    for (int j = 0; j < local_rows; j++) {
        for (int i = 0; i < nx; i++) {
            double cx = xL + i * dx;
            double cy = yL + (start_row + j) * dy;
            int iter = compute_mandelbrot(cx, cy, Imax);
            local_image[j * nx + i] = (unsigned char)(iter == Imax ? 255 : 0);
        }
    }

    double end_compute = MPI_Wtime();
    double start_io = MPI_Wtime();

    int write_success = write_pgm_image_mpi(local_image, 255, nx, ny,
                                            "mandelbrot_output.pgm", rank, size, local_rows);

    double end_io = MPI_Wtime();
    double compute_time = end_compute - start_compute;
    double io_time = end_io - start_io;
    double total_time = end_io - start_compute;

    double max_compute, max_io, max_total;
    MPI_Reduce(&compute_time, &max_compute, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(&io_time, &max_io, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    MPI_Reduce(&total_time, &max_total, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);

    if (rank == 0) {
        printf("Image size: %dx%d\n", nx, ny);
        printf("Processes: %d\n", size);
        printf("Threads per process: %d\n", num_threads);
        printf("Compute time: %f\n", max_compute);
        printf("I/O time: %f\n", max_io);
        printf("Total time: %f\n", max_total);
    }

    free(local_image);
    MPI_Finalize();
    return 0;
}
