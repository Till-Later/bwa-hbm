def compressor_6_3():
    lut6_0 = 0
    lut6_1 = 0
    lut6_2 = 0

    for i in range(0, 64):
        num_bits_in_i = bin(i).count("1")
        lut6_0 |= ((num_bits_in_i >> 0) & 1) << i
        lut6_1 |= ((num_bits_in_i >> 1) & 1) << i
        lut6_2 |= ((num_bits_in_i >> 2) & 1) << i

    print('LUT6 [0]: X"{0:0{1}x}"'.format(lut6_0, 16))
    print('LUT6 [1]: X"{0:0{1}x}"'.format(lut6_1, 16))
    print('LUT6 [2]: X"{0:0{1}x}"'.format(lut6_2, 16))


def reference_section_to_popcount():
    lut3_a = 0
    lut3_c = 0
    lut3_g = 0
    lut3_t = 0

    for i in range(0, 8):
        lut3_a |= (1 if ((i & 1) and (i >> 1) == 0) else 0) << i
        lut3_c |= (1 if ((i & 1) and (i >> 1) == 1) else 0) << i
        lut3_g |= (1 if ((i & 1) and (i >> 1) == 2) else 0) << i
        lut3_t |= (1 if ((i & 1) and (i >> 1) == 3) else 0) << i

    print('A (0): LUT3: X"{0:0{1}x}"'.format(lut3_a, 2))
    print('C (1): LUT3: X"{0:0{1}x}"'.format(lut3_c, 2))
    print('G (2): LUT3: X"{0:0{1}x}"'.format(lut3_g, 2))
    print('T (3): LUT3: X"{0:0{1}x}"'.format(lut3_t, 2))

    print('AC: LUT6_2: X"{0:0{1}x}"'.format((lut3_c << 32) | lut3_a, 16))
    print('GT: LUT6_2: X"{0:0{1}x}"'.format((lut3_t << 32) | lut3_g, 16))


if __name__ == "__main__":
    print("### compressor_6_3 ### ")
    compressor_6_3()
    print("### reference_section_to_popcount ### ")
    reference_section_to_popcount()
