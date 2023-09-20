REPO := $(shell git rev-parse --show-toplevel)

#--------------------------------------------------------------------
# SRC files and tb files

# directories
RTL_PATH := $(REPO)/src/rtl/
TB_PATH := $(REPO)/verif/tb/
# src files
UART_FILES := $(wildcard $(RTL_PATH)/uart/*.sv)
SV_FILE += $(UART_FILES)
TB_PATH := $(REPO)/verif/tb

SIM ?= iverilog

#--------------------------------------------------------------------
# Directory

OUTPUT := output


#--------------------------------------------------------------------
# OPTIONS

IVERILOG_OPTIONS += -g2012
ifeq ($(WAVE),1)
VVP_OPTIONS      += +DUMP
endif

XVLOG_OPTIONS += -sv
XELAB_OPTIONS += -timescale 1ns/10ps --debug all

ifeq ($(WAVE),1)
XSIM_OPTIONS  += -testplusarg DUMP
endif

#--------------------------------------------------------------------
# Functions

define add_test
$(1): $(OUTPUT)
ifeq ($(SIM), iverilog)
	@iverilog $(IVERILOG_OPTIONS) $(SV_FILE) $(TB_PATH)/$(1)_tb.sv -I $(TB_PATH) -o $(OUTPUT)/$(1)
	@cd $(OUTPUT); vvp $(1) $(VVP_OPTIONS)
else ifeq ($(SIM), vivado)
	@cd $(OUTPUT); xvlog $(XVLOG_OPTIONS) -i $(TB_PATH) $(SV_FILE) $(TB_PATH)/$(1)_tb.sv
	@cd $(OUTPUT); xelab $(XELAB_OPTIONS) $(1)_tb
	@cd $(OUTPUT); xsim $(1)_tb $(XSIM_OPTIONS) -R
endif
endef

#--------------------------------------------------------------------
# Compile and run test cases


$(eval $(call add_test,uart_rx))

rtl_lint:
	@verilator -lint-only -Wall $(SV_FILE)

$(OUTPUT):
	@mkdir -p output

#--------------------------------------------------------------------
# Clean target

clean:
	rm -rf $(OUTPUT)
