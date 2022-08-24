def print_single_character_cnt_table(c, character_group_size_bits=8):
    print("{ ", end="")
    for i in range(0, 2 ** character_group_size_bits):
        x = 0
        for j in range(0, character_group_size_bits, 2):
            x += (i >> j & 3) == c
        print("%s, " % ("{:01d}".format(x)), end="")
    print("}")


if __name__ == "__main__":
    is_big_endian = False
    bits_per_value = 8

    cnt_table = [0] * 256
    for i in range(0, 256):
        x = 0
        for j in range(0, 4):
            x |= (
                ((i & 3) == j)
                + ((i >> 2 & 3) == j)
                + ((i >> 4 & 3) == j)
                + (i >> 6 == j)
            ) << (
                (24 - (j * bits_per_value)) if is_big_endian else (j * bits_per_value)
            )
        cnt_table[i] = x

    # print("{ %s, }" % (",".join(["0x{:08x}".format(i) for i in cnt_table])))

    print_single_character_cnt_table(0, 6)
    print_single_character_cnt_table(1, 6)
    print_single_character_cnt_table(2, 6)
    print_single_character_cnt_table(3, 6)
