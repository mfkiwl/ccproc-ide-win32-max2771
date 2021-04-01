#H*****************************************************************************
#
# Copyright (c) 2017 ChipCraft Sp. z o.o. All rights reserved
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#   - Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   - Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   - Neither the name of ChipCraft Sp. z o.o. nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# ******************************************************************************
# File Name : generic.mk
# Author    : Rafal Harabien
# ******************************************************************************
# $Date: 2020-09-03 13:37:17 +0200 (czw, 03 wrz 2020) $
# $Revision: 635 $
#H******************************************************************************

ifeq ($(OS),Windows_NT)
    PLATFORM := windows
    EXEEXT ?= .exe
else ifeq ($(shell uname -s),Linux)
    PLATFORM := linux
    EXEEXT ?=
else
    $(error Unsupported platform)
endif

#CCSDK_HOME          ?= $(HOME)/ccsdk
ifndef CCSDK_HOME
  $(error Define CCSDK_HOME variable, eg.: $(HOME)/ccsdk!)
endif

-include $(CCSDK_HOME)/common/customization.mk

ifeq ($(CCSDK_TOOLS_PATH),)
  # set development tools path
  CCSDK_TOOLS_PATH := $(CCSDK_HOME)/build/tools/$(PLATFORM)/stripped
endif
CCSDK_TRIPLET       ?= mips-cc-elf
ifeq ($(CCSDK_TOOLCHAIN_PATH),)
  $(error ChipCraft toolchain path not set, ensure chipcraft-toolchain is installed and CCSDK_TOOLCHAIN_PATH variable is set.)
endif
PREFIX              ?= $(CCSDK_TOOLCHAIN_PATH)/$(CCSDK_TRIPLET)-

NULLSTR := # creating a null string
SPACE   := $(NULLSTR) # end of the line

ifdef windir
 PYTHON    := python
 # Make sure Make always uses cmd.exe on Windows
 SHELL     := cmd
else
 PYTHON    := python2
endif

CC                := "$(PREFIX)gcc$(EXEEXT)"
CXX               := "$(PREFIX)g++$(EXEEXT)"
LINK              := $(CC)
OBJCOPY           := "$(PREFIX)objcopy$(EXEEXT)"
OBJDUMP           := "$(PREFIX)objdump$(EXEEXT)"
SIZE              := "$(PREFIX)size$(EXEEXT)"
DEBUGGER          := "$(PREFIX)gdb$(EXEEXT)"
CCPROG            := "$(CCSDK_TOOLS_PATH)/ccprog$(EXEEXT)"
CCTERM            := "$(CCSDK_TOOLS_PATH)/ccterm$(EXEEXT)"
DBGSERVER_RS      := $(PYTHON) "$(CCSDK_TOOLS_PATH)/dbgserver.py"
DBGSERVER_JTAG    := $(CCSDK_TOOLS_PATH)/debugserverjtag$(EXEEXT)
DBGSERVER_SIM     := $(DBGSERVER_RS)
CCSIM             := "$(CCSDK_TOOLS_PATH)/ccsim$(EXEEXT)"

MINITERM          := miniterm.py
ECHO              := @echo

ifeq ($(CCSDK_USE_JTAG),Yes)
 DBGSERVER := $(DBGSERVER_JTAG)
else
 DBGSERVER := $(DBGSERVER_RS)
endif

ifdef windir
 # native_path(path)
 native_path = $(subst /,\,$(subst \$(SPACE),$(SPACE),$(1)))
 # mkdir_recursive(path)
 mkdir_recursive = if not exist "$(call native_path,$(1))" mkdir "$(call native_path,$(1))"
 # rmdir(path)
 rmdir = del /S /Q "$(call native_path,$(1))"
else
 # native_path(path)
 native_path = $(subst \,/,$(subst \$(SPACE),$(SPACE),$(1)))
 # mkdir_recursive(path)
 mkdir_recursive = mkdir -p "$(call native_path,$(1))"
 # rmdir(path)
 rmdir = rm -rf "$(call native_path,$(1))"
endif



ifneq ($(QUIET),0)
Q := @
endif

BUILDDIR        ?= build
COMMON_BUILDDIR := $(BUILDDIR)/common
PROGBIN         := $(BUILDDIR)/$(PROGNAME)
PROGSREC        := $(BUILDDIR)/$(PROGNAME).srec

# Default ports
CCSDK_DBG_PORT   ?= /dev/ttyUSB0
CCSDK_UART_PORT  ?= /dev/ttyUSB1

