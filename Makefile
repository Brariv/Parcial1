# Compila en Linux y macOS.
#
# Linux : gcc con -fopenmp.
# macOS : el "gcc" de Xcode es clang y no trae OpenMP. Se busca, en este orden:
#           1. gcc de Homebrew (brew install gcc)      -> gcc-15, gcc-14, ...
#           2. clang de Xcode + libomp (brew install libomp)
#         Tambien se puede forzar el compilador: make CC=gcc-14

UNAME_S := $(shell uname -s)

CFLAGS := -Wall -Wextra -O2 -std=c11
BIN_DIR := bin

SEQ_SRC := secuencial/matrix_multiplier.c
PAR_SRC := paralelo/matrix_multiplier.c

SEQ_BIN := $(BIN_DIR)/secuencial
PAR_BIN := $(BIN_DIR)/paralelo

ifeq ($(UNAME_S),Darwin)
  # 1) gcc de Homebrew, si existe
  BREW_GCC := $(firstword $(foreach v,16 15 14 13 12 11,$(shell command -v gcc-$(v) 2>/dev/null)))
  ifneq ($(BREW_GCC),)
    CC := $(BREW_GCC)
    OMPFLAGS := -fopenmp
    OMPLIBS  :=
  else
    # 2) clang de Xcode + libomp de Homebrew
    CC := clang
    LIBOMP := $(shell brew --prefix libomp 2>/dev/null)
    ifeq ($(LIBOMP),)
      $(error No se encontro OpenMP. Instala uno: 'brew install gcc' o 'brew install libomp')
    endif
    OMPFLAGS := -Xpreprocessor -fopenmp -I$(LIBOMP)/include
    OMPLIBS  := -L$(LIBOMP)/lib -lomp
  endif
else
  CC := gcc
  OMPFLAGS := -fopenmp
  OMPLIBS  :=
endif

# Parametros por defecto para los targets de ejecucion (make run-secuencial N=2000)
N ?= 1000
SEED ?= 42
THREADS ?= 4

.PHONY: all secuencial paralelo run-secuencial run-paralelo clean info

all: secuencial paralelo

secuencial: $(SEQ_BIN)

paralelo: $(PAR_BIN)

$(SEQ_BIN): $(SEQ_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(PAR_BIN): $(PAR_SRC) | $(BIN_DIR)
	$(CC) $(CFLAGS) $(OMPFLAGS) -o $@ $< $(OMPLIBS)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

run-secuencial: $(SEQ_BIN)
	./$(SEQ_BIN) $(N) $(SEED)

run-paralelo: $(PAR_BIN)
	OMP_NUM_THREADS=$(THREADS) ./$(PAR_BIN) $(N) $(SEED) $(THREADS)

info:
	@echo "OS:       $(UNAME_S)"
	@echo "CC:       $(CC)"
	@echo "OMPFLAGS: $(OMPFLAGS)"
	@echo "OMPLIBS:  $(OMPLIBS)"

clean:
	rm -rf $(BIN_DIR)
