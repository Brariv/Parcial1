# Super Matrix Pasco

Consultora HPC — Examen Parcial 1: Super Matrix Pasco

**Grupo 9 — Problema 3: Multiplicación de Matrices Densas (C = A × B)**

## Integrantes

- Nombre integrante 1: Pedro Ruben Avila Cofino
- Nombre integrante 2: Brandon Werner Rivera Cabrera

## Estructura del repositorio

- `secuencial/` — algoritmo base (línea base para medir speedup).
- `paralelo/` — solución optimizada con OpenMP.
- `docs/` — reportes, gráficas y análisis de datos.

## Compilación y ejecución

```bash
make all                                  # compila ambas versiones en bin/
make run-secuencial N=2000 SEED=42
make run-paralelo   N=2000 SEED=42 THREADS=4
```

Uso directo de los binarios:

```
./bin/secuencial <N> [seed]
./bin/paralelo   <N> [seed] [threads]
```

- `N` — dimensión de las matrices cuadradas A, B y C (N×N). Default: 1000.
- `seed` — semilla para generar A y B de forma reproducible. Default: 42.
- `threads` — número de hilos OpenMP. Default: `OMP_NUM_THREADS` o el máximo del sistema.

Ambas versiones imprimen el tiempo de la multiplicación y un checksum (suma de todos los elementos de C). Con el mismo `N` y `seed` el checksum debe ser idéntico en ambas versiones, lo que valida que la versión paralela produce exactamente el mismo resultado. Si `N <= 10` también se imprimen las matrices A, B y C.

## Datos de prueba

A y B se llenan con valores pseudoaleatorios en el rango [0.0, 99.9] a partir de `rand()` con la semilla indicada (B usa `seed + 1`). Ambas versiones generan exactamente la misma secuencia de números, por lo que los resultados son comparables entre sí.

Las matrices se almacenan en memoria como un único arreglo unidimensional de `double` de tamaño N·N en orden por filas (`M[i][j] = m[i * N + j]`). Esto garantiza que una fila completa sea contigua en memoria y aprovecha mejor la caché que un arreglo de punteros a filas.

## Versión secuencial

Orden de bucles i-k-j: para cada fila `i`, el valor `A[i][k]` se lee una sola vez y se reutiliza en todo el recorrido de `j`, mientras que `B[k][j]` y `C[i][j]` se recorren de forma contigua en memoria. Esto minimiza relecturas de A y B frente al orden clásico i-j-k (donde `B[k][j]` se recorre por columnas, saltando de fila en fila), y es la base que luego se reparte entre hilos en la versión paralela.

El checksum es la suma de todos los elementos de C y sirve como verificación rápida sin imprimir matrices completas cuando N es grande.

## Versión paralela (OpenMP)

### Estrategia de paralelización

- **Descomposición por filas de C.** Cada hilo recibe un bloque de filas completas de C. Como cada hilo escribe únicamente en sus propias filas, no existe condición de carrera sobre C y no se necesitan secciones críticas, `atomic` ni reducciones.
- **A y B son solo lectura (`shared`).** La fila `i` de A la lee únicamente el hilo dueño de esa fila, y B se comparte en caché entre todos los hilos sin escrituras que la invaliden.
- **Orden de bucles i-k-j** (igual que la versión secuencial): `A[i][k]` se carga una vez en registro y las filas `B[k][*]` y `C[i][*]` se recorren de forma contigua, aprovechando la caché y permitiendo vectorización del bucle interno.
- **`schedule(static)`.** Cada fila de C cuesta exactamente lo mismo (N·N operaciones), por lo que un reparto estático en bloques contiguos queda balanceado y evita el overhead de un scheduling dinámico. Además, los bloques contiguos de filas mejoran la localidad.

### Directivas utilizadas

`#pragma omp parallel for default(none) shared(A, B, C, n) schedule(static)` sobre el bucle de filas `i`:

- `parallel for` reparte las iteraciones del bucle `i` (filas de C) entre los hilos.
- `default(none)` obliga a declarar el ámbito de cada variable, evitando que por accidente una variable quede compartida y genere una condición de carrera.
- `shared(A, B, C, n)`: las matrices se comparten (no se copian).
- `i`, `k`, `j` y `a_ik` se declaran dentro del bloque, por lo que son privadas para cada hilo automáticamente.
- `schedule(static)`: bloques contiguos de filas de tamaño aproximado N / threads.

`#pragma omp simd` en el bucle interno sobre `j`: le indica al compilador que no hay dependencias entre iteraciones y que el bucle puede vectorizarse (SIMD).

### Medición y verificación

- El tiempo se mide con `omp_get_wtime()` únicamente alrededor de la multiplicación (no incluye la generación de datos ni el checksum).
- Se reporta el número real de hilos con el que se ejecutó la región paralela (`omp_get_num_threads()`).
- El checksum se calcula de forma secuencial a propósito: sumar en el mismo orden que la versión secuencial garantiza un resultado bit a bit idéntico. Con una `reduction(+:sum)` el valor variaría en los últimos decimales por el orden de las sumas en punto flotante, aunque la matriz C fuera idéntica.

## Métricas

- Speedup: `S = T_secuencial / T_paralelo`
- Eficiencia: `E = S / threads`

Las mediciones de cada integrante, con capturas de las ejecuciones, están en `docs/`.