ifndef CCSDK_BOARD
  $(error Define CCSDK_BOARD variable, eg.: sim!)
endif

# Default target
all: $(PROGSREC)

# Board specific assignments
include $(CCSDK_HOME)/boards/$(CCSDK_BOARD)/board.properties
CCSDK_MCU             ?= $(MCU)
CCSDK_DBG_BAUDRATE    ?= $(DBG_BAUDRATE)
CCSDK_UART_BAUDRATE   ?= $(UART_BAUDRATE)

CCPROG_FLAGS          += --mcu $(CCSDK_MCU)
DBGSERVER_FLAGS += --mcu $(CCSDK_MCU)
ifeq ($(CCSDK_USE_JTAG),Yes)
 $(info Using JTAG connection.)
 CCPROG_FLAGS          += $(CCSDK_JTAG_FLAG)
else
 CCPROG_FLAGS          += -p $(CCSDK_DBG_PORT) -b auto
 DBGSERVER_FLAGS += -p $(CCSDK_DBG_PORT) -b $(CCSDK_DBG_BAUDRATE)
endif

include $(CCSDK_HOME)/boards/$(CCSDK_BOARD)/board.mk


ifndef CCSDK_MCU
  $(error Define CCSDK_MCU variable, eg.: ml605!)
endif

# Overridable default common sources
DEFAULT_COMMON_SOURCES ?= board.c libc_multicore.c

# Sources from common and drivers SDK subdirectories
COMMON_SOURCES += $(DEFAULT_COMMON_SOURCES)

# Board in uppercase
TOUPPER=$(strip $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,\
  $(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,\
  $(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,\
  $(subst x,X,$(subst y,Y,$(subst z,Z,$1)))))))))))))))))))))))))))
BOARD_UPPER := $(call TOUPPER,$(CCSDK_BOARD))
MCU_UPPER := $(call TOUPPER,$(CCSDK_MCU))

# Preprocessor flags
CPPFLAGS += -DBOARD=$(CCSDK_BOARD) -DBOARD_$(BOARD_UPPER) -DMCU_$(MCU_UPPER)
CPPFLAGS += -I$(CCSDK_HOME)/include
CPPFLAGS += -I$(CCSDK_HOME)/include/flash
CPPFLAGS += -I$(CCSDK_HOME)/common/include
CPPFLAGS += -I$(CCSDK_HOME)/drivers/include
CPPFLAGS += -I$(CCSDK_HOME)/drivers/flash/include
CPPFLAGS += -I$(CCSDK_HOME)/drivers/max2771/include
CPPFLAGS += -I$(CCSDK_HOME)/boards/$(CCSDK_BOARD)
CPPFLAGS += -I$(CCSDK_HOME)/boards/$(CCSDK_BOARD)/include
CPPFLAGS += -MMD -MP

# MIPS II (Big Endian) without coprocessor, unaligned load/store, trap, branch-likely instructions
#CFLAGS_ARCH   ?= -mips2 -EB -msoft-float -mno-branch-likely -mdivide-breaks -mpatfree
#CFLAGS_ARCH   ?= -march=ccproc
CFLAGS_OPT    ?= -Os -fdata-sections -ffunction-sections
CFLAGS_DEBUG  ?= -ggdb -g3
CFLAGS_WARN   ?= -Wall
CFLAGS_CSTD   ?= -std=gnu99
CFLAGS_CXXSTD ?=

CFLAGS   += $(CFLAGS_ARCH) $(CFLAGS_DEBUG) $(CFLAGS_OPT) $(CFLAGS_CSTD) $(CFLAGS_WARN)
CXXFLAGS += $(CFLAGS_ARCH) $(CFLAGS_DEBUG) $(CFLAGS_OPT) $(CFLAGS_CXXSTD) $(CFLAGS_WARN)
ASFLAGS  += $(CFLAGS_ARCH) $(CFLAGS_DEBUG)

LDFLAGS_OPT    ?= -Wl,--gc-sections
LDFLAGS_DEBUG  ?= -Wl,-Map,$(BUILDDIR)/$(PROGNAME).map
LDSCRIPT       ?= "$(CCSDK_HOME)/linker/ccproc.ld"
#LDFLAGS += -Wl,-melf32ccproc

LDFLAGS  += $(CFLAGS_ARCH) -T $(LDSCRIPT) $(LDFLAGS_OPT) $(LDFLAGS_DEBUG)
DEFAULT_LDLIBS ?= -lstdc++ -lc
LDLIBS   += $(DEFAULT_LDLIBS)
# TODO: add stdc++ only for C++ projects

