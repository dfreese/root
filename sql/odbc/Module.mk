# Module.mk for odbc module
# Copyright (c) 2006 Rene Brun and Fons Rademakers
#
# Author: Fons Rademakers, 29/2/2000

MODNAME     := odbc
MODDIR      := $(ROOT_SRCDIR)/sql/$(MODNAME)
MODDIRS     := $(MODDIR)/src
MODDIRI     := $(MODDIR)/inc

ODBCDIR     := $(MODDIR)
ODBCDIRS    := $(ODBCDIR)/src
ODBCDIRI    := $(ODBCDIR)/inc

##### libODBC #####
ODBCL       := $(MODDIRI)/LinkDef.h
ODBCDS      := $(call stripsrc,$(MODDIRS)/G__ODBC.cxx)
ODBCDO      := $(ODBCDS:.cxx=.o)
ODBCDH      := $(ODBCDS:.cxx=.h)

ODBCH       := $(filter-out $(MODDIRI)/LinkDef%,$(wildcard $(MODDIRI)/*.h))
ODBCS       := $(filter-out $(MODDIRS)/G__%,$(wildcard $(MODDIRS)/*.cxx))
ODBCO       := $(call stripsrc,$(ODBCS:.cxx=.o))

ODBCDEP     := $(ODBCO:.o=.d) $(ODBCDO:.o=.d)

ODBCLIB     := $(LPATH)/libRODBC.$(SOEXT)
ODBCMAP     := $(ODBCLIB:.$(SOEXT)=.rootmap)

# used in the main Makefile
ODBCH_REL   := $(patsubst $(MODDIRI)/%.h,include/%.h,$(ODBCH))
ALLHDRS     += $(ODBCH_REL)
ALLLIBS     += $(ODBCLIB)
ALLMAPS     += $(ODBCMAP)
ifeq ($(CXXMODULES),yes)
  CXXMODULES_HEADERS := $(patsubst include/%,header \"%\"\\n,$(ODBCH_REL))
  CXXMODULES_MODULEMAP_CONTENTS += module Sql_$(MODNAME) { \\n
  CXXMODULES_MODULEMAP_CONTENTS += $(CXXMODULES_HEADERS)
  CXXMODULES_MODULEMAP_CONTENTS += "export \* \\n"
  CXXMODULES_MODULEMAP_CONTENTS += link \"$(ODBCLIB)\" \\n
  CXXMODULES_MODULEMAP_CONTENTS += } \\n
endif

# include all dependency files
INCLUDEFILES += $(ODBCDEP)

##### local rules #####
.PHONY:         all-$(MODNAME) clean-$(MODNAME) distclean-$(MODNAME)

include/%.h:    $(ODBCDIRI)/%.h
		cp $< $@

$(ODBCLIB):     $(ODBCO) $(ODBCDO) $(ORDER_) $(MAINLIBS) $(ODBCLIBDEP)
		@$(MAKELIB) $(PLATFORM) $(LD) "$(LDFLAGS)" \
		   "$(SOFLAGS)" libRODBC.$(SOEXT) $@ "$(ODBCO) $(ODBCDO)" \
		   "$(ODBCLIBEXTRA) $(ODBCLIBDIR) $(ODBCCLILIB)"

$(call pcmrule,ODBC)
	$(noop)

$(ODBCDS):     $(ODBCH) $(ODBCL) $(ROOTCLINGEXE) $(call pcmdep,ODBC)
		$(MAKEDIR)
		@echo "Generating dictionary $@..."
		$(ROOTCLINGSTAGE2) -f $@ $(call dictModule,ODBC) -c $(ODBCINCDIR:%=-I%) $(ODBCH) $(ODBCL)

$(ODBCMAP):     $(ODBCH) $(ODBCL) $(ROOTCLINGEXE) $(call pcmdep,ODBC)
		$(MAKEDIR)
		@echo "Generating rootmap $@..."
		$(ROOTCLINGSTAGE2) -r $(ODBCDS) $(call dictModule,ODBC) -c $(ODBCINCDIR:%=-I%) $(ODBCH) $(ODBCL)

all-$(MODNAME): $(ODBCLIB)

clean-$(MODNAME):
		@rm -f $(ODBCO) $(ODBCDO)

clean::         clean-$(MODNAME)

distclean-$(MODNAME): clean-$(MODNAME)
		@rm -f $(ODBCDEP) $(ODBCDS) $(ODBCDH) $(ODBCLIB) $(ODBCMAP)

distclean::     distclean-$(MODNAME)

##### extra rules ######
$(ODBCO) $(ODBCDO): CXXFLAGS += $(ODBCINCDIR:%=-I%)
ifeq ($(MACOSX_ODBC_DEPRECATED),yes)
$(ODBCO) $(ODBCDO): CXXFLAGS += -Wno-deprecated-declarations
endif
