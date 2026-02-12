# Makefile for FMM3D (Windows/Linux Hybrid)

CC ?= icx
FC ?= ifx

#=======================================================================
# 1. OS Detection and Command Setup
#=======================================================================
ifeq ($(OS),Windows_NT)
    SHELL := cmd.exe
    # Auto-copy make.inc.windows if make.inc doesn't exist
    PREPARE_INC := $(shell if not exist make.inc copy /Y make.inc.windows make.inc >nul)
    
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
    # Auto-copy make.inc.linux if make.inc doesn't exist
    PREPARE_INC := $(shell [ -f make.inc ] || cp make.inc.linux make.inc)
    
    AR ?= ar
    ARFLAGS ?= rcs
    LIB_EXT = .a
    DYN_EXT = .so
    CP = cp -f
    RM = rm -f
    SLASH = /
endif

# Load user overrides
-include make.inc

#=======================================================================
# 2. Installation Paths & Library Names
#=======================================================================
FMM_INSTALL_DIR = $(PREFIX)
ifeq ($(PREFIX),)
    ifeq ($(OS),Windows_NT)
        FMM_INSTALL_DIR = .$(SLASH)local
    else
        FMM_INSTALL_DIR = $(HOME)/lib
    endif
endif

LIBNAME = libfmm3d
STATICLIB = $(LIBNAME)$(LIB_EXT)
DYNAMICLIB = $(LIBNAME)$(DYN_EXT)

#=======================================================================
# 3. Object List
#=======================================================================
COM = src/Common
HELM = src/Helmholtz
LAP = src/Laplace
STOK = src/Stokes
EM = src/Maxwell

OBJS = $(COM)/besseljs3d.o $(COM)/cdjseval3d.o $(COM)/dfft.o $(COM)/fmmcommon.o \
       $(COM)/legeexps.o $(COM)/prini.o $(COM)/rotgen.o $(COM)/rotproj.o \
       $(COM)/rotviarecur.o $(COM)/tree_routs3d.o $(COM)/pts_tree3d.o \
       $(COM)/yrecursion.o $(COM)/cumsum.o \
       $(HELM)/h3dcommon.o $(HELM)/h3dterms.o $(HELM)/h3dtrans.o \
       $(HELM)/helmrouts3d.o $(HELM)/hfmm3d.o $(HELM)/hfmm3dwrap.o \
       $(HELM)/hfmm3d_mps.o $(HELM)/hfmm3d_memest.o $(HELM)/hfmm3d_ndiv.o \
       $(HELM)/helmkernels.o $(HELM)/hndiv.o $(HELM)/hpwrouts.o \
       $(HELM)/hwts3e.o $(HELM)/hnumphys.o $(HELM)/hnumfour.o $(HELM)/projections.o \
       $(LAP)/lwtsexp_sep1.o $(LAP)/l3dterms.o $(LAP)/l3dtrans.o \
       $(LAP)/laprouts3d.o $(LAP)/lfmm3d.o $(LAP)/lfmm3dwrap.o \
       $(LAP)/lapkernels.o $(LAP)/lndiv.o $(LAP)/lpwrouts.o $(LAP)/lwtsexp_sep2.o \
       $(STOK)/stfmm3d.o $(STOK)/stokkernels.o \
       $(EM)/emfmm3d.o

#=======================================================================
# 4. Primary Targets
#=======================================================================
.PHONY: all lib install clean usage

default: usage

usage:
	@echo "------------------------------------------------------------------------"
	@echo "Makefile for FMM3D. Specify what to make:"
	@echo ""
	@echo "  make install        compile and install the main library"
	@echo "  make install PREFIX=(INSTALL_DIR)  "
	@echo "                      compile and install at custom location"
	@echo "  make lib            compile the main library (in lib/ and lib-static/)"
	@echo "  make clean          remove all objects and built libraries"
	@echo "------------------------------------------------------------------------"

all: lib

lib: $(STATICLIB) $(DYNAMICLIB)

# Separate Logic for Static Library Build
$(STATICLIB): $(OBJS)
ifeq ($(OS),Windows_NT)
	$(AR) $(ARFLAGS)$@ $(OBJS)
	@if not exist lib-static mkdir lib-static
	move $@ lib-static$(SLASH)
else
	$(AR) $(ARFLAGS) $@ $(OBJS)
	mkdir -p lib-static
	mv $@ lib-static/
endif

# Separate Logic for Dynamic Library Build
$(DYNAMICLIB): $(OBJS)
ifeq ($(OS),Windows_NT)
	$(FC) $(FFLAGS) $(OBJS) -o $(DYNAMICLIB) /link $(LDFLAGS_WIN) $(WIN_LIBS) $(OMPLIBS)
	@if not exist lib mkdir lib
	move $@ lib$(SLASH)
else
	$(FC) $(FFLAGS) -shared $(OBJS) -o $(DYNAMICLIB) $(OMPLIBS)
	mkdir -p lib
	mv $@ lib/
endif

#=======================================================================
# 5. Implicit Rules
#=======================================================================
%.o: %.f
	$(FC) -c $(FFLAGS) -I$(HELM) -I$(COM) $< -o $@
%.o: %.f90
	$(FC) -c $(FFLAGS) -I$(HELM) -I$(COM) $< -o $@
%.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

#=======================================================================
# 6. Installation
#=======================================================================
install: $(STATICLIB) $(DYNAMICLIB)
	@echo "Installing to $(FMM_INSTALL_DIR)"
ifeq ($(OS),Windows_NT)
	@if not exist "$(FMM_INSTALL_DIR)" mkdir "$(FMM_INSTALL_DIR)"
	$(CP) lib$(SLASH)$(DYNAMICLIB) "$(FMM_INSTALL_DIR)$(SLASH)"
	$(CP) lib-static$(SLASH)$(STATICLIB) "$(FMM_INSTALL_DIR)$(SLASH)"
else
	mkdir -p $(FMM_INSTALL_DIR)
	$(CP) lib/$(DYNAMICLIB) $(FMM_INSTALL_DIR)/
	$(CP) lib-static/$(STATICLIB) $(FMM_INSTALL_DIR)/
endif

#=======================================================================
# 7. Cleanup
#=======================================================================
clean:
ifeq ($(OS),Windows_NT)
	$(RM) src$(SLASH)Common$(SLASH)*.o 2>nul
	$(RM) src$(SLASH)Helmholtz$(SLASH)*.o 2>nul
	$(RM) src$(SLASH)Laplace$(SLASH)*.o 2>nul
	$(RM) src$(SLASH)Stokes$(SLASH)*.o 2>nul
	$(RM) src$(SLASH)Maxwell$(SLASH)*.o 2>nul
	$(RM) lib$(SLASH)* 2>nul
	$(RM) lib-static$(SLASH)* 2>nul
else
	rm -f src/Common/*.o src/Helmholtz/*.o src/Laplace/*.o \
	      src/Stokes/*.o src/Maxwell/*.o
	rm -rf lib/* lib-static/*
endif