CC=			gcc
AR=			ar
CFLAGS+=	-std=c11 -pthread -g -O3 -DACCELERATED_BWA -DNO_WARN_X86_INTRINSICS
DFLAGS=		-DHAVE_PTHREAD
LOBJS=		$(BUILD_DIR)/utils.o $(BUILD_DIR)/kthread.o $(BUILD_DIR)/kstring.o $(BUILD_DIR)/ksw.o $(BUILD_DIR)/bwamem_extra.o $(BUILD_DIR)/bwt.o $(BUILD_DIR)/bntseq.o $(BUILD_DIR)/bwa.o $(BUILD_DIR)/bwamem.o $(BUILD_DIR)/bwamem_pair.o $(BUILD_DIR)/malloc_wrap.o
LOBJS+=		$(BUILD_DIR)/accelerator_adapter.o $(BUILD_DIR)/accelerator_performance_counters.o $(BUILD_DIR)/performance_counters.o
AOBJS=		$(BUILD_DIR)/fastmap.o $(BUILD_DIR)/bwashm.o $(BUILD_DIR)/kopen.o
PROG=		accelerated_bwa_mem
BWA_DIR=bwa
ACTION_INCLUDE_DIR=../include
BUILD_DIR=build
INCLUDES=
LDLIBS=	-lm -lz -lpthread
SUBDIRS=$(BWA_DIR)

ifeq ($(shell uname -s),Linux)
	LDLIBS += -lrt
endif

all: $(PROG)

create_dirs:
	mkdir -p build

$(BUILD_DIR)/%.o: $(BWA_DIR)/%.c | create_dirs
	$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $< -o $@

$(BUILD_DIR)/%.o: %.c | create_dirs
	$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $< -o $@

accelerated_bwa_mem.o: $(BUILD_DIR)/libbwa.a $(AOBJS) main.c
	$(CC) -c $(CFLAGS) $(DFLAGS) $(AOBJS) main.c -o $@ -L$(BUILD_DIR) -lbwa
	chmod +x $@

$(BUILD_DIR)/libbwa.a: $(LOBJS)
		$(AR) -csr $@ $(LOBJS)
		
clean_bwa:
	rm -rf accelerated_bwa_mem *.a *.o bwa/*.o bwa/*.a build/

fastmap.o: accelerator_adapter.h $(BWA_DIR)/bwa.h $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwt.h $(BWA_DIR)/bwamem.h $(BWA_DIR)/kvec.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/utils.h $(BWA_DIR)/kseq.h
bwa.o: $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwa.h $(BWA_DIR)/bwt.h $(BWA_DIR)/ksw.h $(BWA_DIR)/utils.h $(BWA_DIR)/kstring.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/kvec.h
bwa.o: $(BWA_DIR)/kseq.h
bntseq.o: $(BWA_DIR)/bntseq.h $(BWA_DIR)/utils.h $(BWA_DIR)/kseq.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/khash.h
bwt.o: $(BWA_DIR)/utils.h $(BWA_DIR)/bwt.h $(BWA_DIR)/kvec.h $(BWA_DIR)/malloc_wrap.h
bwamem.o: $(BWA_DIR)/kstring.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/bwamem.h $(BWA_DIR)/bwt.h $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwa.h $(BWA_DIR)/ksw.h $(BWA_DIR)/kvec.h
bwamem.o: $(BWA_DIR)/ksort.h $(BWA_DIR)/utils.h $(BWA_DIR)/kbtree.h
malloc_wrap.o: $(BWA_DIR)/malloc_wrap.h
utils.o: $(BWA_DIR)/utils.h $(BWA_DIR)/ksort.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/kseq.h
ksw.o: $(BWA_DIR)/ksw.h $(BWA_DIR)/malloc_wrap.h
kstring.o: $(BWA_DIR)/kstring.h $(BWA_DIR)/malloc_wrap.h
bwashm.o: $(BWA_DIR)/bwa.h $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwt.h
kopen.o: $(BWA_DIR)/malloc_wrap.h
bwamem_extra.o: $(BWA_DIR)/bwa.h $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwt.h $(BWA_DIR)/bwamem.h $(BWA_DIR)/kstring.h $(BWA_DIR)/malloc_wrap.h
bwamem_pair.o: $(BWA_DIR)/kstring.h $(BWA_DIR)/malloc_wrap.h $(BWA_DIR)/bwamem.h $(BWA_DIR)/bwt.h $(BWA_DIR)/bntseq.h $(BWA_DIR)/bwa.h kvec.h
bwamem_pair.o: $(BWA_DIR)/utils.h $(BWA_DIR)/ksw.h
accelerator_adapter.o: $(BWA_DIR)/bwt.h $(ACTION_INCLUDE_DIR)/action_aligner.h accelerator_performance_counters.h
accelerator_performance_counters.o: $(ACTION_INCLUDE_DIR)/action_aligner.h
performance_counters.o: $(BWA_DIR)/performance_counters.h

SNAP_ROOT=$(abspath ../../oc-accel)

# This is solution specific. Check if we can replace this by generics too.

accelerated_bwa_mem_libs = $(BUILD_DIR)/libbwa.a
accelerated_bwa_mem_objs = $(AOBJS)
accelerated_bwa_mem: accelerated_bwa_mem.o

projs += accelerated_bwa_mem

# If you have the host code outside of the default snap directory structure,
# change to /path/to/snap/actions/software.mk
include $(SNAP_ROOT)/actions/software.mk
