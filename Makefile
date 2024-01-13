SOURCEDIR = src
BUILDDIR = build
TARGET = $(BUILDDIR)/hello_world.clap

# List all V source files
V_SRC = $(wildcard $(SOURCEDIR)/*.v)


# Debug and Release build options
DEBUG ?= 0
RELEASE ?= 0
ifeq ($(DEBUG),1)
	V_FLAGS = -cg -show-c-output -trace-calls
else ifeq ($(RELEASE),1)
	V_FLAGS = -prod -skip-unused -cflags -fvisibility=hidden
endif


all: $(TARGET)

# Use dependency on V source files to avoid recompilation
$(TARGET): $(V_SRC) | dir
	v -cc gcc -shared -enable-globals $(V_FLAGS) $(SOURCEDIR) -o $@.so
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

install: $(TARGET)
	mkdir -p ~/.clap
	cp $(TARGET) ~/.clap/

.PHONY: all clean dir info install
