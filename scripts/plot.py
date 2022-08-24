import ast
import matplotlib
import matplotlib.pyplot as pyplot
import pathlib
import numpy as np
import sys
import pandas as pd

if __name__ == "__main__":
    data_dir = "latest"
    data_filepath = "%s/%s" % (data_dir, "performance_counters_regular.json")
    data_file = open(data_filepath, "r")

    data = ast.literal_eval(data_file.read())

    bwt_access_chunks = pd.DataFrame(
        {
            "num_accesses": data["bwt_access_chunks"],
            "index": list(range(0, len(data["bwt_access_chunks"]))),
        }
    )
    bwt_access_chunks = bwt_access_chunks.sort_values(
        by=["num_accesses"], ascending=False
    )

    # print("Max: %s" % np.max(bwt_access_chunks))
    # print("Median: %s" % np.median(bwt_access_chunks))
    # print("Mean: %s" % np.mean(bwt_access_chunks))
    # print("Std: %s" % np.std(bwt_access_chunks))

    bwt_file = open("../sample_data/Wuhan-Hu-1.bwt.bin", "rb")
    bwt_table = bwt_file.read()

    base_to_bin = {"A": "00", "C": "01", "G": "10", "T": "11"}
    bin_to_base = ["A", "C", "G", "T"]

    bwt_string = ""
    occ_table = []
    for i in range(0, len(bwt_table) - 64, 64):
        occ_table.append(
            [
                int.from_bytes(bwt_table[i : i + 7], sys.byteorder),
                int.from_bytes(bwt_table[i + 8 : i + 15], sys.byteorder),
                int.from_bytes(bwt_table[i + 16 : i + 23], sys.byteorder),
                int.from_bytes(bwt_table[i + 24 : i + 31], sys.byteorder),
            ]
        )
        for j in range(0, 32, 4):
            for k in range(0, 4)[::-1]:
                bwt_string += bin_to_base[(int(bwt_table[(i + 32) + j + k]) >> 6) & 3]
                bwt_string += bin_to_base[(int(bwt_table[(i + 32) + j + k]) >> 4) & 3]
                bwt_string += bin_to_base[(int(bwt_table[(i + 32) + j + k]) >> 2) & 3]
                bwt_string += bin_to_base[(int(bwt_table[(i + 32) + j + k]) >> 0) & 3]

    k = 18547
    print(occ_table[k >> 7])
    remainder_string = bwt_string[(k >> 7) << 7 : ((k >> 7) + 1) << 7][
        0 : (k % 128) + 1
    ]
    print(
        "A: %s, C: %s, G: %s, T: %s"
        % (
            remainder_string.count("A"),
            remainder_string.count("C"),
            remainder_string.count("G"),
            remainder_string.count("T"),
        )
    )
    splitted_remainder_string = [
        remainder_string[i : i + 32] for i in range(0, len(remainder_string), 32)
    ]
    for substr in splitted_remainder_string:
        for c in substr:
            print(base_to_bin[c], end="")
        print()

    for substr in splitted_remainder_string:
        print(substr)
    #
    # pyplot.bar(x=range(0, len(bwt_access_chunks)), height=bwt_access_chunks)
    # pyplot.savefig(
    #     pathlib.Path("%s/bwt_access_chunks.pdf" % (data_dir)).resolve(), format="pdf"
    # )
    # pyplot.close()
