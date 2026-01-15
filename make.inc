#
# This config tested under Intel Parallel Studio XE Composer Edition
# for macOS Version 2020 Update 1, released April 2020
# This release is only tested with Xcode 13.1.1
#

CC=icx
CXX=icpx
FC=ifx

FFLAGS= -fPIC -O3 -march=native -funroll-loops -std=legacy -w 
LIBS= -lmkl_rt -liomp5 -lmkl_blas95_lp64 -lpthread -lm -ldl
#CLIBS = -lm -ldl -lifcore
CLIBS = -lm -ldl

ifeq ($(PREFIX),)
    FMM_INSTALL_DIR=/usr/local/lib
endif

ifeq ($(FAST_KER),ON)
  CXXFLAGS = $(FFLAGS)
  CXXFLAGS += -std=c++11 -DSCTL_HAVE_SVML -DSCTL_PROFILE=-1
  LIBS   += -lstdc++      # add C++ runtime for static/exe links
  DYLIBS += -lstdc++      # add C++ runtime for shared lib links
endif

# used to be needed on the CXXFLAGS for weird intel compiler problems
#  -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk

OMPFLAGS = -qopenmp
OMPLIBS = -liomp5

# MATLAB interface:
FDIR=$$(dirname `gfortran --print-file-name libgfortran.dylib`)
MFLAGS +=-L${FDIR}
MEX = $(shell ls -d /Applications/MATLAB_R* | sort | tail -1)/bin/mex