ifndef windir
  DEBUGGER_FLAGS  ?= -tui -q -x "$(CCSDK_HOME)/common/gdbinit"
else
  DEBUGGER_FLAGS  ?= -q -x "$(CCSDK_HOME)/common/gdbinit"
endif

GDB_UNIX_SOCK ?= 0
SIM_DEBUG ?= 1

SIMFLAGS += --uart-input stdin --uart-output stdout --uart-input uart1in.txt --uart-output uart1out.txt --uart-input uart2in.txt --uart-output uart2out.txt

# use virtual ports for simulators
ifeq ($(SIM_DEBUG),1)
  ifdef windir
    SIM_DEBUG_PIPE := ccsim-dbg-pipe
  else
    SIM_DEBUG_PIPE := /tmp/ccsim-dbg-pipe-$(USER)
    CCSIM          := rm -f "$(SIM_DEBUG_PIPE).out" && rm -f "$(SIM_DEBUG_PIPE).in" && $(CCSIM)
  endif
  SIMFLAGS   += -d "$(SIM_DEBUG_PIPE)"
  DBGSERVER_FLAGS_SIM += -p "pipe:$(SIM_DEBUG_PIPE)"
endif

# define debugger flags
GDB_PIPE ?= 1
ifeq ($(GDB_PIPE),1)
  DBGSERVER_FLAGS_PIPE       ?= --pipe --log-file $(BUILDDIR)/dbgserver.log --log DEBUG
  DEBUGGER_FLAGS_TARGET      ?= -ex "target remote | $(subst \,/,$(DBGSERVER)) $(DBGSERVER_FLAGS) $(DBGSERVER_FLAGS_PIPE)"
  DEBUGGER_FLAGS_TARGET_SIM  ?= -ex "target remote | $(subst \,/,$(DBGSERVER_SIM)) $(DBGSERVER_FLAGS_SIM) $(DBGSERVER_FLAGS_PIPE)"
else ifeq ($(GDB_UNIX_SOCK),0)
  GDB_TCP_PORT               ?= 3333
  DEBUGGER_FLAGS_TARGET      ?= -ex "target remote localhost:$(GDB_TCP_PORT)"
  DEBUGGER_FLAGS_TARGET_SIM  ?= -ex "target remote localhost:$(GDB_TCP_PORT)"
  DBGSERVER_FLAGS            += -g $(GDB_TCP_PORT)
  DBGSERVER_FLAGS_SIM        += -g $(GDB_TCP_PORT)
else
  # deprecated
  GDB_UNIX_SOCK_PATH         ?= /tmp/ccproc-dbgserver-$(USER).sock
  DEBUGGER_FLAGS_TARGET      ?= -ex "target remote | socat - UNIX-CONNECT:$(GDB_UNIX_SOCK_PATH)"
  DEBUGGER_FLAGS_TARGET_SIM  ?= -ex "target remote | socat - UNIX-CONNECT:$(GDB_UNIX_SOCK_PATH)"
  DBGSERVER_FLAGS            += -u "$(GDB_UNIX_SOCK_PATH)"
  DBGSERVER_FLAGS_SIM        += -u "$(GDB_UNIX_SOCK_PATH)"
endif


START_OBJ ?= $(COMMON_BUILDDIR)/startup.o

