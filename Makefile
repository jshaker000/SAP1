MODULE_NAME    := Top
VERILATED_NAME := V${MODULE_NAME}
ASM            := example.asm
RAMFILE        := ram.hex
ASSEMBLER      := assembler.rb
OBJ_DIR        := obj_dir
LD_FLAGS       := -lncurses -flto
CFLAGS         := --std=c++17 -O3 -flto
V_FLAGS        := --Wall -O3 --clk mclk --trace --Mdir ${OBJ_DIR} --prefix ${VERILATED_NAME}

.PHONY: run all clean

run: all
	${OBJ_DIR}/./${VERILATED_NAME}

all: ${OBJ_DIR}/${VERILATED_NAME} ${RAMFILE}

${RAMFILE} : example.asm ${ASSEMBLER}
	if [ ! -f $@ ]; then ./${ASSEMBLER} -i $< -o $@ ; else touch $@; fi

${OBJ_DIR}/${VERILATED_NAME} : % : %.mk ${MODULE_NAME}.cpp
	cd ${OBJ_DIR}; make -f $(patsubst ${OBJ_DIR}/%,%,$<)

${OBJ_DIR}/${VERILATED_NAME}.mk : ${MODULE_NAME}.v $(filter-out ${MODULE_NAME}, *.v) *.vi
	verilator ${V_FLAGS} -cc $< --exe $(patsubst %.v,%.cpp,$<) -LDFLAGS "${LD_FLAGS}" -CFLAGS "${CFLAGS}"

clean:
	rm -rf ${OBJ_DIR} *.vcd
