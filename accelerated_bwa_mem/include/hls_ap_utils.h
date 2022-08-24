#ifndef ACCELERATED_BWA_MEM_HLS_AP_UTILS_H
#define ACCELERATED_BWA_MEM_HLS_AP_UTILS_H

#include <ap_int.h>

#define VUP(IDX, CELL_BITS) (CELL_BITS * (IDX) + CELL_BITS - 1)
#define VLO(IDX, CELL_BITS) (CELL_BITS * (IDX))

#define SLICE(VALUE, IDX, CELL_BITS) VALUE(VUP(IDX, CELL_BITS), VLO(IDX, CELL_BITS))
#define SLICE_OFFSET(VALUE, OFFSET_BITS, IDX, CELL_BITS) \
    VALUE(OFFSET_BITS + VUP(IDX, CELL_BITS), OFFSET_BITS + VLO(IDX, CELL_BITS))

#define INIT_FROM_AP_ELEMENT_BITS(variable) \
    variable = ap_element(offset + variable.width - 1, offset); \
    offset += variable.width

#define INIT_FROM_AP_ELEMENT_BITS_WIDTH(variable, width) \
    variable(width - 1, 0) = ap_element(offset + width - 1, offset); \
    offset += width    

#define INIT_FROM_AP_ELEMENT_BYTES(variable) \
    variable = ap_element(offset + (sizeof(variable) * 8) - 1, offset); \
    offset += (sizeof(variable) * 8)

#define STORE_INTO_AP_ELEMENT_BITS(variable) \
    ap_element(offset + variable.width - 1, offset) = variable; \
    offset += variable.width

#define STORE_INTO_AP_ELEMENT_BITS_WIDTH(variable, width) \
    ap_element(offset + width - 1, offset) = variable(width - 1, 0); \
    offset += width

#define STORE_INTO_AP_ELEMENT_BYTES(variable) \
    ap_element(offset + (sizeof(variable) * 8) - 1, offset) = variable; \
    offset += (sizeof(variable) * 8)

typedef ap_uint<1> ap_bool_t;

#endif  //ACCELERATED_BWA_MEM_HLS_AP_UTILS_H
