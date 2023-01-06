
PROJNM=PetVideoSim
SRCDIR=$(PROJNM).srcs
SOURCES= \
	$(SRCDIR)/sim_1/petvid.v				\
	$(SRCDIR)/sim_1/ttllib.v				\
	$(SRCDIR)/sim_1/charrom.mem


ifndef XILINX_VIVADO
$(error XILINX_VIVADO must be set to point to Xilinx tools)
endif

VIVADO=$(XILINX_VIVADO)/bin/vivado
XSDB=$(XILINX_VIVADO)/bin/xsdb

.PHONY: default project bitstream program

default: project

PROJECT_FILE=$(PROJNM)/$(PROJNM).xpr

project: $(PROJECT_FILE)

$(PROJECT_FILE): $(ROMS)
	$(VIVADO) -mode batch -source project.tcl