SOURCES += $(wildcard *.c *.cpp *.s *.S)
SOURCES += $(foreach dir,$(SOURCE_DIRS),$(wildcard $(dir)/*.c $(dir)/*.cpp $(dir)/*.s $(dir)/*.S))

OBJECTS := $(addprefix $(BUILDDIR)/,$(subst ../,,$(SOURCES)))
OBJECTS := $(OBJECTS:%.c=%.o)
OBJECTS := $(OBJECTS:%.cpp=%.o)
OBJECTS := $(OBJECTS:%.s=%.o)
OBJECTS := $(OBJECTS:%.S=%.o)

COMMON_OBJECTS := $(addprefix $(COMMON_BUILDDIR)/,$(COMMON_SOURCES))
COMMON_OBJECTS := $(COMMON_OBJECTS:%.c=%.o)
COMMON_OBJECTS := $(COMMON_OBJECTS:%.cpp=%.o)
COMMON_OBJECTS := $(COMMON_OBJECTS:%.s=%.o)
COMMON_OBJECTS := $(COMMON_OBJECTS:%.S=%.o)

ALL_OBJECTS := $(COMMON_OBJECTS) $(OBJECTS)
ALL_OBJECTS := $(START_OBJ) $(filter-out $(START_OBJ),$(ALL_OBJECTS))

# buildrules(input_dir,output_dir)
define buildrules
$(1)/%.o: $(2)%.c
	$(ECHO) Compiling $$@
	$(Q)$$(call mkdir_recursive,$$(dir $$@))
	$(Q)$(CC) $(CPPFLAGS) $(CFLAGS) $(EXTFLAGS) -c $$< -o $$@

$(1)/%.o: $(2)%.cpp
	$(ECHO) Compiling $$@
	$(Q)$$(call mkdir_recursive,$$(dir $$@))
	$(Q)$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $$< -o $$@

$(1)/%.o: $(2)%.s
	$(ECHO) Compiling $$@
	$(Q)$$(call mkdir_recursive,$$(dir $$@))
	$(Q)$(CC) $(ASFLAGS) $(EXTFLAGS) -c $$< -o $$@

$(1)/%.o: $(2)%.S
	$(ECHO) Compiling $$@
	$(Q)$$(call mkdir_recursive,$$(dir $$@))
	$(Q)$(CC) $(CPPFLAGS) $(ASFLAGS) $(EXTFLAGS) -c $$< -o $$@
endef

$(BUILDDIR):
	$(Q)$(call mkdir_recursive,$(BUILDDIR))

$(COMMON_BUILDDIR):
	$(Q)$(call mkdir_recursive,$(COMMON_BUILDDIR))

$(eval $(call buildrules,$(BUILDDIR),))
$(eval $(call buildrules,$(COMMON_BUILDDIR),$(CCSDK_HOME)/common/))
$(eval $(call buildrules,$(COMMON_BUILDDIR),$(CCSDK_HOME)/boards/$(CCSDK_BOARD)/))
$(eval $(call buildrules,$(COMMON_BUILDDIR),$(CCSDK_HOME)/drivers/))
$(foreach dir,$(SOURCE_DIRS),$(eval $(call buildrules,$(BUILDDIR)/$(subst ../,,$(dir)),$(dir)/)))

$(PROGBIN): $(ALL_OBJECTS)
	$(ECHO) Linking $@
	$(Q)$(LINK) $(LDFLAGS) -o $@ $^ $(LDLIBS)
	$(Q)$(SIZE) $@

$(PROGSREC): $(PROGBIN)
	$(ECHO) Generating $@
	$(Q)$(OBJCOPY) -O srec $^ $@

size: $(PROGBIN)
	$(Q)$(SIZE) $(PROGBIN)

clean:
	$(Q)$(call rmdir,$(BUILDDIR))

debug: $(PROGBIN)
	$(Q)$(DEBUGGER) $(DEBUGGER_FLAGS) $(DEBUGGER_FLAGS_TARGET) $(PROGBIN)

debug-server:
	$(Q)$(DBGSERVER) $(DBGSERVER_FLAGS)

sim: $(PROGSREC)
	$(Q)$(CCSIM) $(SIMFLAGS) $(PROGSREC)

ifeq ($(SIM_DEBUG),1)
sim-debug:
	$(Q)$(DEBUGGER) $(DEBUGGER_FLAGS) $(DEBUGGER_FLAGS_TARGET_SIM) $(PROGBIN)
sim-debug-server:
	$(Q)$(DBGSERVER_SIM) $(DBGSERVER_FLAGS_SIM)
endif

reset:
	$(Q)$(CCPROG) $(CCPROG_FLAGS) --reset-only $(PROGSREC)

disasm: $(PROGBIN)
	$(Q)$(OBJDUMP) -d -l $(PROGBIN) > "$(BUILDDIR)/$(PROGNAME)_disasm.S"

term:
	$(Q)$(CCTERM) $(CCSDK_UART_PORT) $(CCSDK_UART_BAUDRATE)

miniterm:
	$(Q)$(MINITERM) $(CCSDK_UART_PORT) $(CCSDK_UART_BAUDRATE)

.PHONY: all clean size sim debug debug-server sim-debug-server reset disasm term miniterm

# Ignore .d files when clean target is used
ifeq ($(filter clean,$(MAKECMDGOALS)),)
 # Include .d files containing dependencies generated by GCC
 -include $(ALL_OBJECTS:%.o=%.d)
endif
