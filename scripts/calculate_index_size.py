import math

if __name__ == "__main__":
    k_step = 2
    reference_length_bp = 3099734149 * 2
    occ_cell_size_bits = 32
    cache_line_size_bytes = 128
    # Number of symbols AFTER combining into k-tuples
    # occ_row_sampling_interval = 64

    num_symbols = 4 ** k_step
    symbol_size_bits = math.log2(num_symbols)

    # reference_length_bytes = math.ceil(reference_length_bp * symbol_size_bits / 8)

    reference_length_symbols = reference_length_bp / k_step
    occ_cell_size_bytes = occ_cell_size_bits / 8
    occ_row_size_bytes = num_symbols * occ_cell_size_bytes
    occ_row_sampling_interval = (cache_line_size_bytes - occ_row_size_bytes) * (
        8 / symbol_size_bits
    )
    occ_bwt_combined_row_size = (
        occ_row_size_bytes + (occ_row_sampling_interval * symbol_size_bits) / 8
    )
    cache_line_utilization = occ_bwt_combined_row_size / cache_line_size_bytes
    num_occ_rows = math.ceil(reference_length_symbols / occ_row_sampling_interval)
    total_size_bytes = cache_line_size_bytes * num_occ_rows

    first_layer_occ_table_num_entries = math.ceil(
        reference_length_symbols / (2 ** occ_cell_size_bits)
    )
    first_layer_occ_cell_size_bytes = 4
    first_layer_occ_table_size_bytes = (
        first_layer_occ_table_num_entries
        * first_layer_occ_cell_size_bytes
        * num_symbols
    )

    print("# Configuration")
    print("k_step: %s" % f"{k_step:,}")
    print("reference_length_bp: %s" % f"{reference_length_bp:,}")
    print("occ_cell_size_bits: %s" % f"{occ_cell_size_bits:,}")
    # print("cache_line_size_bytes: %s" % f"{cache_line_size_bytes:,}")

    print("\n# Calculated")
    print("occ_row_sampling_interval: %s" % f"{occ_row_sampling_interval:,}")
    print()
    print("occ_row_size_bytes: %s" % f"{occ_row_size_bytes:,}")
    print("occ_bwt_combined_row_size: %s" % f"{occ_bwt_combined_row_size:,}")
    # print("cache_line_utilization: %s%%" % f"{cache_line_utilization*100:,}")
    print()
    print("num_occ_rows: %s" % f"{num_occ_rows:,}")
    print("total_size_bytes: %s" % f"{total_size_bytes:,}")
    print()
    print(
        "first_layer_occ_table_num_entries: %s"
        % f"{first_layer_occ_table_num_entries:,}"
    )
    print(
        "first_layer_occ_table_size_bytes: %s" % f"{first_layer_occ_table_size_bytes:,}"
    )
