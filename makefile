# Makefile for FMM3D (Windows/Linux Hybrid)

CC ?= icx
CXX ?= icpx
FC ?= ifx

# OS Detection
ifeq ($(OS),Windows_NT)
    SHELL := cmd.exe
    AR = xilib
    ARFLAGS = /out:
    LIB_EXT = .lib
    DYN_EXT = .dll
    CP = copy /Y
    RM = -del /Q /F
    SLASH = \\
    LDFLAGS_WIN = /DLL /MACHINE:X64
    WIN_LIBS = msvcrt.lib ucrt.lib vcruntime.lib oldnames.lib kernel32.lib user32.lib advapi32.lib
else
    AR ?= ar
    ARFLAGS ?= rcs
    LIB_EXT = .a
    DYN_EXT = .so
    CP = cp -f
    RM = rm -f
    SLASH = /
endif

-include make.inc

# Restored PREFIX Logic
# If PREFIX is provided via command line (make install PREFIX=local), use it.
# Otherwise, fall back to OS-specific defaults.
FMM_INSTALL_DIR = $(PREFIX)
ifeq ($(PREFIX),)
    ifeq ($(OS),Windows_NT)
        FMM_INSTALL_DIR = .$(SLASH)local
    else
        FMM_INSTALL_DIR = $(HOME)/lib
    endif
endif

STATICLIB = libfmm3d$(LIB_EXT)
DYNAMICLIB = libfmm3d$(DYN_EXT)

# Object list
OBJS = src/Common/besseljs3d.o src/Common/cdjseval3d.o src/Common/dfft.o \
       src/Common/fmmcommon.o src/Common/legeexps.o src/Common/prini.o \
       src/Common/rotgen.o src/Common/rotproj.o src/Common/rotviarecur.o \
       src/Common/tree_routs3d.o src/Common/pts_tree3d.o src/Common/yrecursion.o \
       src/Common/cumsum.o \
       src/Helmholtz/h3dcommon.o src/Helmholtz/h3dterms.o src/Helmholtz/h3dtrans.o \
       src/Helmholtz/helmrouts3d.o src/Helmholtz/hfmm3d.o src/Helmholtz/hfmm3dwrap.o \
       src/Helmholtz/hfmm3d_mps.o src/Helmholtz/hfmm3d_memest.o src/Helmholtz/hfmm3d_ndiv.o \
       src/Helmholtz/helmkernels.o src/Helmholtz/hndiv.o \
       src/Helmholtz/hpwrouts.o src/Helmholtz/hwts3e.o src/Helmholtz/hnumphys.o \
       src/Helmholtz/hnumfour.o src/Helmholtz/projections.o \
       src/Laplace/lwtsexp_sep1.o src/Laplace/l3dterms.o src/Laplace/l3dtrans.o \
       src/Laplace/laprouts3d.o src/Laplace/lfmm3d.o src/Laplace/lfmm3dwrap.o \
       src/Laplace/lapkernels.o src/Laplace/lndiv.o \
       src/Laplace/lpwrouts.o src/Laplace/lwtsexp_sep2.o \
       src/Stokes/stfmm3d.o src/Stokes/stokkernels.o \
       src/Maxwell/emfmm3d.o

.PHONY: all lib install clean

all: lib

lib: $(STATICLIB) $(DYNAMICLIB)

$(STATICLIB): $(OBJS)
	$(AR) $(ARFLAGS)$@ $(OBJS)
	@if not exist lib-static mkdir lib-static
	move $(STATICLIB) lib-static$(SLASH)

$(DYNAMICLIB): $(OBJS)
ifeq ($(OS),Windows_NT)
	$(FC) $(FFLAGS) $(OBJS) -o $(DYNAMICLIB) /link $(LDFLAGS_WIN) $(WIN_LIBS) $(OMPLIBS)
else
	$(FC) $(FFLAGS) -shared $(OBJS) -o $(DYNAMICLIB) $(OMPLIBS)
endif
	@if not exist lib mkdir lib
	move $(DYNAMICLIB) lib$(SLASH)

%.o: %.f
	$(FC) -c $(FFLAGS) -Isrc/Helmholtz -Isrc/Common $< -o $@
%.o: %.f90
	$(FC) -c $(FFLAGS) -Isrc/Helmholtz -Isrc/Common $< -o $@
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

install: $(STATICLIB) $(DYNAMICLIB)
ifeq ($(OS),Windows_NT)
	@if not exist "$(FMM_INSTALL_DIR)" mkdir "$(FMM_INSTALL_DIR)"
	$(CP) lib$(SLASH)$(DYNAMICLIB) "$(FMM_INSTALL_DIR)$(SLASH)"
	$(CP) lib-static$(SLASH)$(STATICLIB) "$(FMM_INSTALL_DIR)$(SLASH)"
else
	mkdir -p $(FMM_INSTALL_DIR)
	cp -f lib/$(DYNAMICLIB) $(FMM_INSTALL_DIR)/
	cp -f lib-static/$(STATICLIB) $(FMM_INSTALL_DIR)/
endif

clean:
	$(RM) src$(SLASH)Common$(SLASH)*.o 2>nul || exit 0
	$(RM) src$(SLASH)Helmholtz$(SLASH)*.o 2>nul || exit 0
	$(RM) src$(SLASH)Laplace$(SLASH)*.o 2>nul || exit 0
	$(RM) src$(SLASH)Stokes$(SLASH)*.o 2>nul || exit 0
	$(RM) src$(SLASH)Maxwell$(SLASH)*.o 2>nul || exit 0
	$(RM) lib$(SLASH)* 2>nul || exit 0
	$(RM) lib-static$(SLASH)* 2>nul || exit 0