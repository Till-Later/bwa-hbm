#ifndef ACCELERATED_BWA_MEM_ACTION_REG_H
#define ACCELERATED_BWA_MEM_ACTION_REG_H

#include "action_aligner.h"
#include "hls_snap_1024.H"

// TODO-TILL: Doesn't really belong here
#define MAX_NB_OF_BYTES_READ (128 * 1024)
#define LCL_MEM_MAX_SIZE (256 * 1024 * 1024)  // HBM is 256MB each
#define MAX_NB_OF_WORDS_READ_256 (MAX_NB_OF_BYTES_READ / BPERDW_256)
#define MAX_NB_OF_WORDS_READ_512 (MAX_NB_OF_BYTES_READ / BPERDW_512)
#define MAX_NB_OF_WORDS_READ_1024 (MAX_NB_OF_BYTES_READ / BPERDW_1024)

// See: https://opencapi.github.io/oc-accel-doc/user-guide/5-hls-design/
// Start address of struct action_reg: 0x100
typedef struct
{
    CONTROL Control;    /*  16 bytes */
    aligner_job_t Data; /* up to 108 bytes */
    uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(aligner_job_t)];
} action_reg;

#endif  //ACCELERATED_BWA_MEM_ACTION_REG_H
