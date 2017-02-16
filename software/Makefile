PRJ=stratox.gpr
PRJ_RTS=../runtime/ravenscar-sfp-stm32f427/ravenscar_build.gpr
FLAGS=--target=arm-eabi -d

.PHONY: stratox rts prove clean bugreport

all: stratox

bugreport:
	./collect_files_for_bugreport.sh

rts:
	gprbuild $(FLAGS) -p -P $(PRJ_RTS)

stratox: rts
	gprbuild $(FLAGS) -p -P $(PRJ)

prove:
	./proveall

clean:
	gprclean -r -P $(PRJ)
	gprclean -r -P $(PRJ_RTS)

