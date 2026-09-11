#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <omp.h>

static double *matrix_alloc(size_t n) {
    double *m = malloc(n * n * sizeof(double));
    if (!m) {
        fprintf(stderr, "Error: no se pudo asignar memoria para una matriz de %zux%zu\n", n, n);
        exit(EXIT_FAILURE);
    }
    return m;
}

static void matrix_fill_random(double *m, size_t n, unsigned int seed) {
    srand(seed);
    for (size_t i = 0; i < n * n; i++) {
        m[i] = (double)(rand() % 1000) / 10.0;
    }
}

static void matrix_zero(double *m, size_t n) {
    memset(m, 0, n * n * sizeof(double));
}

static void matrix_print(const double *m, size_t n) {
    for (size_t i = 0; i < n; i++) {
        for (size_t j = 0; j < n; j++) {
            printf("%8.2f ", m[i * n + j]);
        }
        printf("\n");
    }
}

static void matrix_multiply(const double *A, const double *B, double *C, size_t n) {
    #pragma omp parallel for default(none) shared(A, B, C, n) schedule(static)
    for (size_t i = 0; i < n; i++) {
        for (size_t k = 0; k < n; k++) {
            double a_ik = A[i * n + k];
            #pragma omp simd
            for (size_t j = 0; j < n; j++) {
                C[i * n + j] += a_ik * B[k * n + j];
            }
        }
    }
}

static double matrix_checksum(const double *m, size_t n) {
    double sum = 0.0;
    for (size_t i = 0; i < n * n; i++) {
        sum += m[i];
    }
    return sum;
}

int main(int argc, char **argv) {
    size_t n = 1000;
    unsigned int seed = 42;
    int threads = 0;

    if (argc >= 2) {
        n = (size_t)strtoul(argv[1], NULL, 10);
    }
    if (argc >= 3) {
        seed = (unsigned int)strtoul(argv[2], NULL, 10);
    }
    if (argc >= 4) {
        threads = atoi(argv[3]);
    }
    if (n == 0) {
        fprintf(stderr, "Uso: %s <N> [seed] [threads]\n", argv[0]);
        return EXIT_FAILURE;
    }
    if (threads > 0) {
        omp_set_num_threads(threads);
    }

    double *A = matrix_alloc(n);
    double *B = matrix_alloc(n);
    double *C = matrix_alloc(n);

    matrix_fill_random(A, n, seed);
    matrix_fill_random(B, n, seed + 1);
    matrix_zero(C, n);

        int used_threads = 0;
    #pragma omp parallel
    {
        #pragma omp single
        used_threads = omp_get_num_threads();
    }

    double start = omp_get_wtime();

    matrix_multiply(A, B, C, n);

    double end = omp_get_wtime();
    double elapsed = end - start;

    printf("Version:    paralelo (OpenMP)\n");
    printf("N:          %zu\n", n);
    printf("Threads:    %d\n", used_threads);
    printf("Tiempo (s): %.6f\n", elapsed);
    printf("Checksum:   %.6f\n", matrix_checksum(C, n));

    if (n <= 10) {
        printf("\nA =\n");
        matrix_print(A, n);
        printf("\nB =\n");
        matrix_print(B, n);
        printf("\nC = A x B =\n");
        matrix_print(C, n);
    }

    free(A);
    free(B);
    free(C);
    return EXIT_SUCCESS;
}
