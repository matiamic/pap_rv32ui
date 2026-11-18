
default : all

# -c file_list.txt -s main

all :
	iverilog -DDUMP='"output/${DUMP}"' -DPROGRAM='"${PROGRAM}"' -o riscv_test.vvp -s test_processor riscv_tb.v riscv.v
	vvp riscv_test.vvp

test :
	cd tests && ./run_tests.sh

run :
	cd program && make run

clean:
	rm -f *.vvp
	rm -f output/*
	rm -f output/.vcd
