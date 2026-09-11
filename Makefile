CC := gcc
CFLAGS := -Wall -Wextra -O2 -std=c11
OMPFLAGS := -fopenmp

BIN_DIR := bin

SEQ_SRC := secuencial/matrix_multiplier.c
PAR_SRC := paralelo/matrix_multiplier.c

SEQ_BIN := $(BIN_DIR)/secuencial
PAR_BIN := $(BIN_DIR)/paralelo

# Parametros por defecto para los targets de ejecucion (make run-secuencial N=2000)
N ?= 1000
SEED ?= 42
THREADS ?= 4

.PHONY: all secuencial paralelo run-secuencial run-paralelo clean

all: secuencial paralelo

secuencial: $(SEQ_BIN)

paralelo: $(PAR_BIN)

$(SEQ_BIN): $(SEQ_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(PAR_BIN): $(PAR_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) $(OMPFLAGS) -o $@ $<

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run-secuencial: $(SEQ_BIN)
	./$(SEQ_BIN) $(N) $(SEED)

run-paralelo: $(PAR_BIN)
	OMP_NUM_THREADS=$(THREADS) ./$(PAR_BIN) $(N) $(SEED) $(THREADS)

clean:
	rm -rf $(BIN_DIR)
