#!/bin/env bash

# The template to build and run the RISC-V official tests on own CPU design
#
# The initial motivation is to help studnets of
# the B4M35PAP - Advanced Computer Architectures course
# https://cw.fel.cvut.cz/wiki/courses/b4m35pap/start
#
# The related Czech technical University in Prague courses guidepost
# https://comparch.edu.cvut.cz/
#
# (C) 2025 Karel Bartunek and Pavel Pisa as public domain

if [ ! -e riscv-tests ]; then
    echo "Downloading official RISC-V tests"
    echo "In the case of problems, switch to 6b474726f51d9ed909b467be0390a6f3d04527f1 version."
    git clone https://github.com/riscv-software-src/riscv-tests riscv-tests
fi

if [ ! -e riscv-tests/env/p/link.ld ] ; then
  echo "Creating symlinks from test-env"
  mkdir -p riscv-tests/env/p
  ln -sf ../../../test-env/link.ld riscv-tests/env/p
  ln -sf ../../../test-env/riscv_test.h riscv-tests/env/p
  ln -sf ../../../test-env/encoding.h riscv-tests/env/p
fi

# Rebuild is mandatory
if [ -e riscv-tests/isa ] ; then
  echo "Obtaining a list of useful rv32-ui tests"
  TARGETS=$(make -C riscv-tests/isa clean 2>&1 | tr ' ' '\n' | grep .dump | sed -n -e "s/^\(rv32u[i].*-p-.*\)/\1/p" | tr "\n" " " )
else
  echo "riscv-tests has not successfully been cloned into 'riscv-tests'."
  exit 2
fi

# Compile test binaries

# FIXME: make of the compiler is silenced for convenience
# While debugging, uncomment the next line:
# make -C riscv-tests/isa $TARGETS
make -C riscv-tests/isa $TARGETS 1>/dev/null || exit 1

# Iterate over built targets

echo $targetlist
for TESTFILENAME in $TARGETS; do
    TESTNAME="${TESTFILENAME%.dump}"
    # Convert ELF to a sequence of instructions (.bin)
    riscv64-unknown-elf-objcopy --strip-debug -O binary riscv-tests/isa/$TESTNAME riscv-tests/isa/$TESTNAME.bin || exit 1
    riscv64-unknown-elf-objcopy --strip-debug -O verilog --verilog-data-width 4 riscv-tests/isa/$TESTNAME riscv-tests/isa/$TESTNAME.vdat || exit 1
    # To Verilog format
    hexdump -v -e '"%08x\n" ' riscv-tests/isa/$TESTNAME.bin > riscv-tests/isa/$TESTNAME.dat

    TEST_FILE=riscv-tests/isa/$TESTNAME.dat

    # Uncomment to use Verilog $readmemh compatible format
    # which uses @ fillowed by address to specify where next
    # next data block should be placed
    TEST_FILE=riscv-tests/isa/$TESTNAME.vdat

    # TODO: Launch your code with $(TEST_FILE) being the file to use with $readmemh in Verilog
    # If inserting via macros (-D[key]=[value] in iverilog), you might have to use the ../ operator
    # one or more times to reach the right folder
    echo "Executing with memory in $TEST_FILE"


    # TODO: Replace with the command that launches the CPU testbench
    RESULT=$(cd impl; DUMP="$TESTNAME.vcd" PROGRAM="tests/$TEST_FILE" make)
    echo $RESULT
    # PASS === output ends with "PASS"
    if echo "$RESULT" | grep -q "PASS$"  ; then
        echo "$TESTNAME: PASS"
    else
        echo "$TESTNAME: FAIL"
    fi
done
