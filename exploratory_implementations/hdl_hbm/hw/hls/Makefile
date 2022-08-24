
SNAP_ROOT=$(abspath ../../../../oc-accel)
modules = $(wildcard ./hls_*)

.PHONY: all vhdl clean $(modules)

all: vhdl

vhdl: $(modules)

$(modules):
	@make -C $@ vhdl

clean:
	@for hls_dir in $(modules); do make -C $$hls_dir clean; done