
PROJNM=PetVideoSim
SRCDIR=$(PROJNM).srcs
SOURCES= \
	$(SRCDIR)/sim_1/pet2001vid.v				\
	$(SRCDIR)/sim_1/dynamicpet.v				\
	$(SRCDIR)/sim_1/ttllib.v				\
	$(SRCDIR)/sim_1/charrom.mem
SCRIPTDIR=$(SRCDIR)/scripts_1

ifndef XILINX_VIVADO
$(error XILINX_VIVADO must be set to point to Xilinx tools)
endif

VIVADO=$(XILINX_VIVADO)/bin/vivado
XSDB=$(XILINX_VIVADO)/bin/xsdb

.PHONY: default project bitstream program simulate

default: project

PROJECT_FILE=$(PROJNM)/$(PROJNM).xpr

project: $(PROJECT_FILE)

$(PROJECT_FILE): $(ROMS)
	$(VIVADO) -mode batch -source project.tcl

pet2001vid.vcd: $(PROJECT_FILE) $(SOURCES)
	$(VIVADO) -mode batch -source $(SCRIPTDIR)/simulate.tcl \
		-tclargs $(PROJNM) -tclargs pet2001vid
	mv $(PROJNM)/$(PROJNM).sim/sim_1/behav/xsim/dump.vcd $@

dynamicpet.vcd: $(PROJECT_FILE) $(SOURCES)
	$(VIVADO) -mode batch -source $(SCRIPTDIR)/simulate.tcl \
		-tclargs $(PROJNM) -tclargs dynamicpet
	mv $(PROJNM)/$(PROJNM).sim/sim_1/behav/xsim/dump.vcd $@

simulate: pet2001vid.vcd dynamicpet.vcd

