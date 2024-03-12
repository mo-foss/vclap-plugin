SOURCEDIR = .
BUILDDIR = build
TARGET = $(BUILDDIR)/hello_world.clap
V_CMD = v -cc gcc -shared -enable-globals
V_SRC := $(shell find $(SOURCEDIR) -name '*.v' -o -name '*.c')

# Debug and Release build options
DEBUG ?= 0
RELEASE ?= 0
ifeq ($(DEBUG),1)
	V_FLAGS = -cg
else ifeq ($(DEBUG),2)
	V_FLAGS = -cg -show-c-output
else ifeq ($(DEBUG),3)
	# Even more debug! Very noisy.
	V_FLAGS = -cg -show-c-output -trace-calls
else ifeq ($(RELEASE),1)
	# -prod currently crashes GC.
	V_FLAGS = -skip-unused -cflags -fvisibility=hidden # -prod
endif


all: $(TARGET)

# Use dependency on V source files to avoid recompilation
$(TARGET): $(V_SRC) | dir
	$(V_CMD) $(V_FLAGS) $(SOURCEDIR) -o $@.so
ifeq ($(RELEASE),1)
	strip $@.so
endif
	mv $@.so $@

dir:
	mkdir -p $(BUILDDIR)

clean:
	rm -rf $(BUILDDIR)

info: $(TARGET)
	clap-info $<

genc: $(V_SRC) | dir
	$(V_CMD) $(V_FLAGS) $(SOURCEDIR) -o $(TARGET).c

install: $(TARGET)
	mkdir -p ~/.clap
	cp $(TARGET) ~/.clap/

.PHONY: all clean dir info install
