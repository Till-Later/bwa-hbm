#!/usr/bin/python3

import matplotlib as plotlib
import matplotlib.pyplot as plt
import matplotlib.font_manager as font_manager
import numpy as np
import json
from pathlib import Path
from functional import seq
from fn import _, F
from fn.func import curried
from collections import namedtuple
import re
from enum import IntEnum
from prettytable import PrettyTable
import statistics

# pip install PyQt5
plt.switch_backend("Qt5Agg") # comment this line on MacOs

# COLORS = ["#e66101", "#5e3c99", "#fdb863", "#b2abd2"]
# COLORS = [
#     "#eb3b5a",
#     "#20bf6b",
#     "#fed330",
#     "#d1d8e0",
#     "#4b6584",
#     "#4b7bec",
#     "#a55eea",
#     "#2bcbba",
# ]
# https://flatuicolors.com/
COLORS = [
    "#303952",
    "#f7d794",
    "#e66767",
    "#f19066",
    "#63cdda",
    "#f8a5c2",
    "#546de5",
    "#ea8685",
]


class FONTSIZE(IntEnum):
    TINY = 14
    SMALL = 16
    REGULAR = 18
    LARGE = 20


BASE_FIGWIDTH = 7.275
BASE_FIGHEIGHT = 3.85


font_dirs = [Path(Path(__file__).parent / "fonts")]
font_files = font_manager.findSystemFonts(fontpaths=font_dirs)
[font_manager.fontManager.addfont(font_file) for font_file in font_files]
plotlib.rcParams["font.family"] = "Vollkorn"


def has_cflag_value(cflag, cflag_value):
    return (
        lambda d: cflag in d["configuration"]["cflags"]
        and d["configuration"]["cflags"][cflag] == cflag_value
    )


def parse_and_extend(d):
    def calculate_accelerator_monitors(iteration):
        return [
            {
                monitor_name: {
                    counter: done_monitors[monitor_name][counter]
                    - start_monitors[monitor_name][counter]
                    for counter in start_monitors[monitor_name].keys()
                }
                for monitor_name in start_monitors.keys()
            }
            for (start_monitors, done_monitors) in zip(
                iteration["start_monitors"], iteration["done_monitors"]
            )
        ]

    def get_variant(cflags):
        phases = [
            "ALIGNMENT",
            "THIRD_PASS_SEEDING",
            "SEED_SORTING",
            "SEED_CHAINING",
            "SEED_EXTENSION",
            "SEED_OUTPUT",
        ]
        for phase in phases:
            if (
                f"PHASE_EXCLUDE_{phase}" in cflags
                and cflags[f"PHASE_EXCLUDE_{phase}"] == 1
            ):
                return f"PHASE_EXCLUDE_{phase}"
        return "ALL"

    variant = get_variant(d["configuration"].get("cflags", {}))

    readable_reference_names = {
        "hg38": "GRCh38",
        "reference_256000000": "Generated (256 Mbp)",
        "reference_1000000000": "Generated (1 Gbp)",
        "reference_4000000000": "Generated (4 Gbp)",
    }
    parsed_reference_file = re.search(
        "(.+?)\/(?:sa_intv_([0-9]+)\/)?reference.fa",
        d["configuration"]["reference_file"],
    ).groups()

    reference = readable_reference_names[parsed_reference_file[0]]
    sa_intv = parsed_reference_file[-1] if len(parsed_reference_file) > 1 else 32

    readable_executable_names = {
        "bwa": "BWA-MEM",
        "accelerated_bwa_mem": "BWA-HBM",
    }
    executable = readable_executable_names[d["configuration"]["executable"]]

    num_queries = int(
        re.search(
            "(.+)/queries/(?:exact_)?sample_([0-9]+)\.fastq",
            d["configuration"]["fastq_file"],
        ).group(2)
    )

    numa_setting = (
        "SINGLE_NODE"
        if d["configuration"].get("numa_command", "") != ""
        else "ALL_NODES"
    )

    parsed_image_name = re.search(
        "(.+\/)?(.+)/cores_([0-9]+)/(.+)_([0-9]+)",
        d["configuration"].get("image_name", "None/cores_0/pipeline_id_width_0"),
    )
    image_configuration = {
        "addressing": parsed_image_name.group(2),
        "num_cores": int(parsed_image_name.group(3)),
        "id_width": int(parsed_image_name.group(5)),
    }

    accelerator_monitors = (
        seq(d["accelerator_performance_counters"]["accelerator_iterations"])
        .map(calculate_accelerator_monitors)
        .map(
            lambda iteration: seq(iteration)
            .take(image_configuration["num_cores"])
            .list()
        )
        .list()
        if "accelerator_performance_counters" in d
        else None
    )
    return {
        "reference": reference,
        "sa_intv": sa_intv,
        "num_queries": num_queries,
        "executable": executable,
        "numa_setting": numa_setting,
        "variant": variant,
        "image_configuration": image_configuration,
        "accelerator_monitors": accelerator_monitors,
        **d,
    }


def new_figure(xlabel, ylabel):
    fig, ax = plt.subplots()
    ax.set_xlabel(xlabel, fontsize=FONTSIZE.REGULAR)
    ax.set_ylabel(ylabel, fontsize=FONTSIZE.REGULAR)
    ax.tick_params(axis="both", which="major", labelsize=FONTSIZE.TINY)
    return fig, ax


def add_errorbar_and_annotation(ax, dataset, key, value):
    ax.errorbar(
        key,
        value,
        yerr=dataset["stddev"],
        capsize=5,
        color="black",
    )

    ax.annotate(
        ("{:.1f}").format(value),
        xy=(key, (value + dataset["stddev"])),
        xytext=(0, 1),
        textcoords="offset points",
        ha="center",
        va="bottom",
        fontsize=FONTSIZE.TINY,
    )


def annotate_bars(ax, bars, precision):
    for bar in bars:
        if bar.get_height() == 0:
            continue
        value = (
            str(int(bar.get_height()))
            if precision == 0
            else ("{:.%sf}" % (precision)).format(bar.get_height())
        )
        if bar.get_y() > 0:
            value = f"+ {value}"

        x = bar.get_x() + bar.get_width() / 2
        y = bar.get_y() + bar.get_height()
        ax.annotate(
            value,
            xy=(x, y),
            xytext=(0, 1),
            textcoords="offset points",
            ha="center",
            va="bottom",
            fontsize=FONTSIZE.TINY,
        )


def barplot(ax, data, label_selector, value_selector, bar_width_scale=0.9):
    labels = data.map(label_selector)
    values = data.map(value_selector)
    keys = np.arange(data.size()) - 0.5

    ax.set_xticks(keys)
    ax.set_xticklabels(labels)

    return [
        ax.bar(key, value, width=bar_width_scale, color=COLORS[0])
        for (key, value, label) in zip(keys, values, labels)
    ]


def grouped_barplot(
    ax,
    data,
    group_selector,
    label_selector,
    value_selector,
    bar_width_scale=0.9,
    group_width_scale=0.8,
    COLORS=COLORS,
    callback=None,
):
    xticks = []
    xtick_labels = []

    bars = []
    combined_labels = data.map(label_selector).distinct().list()

    for group_index, (group_key, group_values) in enumerate(
        data.group_by(group_selector).list()
    ):
        num_bars = len(group_values)
        bar_space = group_width_scale / num_bars
        bar_width = bar_space * bar_width_scale

        group_x_offset = -(group_width_scale / 2) + (bar_space / 2) + (group_index)

        values = list(map(value_selector, group_values))
        labels = list(map(label_selector, group_values))
        keys = list(
            map(lambda index: group_x_offset + (index * bar_space), range(len(values)))
        )

        for (dataset, key, value, label) in zip(group_values, keys, values, labels):
            label_color = COLORS[combined_labels.index(label)]
            bar = ax.bar(key, value, width=bar_width, color=label_color)
            bars.append(bar)

        if callback is not None:
            for (dataset, key, value, label) in zip(group_values, keys, values, labels):
                callback(ax, dataset, key, value)

        xticks.append(group_index)
        xtick_labels.append(group_key)

    ax.set_xticks(xticks)
    ax.set_xticklabels(xtick_labels)

    return bars, combined_labels


def grouped_stacked_barplot(
    ax,
    data,
    group_selector,
    stack_selector,
    label_selector,
    value_selector,
    sum_values=False,
    bar_width_scale=0.9,
    group_width_scale=0.8,
    property_map={},
    callback=None,
):
    xticks = []
    xtick_labels = []

    bars = []
    combined_labels = data.map(label_selector).distinct().list()

    for group_index, (group_key, group_values) in enumerate(
        data.group_by(group_selector).list()
    ):
        xticks.append(group_index)
        xtick_labels.append(group_key)

        num_bars_in_group = len(
            seq(group_values).group_by(stack_selector).first().list()[1]
        )
        bar_space = group_width_scale / num_bars_in_group
        bar_width = bar_space * bar_width_scale
        group_x_offset = -(group_width_scale / 2) + (bar_space / 2) + (group_index)

        stacks = seq(group_values).group_by(stack_selector)
        num_stacks = stacks.first()[1].size()

        stack_sums = [0] * num_stacks

        for stack_index, (stack_key, stack_values) in enumerate(stacks.list()):
            y_offsets = stack_sums
            if sum_values:
                values = seq(stack_values).map(value_selector).list()
                stack_sums = (
                    seq(stack_values)
                    .map(value_selector)
                    .zip(stack_sums)
                    .starmap(_ + _)
                    .list()
                )
            else:
                values = (
                    seq(stack_values)
                    .map(value_selector)
                    .zip(stack_sums)
                    .starmap(_ - _)
                    .list()
                )
                stack_sums = seq(stack_values).map(value_selector).list()

            labels = seq(stack_values).map(label_selector).list()
            keys = group_x_offset + (np.arange(len(stack_values)) * bar_space)
            label_colors = (
                seq(labels).map(lambda l: COLORS[combined_labels.index(l)]).list()
            )
            special_properties = (
                seq(labels).map(lambda l: property_map.get(l, {})).list()
            )
            for key, value, label_color, y_offset, props in zip(
                keys, values, label_colors, y_offsets, special_properties
            ):
                bars.append(
                    ax.bar(
                        key,
                        value,
                        y=y_offset,
                        width=bar_width,
                        color=label_color,
                        zorder=10 + num_stacks - stack_index,
                        **props,
                    )
                )

            if callback is not None:
                for (dataset, key, value, y_offset) in zip(
                    stack_values, keys, values, y_offsets
                ):
                    callback(ax, dataset, key, value, y_offset)

    ax.set_xticks(xticks)
    ax.set_xticklabels(xtick_labels)

    return bars, combined_labels


def print_table(data, columns):
    t = PrettyTable()
    t.field_names = columns
    rows = data.map(
        lambda d: seq(columns).map(lambda column: getattr(d, column)).list()
    ).list()
    t.add_rows(rows)
    print(t)


def pretty_print(data):
    print(json.dumps(data, indent=4))


def events_to_timespans(event_list, executable):
    step_num_to_step_name = {
        "BWA-MEM": ["input", "remaining", "output"],
        "BWA-HBM": ["input", "accelerated", "remaining", "output"],
    }

    event_tuples = (
        seq(event_list)
        .map(
            lambda e: namedtuple("Event", "is_start_event time step")(
                e["is_start_event"],
                e["time"] / 1000,
                e["step"],
            )
        )
        .order_by(lambda el: (el.time))
    )

    timespans = []
    start_time = event_tuples.first().time
    num_steps = event_tuples.map(_.step).distinct().size()
    opened_events = [None] * num_steps

    for event in event_tuples:
        if event.is_start_event:
            opened_events[event.step] = event
        else:
            assert (
                opened_events[event.step] is not None
            ), "Found closing event for inactive step"
            timespans.append(
                namedtuple("Timespan", "step_num step_name start done duration")(
                    event.step,
                    step_num_to_step_name[executable][event.step],
                    opened_events[event.step].time - start_time,
                    event.time - start_time,
                    event.time - opened_events[event.step].time,
                )
            )
            opened_events[event.step] = None

    return timespans


class LegendTitle(object):
    def __init__(self, text_props=None):
        self.text_props = text_props or {}
        super(LegendTitle, self).__init__()

    def legend_artist(self, legend, orig_handle, fontsize, handlebox):
        x0, y0 = handlebox.xdescent, handlebox.ydescent
        title = plotlib.text.Text(x0, y0, orig_handle, usetex=True, **self.text_props)
        handlebox.add_artist(title)
        return title


def plot_bit_partitioning(benchmark_data):
    def calculate_relative_bandwidth_lost(c):
        return (
            seq(np.diff(seq(c).sorted().list()))
            .map(_ / seq(c).max())
            .enumerate(start=1)
            .starmap(_ + _)
            .sum()
            * 100
            / len(c)
        )

    partition_bit_width = 4
    runs = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(
            has_cflag_value(
                "PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS",
                partition_bit_width,
            )
        )
        .map(
            lambda d: {
                "reference": d["reference"],
                "offset_bits": d["configuration"]["cflags"][
                    "PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS"
                ],
                "forward": d["performance_counters"]["bwt_forward_access_chunks"],
                "backward": d["performance_counters"]["bwt_backward_access_chunks"],
                "combined": np.array(
                    d["performance_counters"]["bwt_forward_access_chunks"]
                )
                + np.array(d["performance_counters"]["bwt_backward_access_chunks"]),
            }
        )
        .filter(_["offset_bits"] < 25)
        .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        # .filter(_.reference == "GRCh38")
        .group_by(_["reference"])
    )

    fig, ax = new_figure("Partition bit offset", "Bandwidth lost (%)")
    ax.xaxis.set_major_locator(plotlib.ticker.MaxNLocator(integer=True))

    linestyles = ["-", "--"]
    access_types = ["forward", "combined", "backward"]
    for reference_index, (reference, data) in enumerate(runs):
        for access_type_index, access_type in enumerate(access_types):
            keys = seq(data).map(_["offset_bits"]).list()
            values = (
                seq(data)
                .map(_[access_type])
                .map(calculate_relative_bandwidth_lost)
                .list()
            )

            ax.plot(
                keys,
                values,
                color=COLORS[access_type_index],
                linestyle=linestyles[reference_index],
                linewidth=2,
                marker=".",
            )[0]

    reference_legend_handles = [
        plotlib.lines.Line2D([], [], color="black", linestyle=linestyles[i])
        for i in range(runs.size())
    ]
    reference_legend_labels = seq(runs).map(_[0]).list()

    ax.legend(
        handles=reference_legend_handles,
        labels=reference_legend_labels,
        # handler_map={str: LegendTitle()},
        fontsize=FONTSIZE.TINY,
        loc="upper right",
        bbox_to_anchor=(1, 1.1),
        ncol=3,
        framealpha=1,
    )

    access_type_legend_handles = [
        plotlib.patches.Patch(color=COLORS[i]) for i in range(len(access_types))
    ]
    access_type_legend_labels = access_types

    access_type_legend = plotlib.legend.Legend(
        ax,
        handles=[""] + access_type_legend_handles,
        labels=["Access type"] + access_type_legend_labels,
        handler_map={str: LegendTitle()},
        fontsize=FONTSIZE.TINY,
        loc="upper right",
        bbox_to_anchor=(1, 0.95),
    )
    ax.add_artist(access_type_legend)

    fig.set_figwidth(BASE_FIGWIDTH)
    fig.set_figheight(BASE_FIGHEIGHT * (7 / 8))

    return [(f"partition_bit_width_{partition_bit_width}", fig)]


def plot_most_frequent_coverage(data):
    runs = (
        seq(data)
        .map(parse_and_extend)
        # .filter(_["reference"] == "GRCh38")
        .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        .map(
            lambda d: {
                "reference": d["reference"],
                "forward": {
                    "freq_chunks": d["performance_counters"][
                        "most_frequent_bwt_forward_access_chunks"
                    ],
                    "accesses": d["performance_counters"]["num_bwt_forward_accesses"],
                },
                "backward": {
                    "freq_chunks": d["performance_counters"][
                        "most_frequent_bwt_backward_access_chunks"
                    ],
                    "accesses": d["performance_counters"]["num_bwt_backward_accesses"],
                },
                "combined": {
                    "freq_chunks": d["performance_counters"][
                        "most_frequent_bwt_access_chunks"
                    ],
                    "accesses": d["performance_counters"]["num_bwt_forward_accesses"]
                    + d["performance_counters"]["num_bwt_backward_accesses"],
                },
            }
        )
        .group_by(_["reference"])
    )

    fig, ax = new_figure(
        "# most frequently accesssd occurence table rows", "Coverage (%)"
    )

    lines = []
    linestyles = ["-", "--"]
    access_types = ["forward", "combined", "backward"]
    for reference_index, (reference, data) in enumerate(runs):
        for access_type_index, access_type in enumerate(access_types):
            values = (
                seq(np.cumsum(data[0][access_type]["freq_chunks"]))
                .map((_ * 100 / data[0][access_type]["accesses"]))
                .list()
            )

            line = ax.plot(
                values,
                color=COLORS[access_type_index],
                linestyle=linestyles[reference_index],
                linewidth=2,
            )[0]
            lines.append(line)

    reference_legend_handles = [
        plotlib.lines.Line2D([], [], color="black", linestyle=linestyles[i])
        for i in range(runs.size())
    ]
    reference_legend_labels = seq(runs).map(_[0]).list()

    access_type_legend_handles = [
        plotlib.patches.Patch(color=COLORS[i]) for i in range(len(access_types))
    ]
    access_type_legend_labels = access_types

    ax.legend(
        handles=reference_legend_handles,
        labels=reference_legend_labels,
        fontsize=FONTSIZE.TINY,
        loc="upper left",
        bbox_to_anchor=(0, 1.1),
        handler_map={str: LegendTitle()},
        framealpha=1,
        ncol=3,
    )

    access_type_legend = plotlib.legend.Legend(
        ax,
        handles=[""] + access_type_legend_handles,
        labels=["Access type"] + access_type_legend_labels,
        handler_map={str: LegendTitle()},
        fontsize=FONTSIZE.TINY,
        loc="lower right",
        ncol=2
        # bbox_to_anchor=(1, 1),
    )
    ax.add_artist(access_type_legend)

    # left, right = ax.get_xlim()
    # ax.set_xlim(left, right * 1.1)

    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.05)

    fig.set_figwidth(BASE_FIGWIDTH)
    fig.set_figheight(BASE_FIGHEIGHT * (7 / 8))

    return [("most_frequent_coverage", fig)]


def plot_num_threads(benchmark_data):
    fig, ax = new_figure("Number of threads", "Runtime (s)")
    ax.set_title("Runtime by number of threads")
    lines = (
        seq(benchmark_data)
        .map(
            lambda d: namedtuple("AxisTuple", "executable num_threads duration")(
                d["configuration"]["executable"],
                int(
                    re.search("-t ([0-9]+)", d["configuration"]["run_options"]).group(1)
                ),
                d["duration"],
            )
        )
        .sorted(_.num_threads)
        .group_by(_.executable)
        .map(
            lambda t: ax.plot(
                list(map(_.num_threads, t[1])),
                list(map(_.duration, t[1])),
                label=t[0],
                linewidth=2,
                marker=".",
            )[0]
        )
        .list()
    )
    bwa_base_runtime = (
        seq(benchmark_data)
        .filter(_["configuration"]["executable"] == "bwa")
        .filter(_["configuration"]["run_options"] == "-t 8")
        .map(_["duration"])
    )[0]
    x = list(range(8, 97, 1))
    y = seq(x).map(bwa_base_runtime * 8 / _).list()
    lines.append(
        plt.plot(x, y, "b", label="Perfect scaling (bwa)", linestyle="dashed")[0]
    )

    ax.legend(handles=lines)

    return [("experiment_num_threads", fig)]


def plot_runtime(benchmark_data):
    fig, ax = new_figure("Number of queries", "Runtime (s)")
    ax.set_title(f"Runtime by query size")

    lines = (
        seq(benchmark_data)
        .filter(_["configuration"]["reference_file"] == "hg38/reference.fa")
        .map(
            lambda d: namedtuple("AxisTuple", "executable query_size duration")(
                d["configuration"]["executable"],
                int(
                    re.search(
                        "(.+)/queries/sample_([0-9]+)\.fastq",
                        d["configuration"]["fastq_file"],
                    ).group(2)
                ),
                d["duration"],
            )
        )
        .sorted(_.query_size)
        .group_by(_.executable)
        .map(
            lambda t: ax.plot(
                list(map(_.query_size, t[1])),
                list(map(_.duration, t[1])),
                label=t[0],
                linewidth=2,
                marker=".",
            )[0]
        )
        .list()
    )
    ax.legend(handles=lines)

    return [("experiment_runtime", fig)]


def plot_runtime_comparison_end_to_end(benchmark_data):
    fig, ax = new_figure("Reference", "Runtime (s)")

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(lambda d: namedtuple("AxisTuple", d)(**d))
        .filter(_.num_queries == int(5e7))
        .filter(_.numa_setting == "ALL_NODES")
        .filter(lambda d: d.reference in ["GRCh38", "Generated (4 Gbp)"])
        .sorted(_.executable, reverse=True)
    )
    bars, labels = grouped_barplot(ax, data, _.reference, _.executable, _.duration)

    ax.legend(
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.2),
        ncol=3,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )
    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.35)

    [annotate_bars(ax, bar, 0) for bar in bars]

    fig.set_figheight(BASE_FIGHEIGHT * (2 / 4))

    return [("runtime_comparison_end_to_end", fig)]


def plot_runtime_variants(benchmark_data):
    def add_errorbar(ax, dataset, key, value, y_offset):
        ax.errorbar(
            key,
            value + y_offset,
            yerr=dataset["stddev"],
            capsize=5,
            color="black",
        )

    variant_name_map = {
        "PHASE_EXCLUDE_ALIGNMENT": "input",
        "PHASE_EXCLUDE_THIRD_PASS_SEEDING": "+ 1st + 2nd pass",
        "PHASE_EXCLUDE_SEED_SORTING": "+ 3rd pass",
        # "PHASE_EXCLUDE_SEED_CHAINING": "+ sorting",
        "PHASE_EXCLUDE_SEED_EXTENSION": "+ chaining",
        "PHASE_EXCLUDE_SEED_OUTPUT": "+ extension",
        "ALL": "+ output gen.",
    }
    variant_name_map = {
        key: f"{index + 1} {value}"
        for index, (key, value) in enumerate(variant_name_map.items())
    }

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(
            lambda d: {**d, "variant_name": variant_name_map.get(d["variant"], "HIDE")}
        )
        .filter(_["variant_name"] != "HIDE")
        # .filter(_.num_queries == int(5e7))
        .filter(lambda t: "1" not in t["configuration"]["run_options"].split(" -"))
        .group_by(lambda d: (d["reference"], d["variant"], d["executable"]))
        .starmap(
            lambda key, group: {
                **group[0],
                "duration": seq(group).map(_["duration"]).average(),
                "stddev": statistics.stdev(seq(group).map(_["duration"]).list()),
            }
        )
        .sorted(_["variant_name"])
    )

    # print_table(
    #     data.sorted(_["reference"]),
    #     ["reference", "executable", "hostname", "variant_name", "duration"],
    # )

    executables = data.map(_["executable"]).distinct().make_string(",")
    fig, ax = new_figure(f"Reference [{executables}]", "Runtime (s)")

    bars, labels = grouped_stacked_barplot(
        ax,
        seq(data),
        _["reference"],
        _["variant"],
        _["variant_name"],
        _["duration"],
        callback=add_errorbar,
    )
    legend_elements = [
        plotlib.patches.Patch(color=COLORS[label_index], label=label)
        for label_index, label in enumerate(
            seq(data).map(_["variant_name"]).distinct().list()
        )
    ]
    ax.legend(
        handles=legend_elements[::-1],
        loc="upper right",
        ncol=1,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )
    # bottom, top = ax.get_ylim()
    # ax.set_ylim(bottom, top * 1.2)

    # [annotate_bars(ax, bar, 0) for bar in bars]

    # fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
    return [(f"runtime_variants_combined", fig)]


def plot_runtime_sa_decompression(benchmark_data):
    variant_name_map = {
        "PHASE_EXCLUDE_ALIGNMENT": "input",
        "PHASE_EXCLUDE_THIRD_PASS_SEEDING": "+ 1st + 2nd pass",
        "PHASE_EXCLUDE_SEED_SORTING": "+ 3rd pass",
        # "PHASE_EXCLUDE_SEED_CHAINING": "+ sorting",
        "PHASE_EXCLUDE_SEED_EXTENSION": "+ chaining",
        "PHASE_EXCLUDE_SEED_OUTPUT": "+ extension",
        "ALL": "+ output gen.",
    }
    variant_name_map = {
        key: f"{index + 1} {value}"
        for index, (key, value) in enumerate(variant_name_map.items())
    }

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(
            lambda d: {**d, "variant_name": variant_name_map.get(d["variant"], "HIDE")}
        )
        .filter(_["variant_name"] != "HIDE")
        # .filter(_["reference"] == "Generated (4 Gbp)")
        .filter(_["reference"] == "GRCh38")
        .map(lambda d: namedtuple("AxisTuple", d)(**d))
        .filter(_.num_queries == int(5e7))
        .filter(lambda t: "1" not in t.configuration["run_options"].split(" -"))
        .sorted(_.variant_name)
        .cache()
    )

    sa_intervals = data.map(_.sa_intv).distinct().make_string(",")
    fig, ax = new_figure(f"Suffix Array Sampling Rate [{sa_intervals}]", "Runtime (s)")

    bars, labels = grouped_stacked_barplot(
        ax, seq(data), _.executable, _.variant, _.variant_name, _.duration
    )
    legend_elements = [
        plotlib.patches.Patch(color=COLORS[label_index], label=label)
        for label_index, label in enumerate(
            seq(data).map(_.variant_name).distinct().list()
        )
    ]
    # ax.legend(
    #     handl`scripts/benchmarks/benchmark.py`2)

    # [annotate_bars(ax, bar, 0) for bar in bars]

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
    return [(f"runtime_sa_decompression", fig)]


def plot_speedup_no_offloading(benchmark_data):
    @curried
    def calculate_step_durations(steps, d):
        timespans = events_to_timespans(
            d["performance_counters"]["process_iteration_events"],
            d["executable"],
        )

        step_durations = {}
        last_step_duration = 0
        for step_name in steps:
            step_durations[step_name] = last_step_duration + (
                seq(timespans).filter(_.step_name == step_name).map(_.duration).sum()
            )
            last_step_duration = step_durations[step_name]

        return {
            **d,
            "timespans": timespans,
            "step_durations": step_durations,
        }

    figures = []

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["num_queries"] == int(5e7))
        # .filter(_["reference"] == "Generated (4 Gbp)")
        .filter(lambda d: "1" in d["configuration"]["run_options"].split(" -"))
        .filter(
            lambda d: d["variant"]
            in ["PHASE_EXCLUDE_SEED_CHAINING", "PHASE_EXCLUDE_THIRD_PASS_SEEDING"]
        )
        .map(calculate_step_durations(["accelerated", "remaining"]))
        .sorted(_["executable"], reverse=True)
        .map(
            lambda run: seq(
                seq(run["step_durations"].items()).map(
                    lambda t: namedtuple(
                        "StepTuple",
                        "run_id executable reference variant step_name ns_per_query",
                    )(
                        run["global_run_id"],
                        run["executable"],
                        run["reference"],
                        run["variant"],
                        t[0],
                        t[1] * 1000000 / run["num_queries"],
                    )
                )
            )
        )
        .flatten()
        .sorted(_.step_name)
        .cache()
    )

    StackTuple = namedtuple(
        "StackTuple", "executable reference stack step_ns_per_query"
    )
    prepared_data = []
    for reference, reference_data in data.group_by(_.reference).list():
        prepared_data += [
            StackTuple("BWA-MEM", reference, "1st + 2nd pass\n(accelerator)", 0),
            StackTuple(
                "BWA-HBM",
                reference,
                "1st + 2nd pass\n(accelerator)",
                seq(reference_data)
                .find(
                    lambda d: d.executable == "BWA-HBM"
                    and d.step_name == "accelerated"
                    and d.variant == "PHASE_EXCLUDE_THIRD_PASS_SEEDING"
                )
                .ns_per_query,
            ),
            StackTuple(
                "BWA-MEM",
                reference,
                "1st + 2nd pass",
                seq(reference_data)
                .find(
                    lambda d: d.executable == "BWA-MEM"
                    and d.step_name == "remaining"
                    and d.variant == "PHASE_EXCLUDE_THIRD_PASS_SEEDING"
                )
                .ns_per_query,
            ),
            StackTuple(
                "BWA-HBM",
                reference,
                "1st + 2nd pass",
                seq(reference_data)
                .find(
                    lambda d: d.executable == "BWA-HBM"
                    and d.step_name == "remaining"
                    and d.variant == "PHASE_EXCLUDE_THIRD_PASS_SEEDING"
                )
                .ns_per_query,  # if reference != "Generated (4 Gbp)" else 0, # Ignore this phase since it has no workload
            ),
            StackTuple(
                "BWA-MEM",
                reference,
                "3rd pass",
                seq(reference_data)
                .find(
                    lambda d: d.executable == "BWA-MEM"
                    and d.step_name == "remaining"
                    and d.variant == "PHASE_EXCLUDE_SEED_CHAINING"
                )
                .ns_per_query,
            ),
            StackTuple(
                "BWA-HBM",
                reference,
                "3rd pass",
                seq(reference_data)
                .find(
                    lambda d: d.executable == "BWA-HBM"
                    and d.step_name == "remaining"
                    and d.variant == "PHASE_EXCLUDE_SEED_CHAINING"
                )
                .ns_per_query,
            ),
        ]

    # pretty_print(seq(prepared_data).group_by(_.stack).list())
    # print_table(seq(prepared_data), ["executable", "reference", "stack", "step_ns_per_query"])

    executables = data.map(_.executable).distinct().make_string(",")
    fig, ax = new_figure(f"Executable [{executables}]", "µs per query")
    ax.yaxis.set_major_locator(plotlib.ticker.MultipleLocator(base=1))
    # ax.grid(visible=True, axis="y")

    bars, labels = grouped_stacked_barplot(
        ax,
        seq(prepared_data),
        _.reference,
        _.stack,
        _.stack,
        _.step_ns_per_query,
        property_map={
            "1st + 2nd pass\n(accelerator)": {
                "hatch": "xx",
                "facecolor": COLORS[1],
                "edgecolor": "black",
            }
        },
    )

    # [annotate_bars(ax, bar, 1) for bar in bars]

    legend_elements = [
        plotlib.patches.Patch(color=COLORS[label_index], label=label)
        for label_index, label in enumerate(
            seq(prepared_data).map(_.stack).distinct().list()
        )
    ]

    legend_elements = [
        # plotlib.patches.Patch(color=COLORS[0], label="1st + 2nd (accelerator)"),
        plotlib.patches.Patch(color=COLORS[1], label="1st + 2nd"),
        plotlib.patches.Patch(color=COLORS[2], label="3rd"),
        plotlib.patches.Patch(
            hatch="xx", fill=False, edgecolor="black", label="accelerator"
        ),
    ]

    ax.legend(
        handles=legend_elements,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.15),
        ncol=3,
        framealpha=1,
        handletextpad=0.4,
        columnspacing=1,
        fontsize=FONTSIZE.SMALL,
    )
    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.1)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
    figures.append(("speedup_no_offloading", fig))

    return figures


def plot_numa_effects(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(lambda d: namedtuple("AxisTuple", d)(**d))
        .filter(_.num_queries == int(2e7))
        .filter(lambda d: d.reference in ["GRCh38", "Generated (4 Gbp)"])
    )
    figures = []

    # print_table(
    #     data,
    #     ["reference", "executable", "variant", "numa_setting", "duration"],
    # )

    for (reference, reference_data) in data.group_by(_.reference):
        for (variant, variant_data) in seq(reference_data).group_by(_.variant):

            fig, ax = new_figure("Reference", "Runtime (s)")

            bars, labels = barplot(
                ax, seq(variant_data), _.executable, _.numa_setting, _.duration
            )

            ax.legend(
                labels,
                loc="upper center",
                bbox_to_anchor=(0.5, 1.15),
                ncol=3,
                framealpha=1,
                fontsize=FONTSIZE.SMALL,
            )
            bottom, top = ax.get_ylim()
            ax.set_ylim(bottom, top * 1.2)

            [annotate_bars(ax, bar, 0) for bar in bars]

            fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
            figures.append((f"numa_effects/runtime_{reference}_{variant}", fig))

    return figures


def plot_runtime_phases(benchmark_data):
    executable = "BWA-HBM"
    fig, ax = new_figure(f"Time (s)", "Phase")
    # reference = "GRCh38"
    reference = "Generated (4 Gbp)"
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["reference"] == reference)
        .filter(_["executable"] == "BWA-HBM")
        .filter(_["variant"] == "ALL")
        # .filter(_["numa_setting"] == "ALL_NODES")
        .map(lambda d: namedtuple("AxisTuple", d)(**d))
        .first()
    )

    timespans = events_to_timespans(
        data.performance_counters["process_iteration_events"], executable
    )

    keys = []
    labels = []
    for (step_num, step) in seq(timespans).group_by(_.step_num):
        keys.append(0.5 + step_num)
        label = seq(step).map(_.step_name).first()
        labels.append(label)
        ax.broken_barh(
            seq(step)
            .map(
                lambda timespan: (
                    timespan.start,
                    timespan.done - timespan.start,
                )
            )
            .list(),
            (0.1 + step_num, 0.8),
            edgecolor="black",
            label=label,
            facecolor=COLORS[step_num],
        )

    ax.set_yticks(keys)
    ax.set_yticklabels(labels)
    # ax.legend()

    fig.set_figheight(BASE_FIGHEIGHT * (2 / 4))
    return [(f"runtime_phases_{reference}", fig)]


def calculate_core_hbm_utilization(core_monitors):
    clock_rate = 2e8
    gb_per_active_cycle = 64 / 1e9

    req_bwt_stream = core_monitors["req_bwt_position_stream_source"]
    active_cycles = req_bwt_stream["active"]
    total_cycles = sum(req_bwt_stream.values())

    if total_cycles == 0:
        return 0

    payload_gb = active_cycles * gb_per_active_cycle
    seconds = total_cycles / clock_rate

    return payload_gb / seconds


def add_overall_bandwidth(d):
    chunk_bandwidths = seq(d["accelerator_monitors"]).map(
        F() >> (map, calculate_core_hbm_utilization) >> sum
    )
    return {
        **d,
        "bandwidth": chunk_bandwidths.average(),
        # "stddev": statistics.stdev(chunk_bandwidths.list()),
    }


def plot_pipeline_depth(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(lambda d: not has_cflag_value("EXCLUDE_SMEM_EXTENSION", 1)(d))
        .map(
            lambda d: {
                **d,
                "num_ids": 2 ** d["image_configuration"]["id_width"],
                "bandwidth": seq(d["accelerator_monitors"])
                .map(
                    lambda iteration_monitors: (
                        seq(iteration_monitors)
                        .map(calculate_core_hbm_utilization)
                        .average()
                    )
                )
                .average(),
                "stddev": statistics.stdev(
                    seq(d["accelerator_monitors"])
                    .map(
                        lambda iteration_monitors: seq(iteration_monitors)
                        .map(calculate_core_hbm_utilization)
                        .average()
                    )
                    .list()
                ),
            }
        )
        .group_by(lambda d: (d["num_ids"], d["reference"]))
        .starmap(
            lambda key, group: {
                **group[0],
                "bandwidth": seq(group).map(_["bandwidth"]).average(),
                "stddev": statistics.stdev(seq(group).map(_["bandwidth"]).list()),
            }
        )
        # .map(lambda d: {**d, "average_duration": d["accelerator_durations"].average()})
    )

    fig, ax = plt.subplots()
    ax.yaxis.set_major_locator(plotlib.ticker.MultipleLocator(base=2))

    ax.set_xlabel(f"Number of Pipeline IDs per core", fontsize=FONTSIZE.REGULAR)
    ax.set_ylabel("GB/s per core", fontsize=FONTSIZE.REGULAR)
    ax.tick_params(axis="both", which="major", labelsize=FONTSIZE.TINY)

    (bars, labels) = grouped_barplot(
        ax,
        data,
        _["num_ids"],
        _["reference"],
        _["bandwidth"],
        callback=add_errorbar_and_annotation,
    )

    ax.legend(
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.15),
        ncol=3,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )

    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.2)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))

    return [("bandwidth_pipeline_id_width", fig)]


def plot_hbm_id_width(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(add_overall_bandwidth)
        .group_by(lambda d: (d["image_configuration"]["id_width"], d["reference"]))
        .starmap(
            lambda key, group: {
                **group[0],
                "bandwidth": seq(group).map(_["bandwidth"]).average(),
                "stddev": statistics.stdev(seq(group).map(_["bandwidth"]).list()),
            }
        )
        .map(lambda d: {**d, "num_ids": 2 ** d["image_configuration"]["id_width"]})
    )

    fig, ax = new_figure("Number of HBM IDs", "GB/s total")

    bars, labels = grouped_barplot(
        ax,
        data,
        _["num_ids"],
        _["reference"],
        _["bandwidth"],
        callback=add_errorbar_and_annotation,
    )

    ax.legend(
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.15),
        ncol=3,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )

    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.2)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))

    return [("bandwidth_hbm_id_width", fig)]


def plot_num_cores(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .sorted(_["image_configuration"]["num_cores"])
        .map(add_overall_bandwidth)
        .group_by(lambda d: (d["image_configuration"]["num_cores"], d["reference"]))
        .starmap(
            lambda key, group: {
                **group[0],
                "bandwidth": seq(group).map(_["bandwidth"]).average(),
                "stddev": statistics.stdev(seq(group).map(_["bandwidth"]).list()),
            }
        )
    )

    fig, ax = new_figure("Number of Cores", "GB/s total")

    bars, labels = grouped_barplot(
        ax,
        data,
        _["image_configuration"]["num_cores"],
        _["reference"],
        _["bandwidth"],
        callback=add_errorbar_and_annotation,
    )

    ax.legend(
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.15),
        ncol=3,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )

    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.2)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))

    return [("bandwidth_num_cores", fig)]


def plot_forward_extension(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["executable"] == "BWA-HBM")
        .filter(_["reference"] == "GRCh38")
        # .filter(_["image_configuration"]["num_cores"] == 4)
        .map(add_overall_bandwidth)
    )
    pretty_print(data.map(_["configuration"]["reference_file"]).list())

    fig, ax = new_figure("Query type", "GB/s total")

    bars, labels = grouped_barplot(
        ax, data, _["configuration"]["fastq_file"], _["reference"], _["bandwidth"]
    )

    [annotate_bars(ax, bar, 0) for bar in bars]

    ax.legend(
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.15),
        ncol=3,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )

    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.2)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))

    return [("bandwidth_forward_extension", fig)]


def plot_addressing(benchmark_data):
    order_map = {
        ("local_addressing", "Generated (256 Mbp)"): 0,
        ("first_layer_crossbar", "Generated (256 Mbp)"): 1,
        ("first_layer_crossbar", "Generated (1 Gbp)"): 2,
        ("second_layer_crossbar", "Generated (256 Mbp)"): 3,
        ("second_layer_crossbar", "Generated (1 Gbp)"): 4,
        ("second_layer_crossbar", "Generated (4 Gbp)"): 5,
        ("second_layer_crossbar", "GRCh38"): 6,
    }

    readable_addressing_names = {
        "local_addressing": "No Interconnect",
        "first_layer_crossbar": "Single-layer\nInterconnect",
        "second_layer_crossbar": "Two-layer\nInterconnect",
    }

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(lambda d: d["reference"] not in ["GRCh38", "Generated (4 Gbp)"])
        .sorted(_["image_configuration"]["num_cores"])
        .sorted(
            lambda d: order_map[
                (d["image_configuration"]["addressing"], d["reference"])
            ]
        )
        .map(add_overall_bandwidth)
        .map(
            lambda d: {
                **d,
                "addressing_name": readable_addressing_names[
                    d["image_configuration"]["addressing"]
                ],
            }
        )
        # .group_by(lambda d: (d["addressing_name"], d["reference"]))
        # .starmap(
        #     lambda key, group: {
        #         **group[0],
        #         "bandwidth": seq(group).map(_["bandwidth"]).average(),
        #         "stddev": statistics.stdev(seq(group).map(_["bandwidth"]).list()),
        #     }
        # )
    )

    core_configurations = (
        data.map(_["image_configuration"]["num_cores"]).distinct().make_string(",")
    )
    fig, ax = new_figure(
        f"Interconnect configuration [{core_configurations} cores]", "GB/s total"
    )

    bars, labels = grouped_barplot(
        ax,
        data,
        _["addressing_name"],
        _["reference"],
        _["bandwidth"],
        COLORS=COLORS[:4][::-1],
        # callback=add_errorbar_and_annotation,
        group_width_scale=0.9,
    )

    [annotate_bars(ax, bar, 1) for bar in bars]

    legend_elements = [
        plotlib.patches.Patch(color=COLORS[:4][::-1][label_index], label=label)
        for label_index, label in enumerate(data.map(_["reference"]).distinct().list())
    ]

    ax.legend(
        handles=legend_elements,
        loc="upper center",
        bbox_to_anchor=(0.5, 1.25),
        ncol=2,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )
    bottom, top = ax.get_ylim()
    ax.set_ylim(bottom, top * 1.15)

    fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))

    return [("bandwidth_addressing", fig)]


def avg_by_key(dicts):
    return (
        seq(dicts)
        .map(lambda d: d.items())
        .flatten()
        .group_by_key()
        .starmap(lambda key, values: (key, statistics.mean(values)))
        .to_dict()
    )


@curried
def calculate_cycle_distribution_for_core(stream_name, core_monitors):
    source_monitors = core_monitors[f"{stream_name}_source"]
    sink_monitors = core_monitors[f"{stream_name}_sink"]
    source_idle_or_slave_stall = source_monitors["idle_or_slave_stall"]
    source_master_stall = source_monitors["master_stall"]
    source_active = source_monitors["active"]

    sink_idle_or_slave_stall = sink_monitors["idle_or_slave_stall"]
    sink_master_stall = sink_monitors["master_stall"]
    sink_active = sink_monitors["active"]

    all_cycles = max(1, sink_idle_or_slave_stall + sink_master_stall + sink_active)

    buffer_empty_cycles = sink_idle_or_slave_stall
    buffer_full_cycles = source_idle_or_slave_stall
    buffer_partially_full_cycles = all_cycles - buffer_empty_cycles - buffer_full_cycles

    cycles = {
        "full": buffer_full_cycles,
        "available": buffer_partially_full_cycles,
        "empty": buffer_empty_cycles,
        "active": source_active,
    }

    return {key: value * 100 / all_cycles for key, value in cycles.items()}


def calculate_cycle_distribution_for_stream(stream, accelerator_monitors):
    averaged_cycles_per_iteration = (
        seq(accelerator_monitors)
        .map(F() >> (map, calculate_cycle_distribution_for_core(stream)) >> list)
        .map(avg_by_key)
        .list()
    )
    # return averaged_cycles_per_iteration[0]
    return avg_by_key(averaged_cycles_per_iteration)


def plot_stream_utilization_forward(benchmark_data):
    readable_query_filenames = {
        "hg38/queries/exact_sample_50000000.fastq": "GRCh38 (No mismatches)",
        # "reference_4000000000/queries/exact_sample_50000000.fastq": "Generated (4 Gbp) (No mismatches)",
        "hg38/queries/sample_50000000.fastq": "GRCh38",
        "reference_4000000000/queries/sample_50000000.fastq": "Gen. (4 Gbp)",
    }

    query_order = {
        "GRCh38": 1,
        "Gen. (4 Gbp)": 2,
        "GRCh38 (No mismatches)": 3,
    }

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["executable"] == "BWA-HBM")
        # .filter(_["reference"] == "Generated (4 Gbp)")
        # .sorted(_["configuration"]["fastq_file"], reverse=True)
        .filter(lambda d: d["configuration"]["fastq_file"] in readable_query_filenames)
        .map(
            lambda d: [
                (d, "new tasks", "task_stream"),
                (d, "results", "filled_result_buffer_stream"),
                (d, "occ request", "req_bwt_position_stream"),
                (d, "occ response", "ret_bwt_entry_stream"),
            ]
        )
        .flatten()
        .starmap(
            lambda d, stream_display_name, stream_name: (
                d["reference"],
                d["image_configuration"]["num_cores"],
                readable_query_filenames[d["configuration"]["fastq_file"]],
                stream_display_name,
                calculate_cycle_distribution_for_stream(
                    stream_name, d["accelerator_monitors"]
                ),
            )
        )
        .starmap(
            lambda reference, num_cores, query_file, stream, cycles: seq(
                cycles.items()
            ).starmap(
                lambda key, value: {
                    "reference": reference,
                    "num_cores": num_cores,
                    "query_file": query_file,
                    "stream": stream,
                    "type": key,
                    "cycles": value,
                }
            )
        )
        .flatten()
        .order_by(lambda d: query_order[d["query_file"]])
    )

    figures = []

    for num_cores in [4, 16]:
        reference_data = data.filter(_["num_cores"] == num_cores)

        query = reference_data.map(_["query_file"]).distinct().make_string(",")
        fig, ax = new_figure(f"stream utilization\n[{query}]", "FIFO state (%)")
        # ax.set_xlabel(f"stream [{cores}]", fontsize=FONTSIZE.SMALL)

        stacks = reference_data.filter(_["type"] != "active")
        grouped_stacked_barplot(
            ax, stacks, _["stream"], _["type"], _["type"], _["cycles"], sum_values=True
        )

        for group_index, group_values in enumerate(
            reference_data.filter(_["type"] == "active")
            .group_by(_["stream"])
            .map(_[1])
            .list()
        ):
            pretty_print(group_values)
            bar_space = 0.8 / len(group_values)
            group_x_offset = -(0.8 / 2) + (bar_space / 2) + (group_index)
            ax.bar(
                group_x_offset + (np.arange(len(group_values)) * bar_space),
                seq(group_values).map(_["cycles"]),
                width=bar_space * 0.9,
                hatch="xx",
                fill=False,
                zorder=100,
            )

        legend_elements = [
            plotlib.patches.Patch(color=COLORS[label_index], label=label)
            for label_index, label in enumerate(
                seq(stacks).map(_["type"]).distinct().list()
            )
        ] + [
            plotlib.patches.Patch(
                hatch="xx", fill=False, edgecolor="black", label="active"
            ),
        ]

        ax.legend(
            handles=legend_elements,
            loc="upper center",
            bbox_to_anchor=(0.5, 1.15),
            ncol=4,
            framealpha=1,
            fontsize=FONTSIZE.SMALL,
            handlelength=1.5,
            handletextpad=0.5,
            columnspacing=0.7,
        )

        bottom, top = ax.get_ylim()
        ax.set_ylim(bottom, top * 1.1)
        ax.grid(visible=True, axis="y", zorder=0)

        fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
        # fig.set_figwidth(BASE_FIGWIDTH * (2 / 4))
        figures.append((f"stream_utilization_forward_{num_cores}_cores", fig))

    return figures


def plot_stream_utilization(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["executable"] == "BWA-HBM")
        .filter(_["configuration"]["iteration"] == 1)
        # .filter(_["image_configuration"]["num_cores"] == 4)
        # .filter(lambda d: len(d["configuration"]["cflags"].keys()) == 3)
        .order_by(_["image_configuration"]["num_cores"])
        .map(
            lambda d: [
                (d, "new tasks", "task_stream"),
                (d, "results", "filled_result_buffer_stream"),
                (d, "bwt request", "req_bwt_position_stream"),
                (d, "bwt response", "ret_bwt_entry_stream"),
            ]
        )
        .flatten()
        .starmap(
            lambda d, stream_display_name, stream_name: (
                d["reference"],
                d["image_configuration"]["num_cores"],
                d["configuration"]["fastq_file"],
                d["image_configuration"]["addressing"],
                stream_display_name,
                calculate_cycle_distribution_for_stream(
                    stream_name, d["accelerator_monitors"]
                ),
            )
        )
        .starmap(
            lambda reference, num_cores, query_file, addressing, stream, cycles: seq(
                cycles.items()
            ).starmap(
                lambda key, value: {
                    "reference": reference,
                    "num_cores": num_cores,
                    "query_file": query_file,
                    "addressing": addressing,
                    "stream": stream,
                    "type": key,
                    "cycles": value,
                }
            )
        )
        .flatten()
    )

    figures = []

    for reference in [
        # "GRCh38",
        # "Generated (256 Mbp)",
        # "Generated (1 Gbp)",
        "Generated (4 Gbp)",
    ]:
        reference_data = data.filter(_["reference"] == reference)

        pretty_print(reference_data.list())

        cores = (
            reference_data.map(_["num_cores"]).distinct().make_string(",") + " cores"
        )
        fig, ax = new_figure(f"stream utilization [{cores}]", "FIFO state (%)")

        stacks = reference_data.filter(_["type"] != "active")
        grouped_stacked_barplot(
            ax, stacks, _["stream"], _["type"], _["type"], _["cycles"], sum_values=True
        )

        for group_index, group_values in enumerate(
            reference_data.filter(_["type"] == "active")
            .group_by(_["stream"])
            .map(_[1])
            .list()
        ):            
            bar_space = 0.8 / len(group_values)
            group_x_offset = -(0.8 / 2) + (bar_space / 2) + (group_index)
            ax.bar(
                group_x_offset + (np.arange(len(group_values)) * bar_space),
                seq(group_values).map(_["cycles"]),
                width=bar_space * 0.9,
                hatch="xx",
                fill=False,
                zorder=100,
            )

        ax.legend(
            handles=[
                plotlib.patches.Patch(color=COLORS[label_index], label=label)
                for label_index, label in enumerate(
                    seq(stacks).map(_["type"]).distinct().list()
                )
            ],
            loc="upper center",
            bbox_to_anchor=(0.5, 1.15),
            ncol=3,
            framealpha=1,
            fontsize=FONTSIZE.SMALL,
        )

        bottom, top = ax.get_ylim()
        ax.set_ylim(bottom, top * 1.1)
        ax.grid(visible=True, axis="y")

        fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
        figures.append((f"stream_utilization_{reference}", fig))

    return figures


def filename_to_dataset(filename):
    with open(filename) as plot_dataset_file:
        dataset = json.load(plot_dataset_file)
    return dataset


def plot_machines(benchmark_data):
    variant_name_map = {
        "PHASE_EXCLUDE_ALIGNMENT": "input",
        "PHASE_EXCLUDE_THIRD_PASS_SEEDING": "+ 1st + 2nd pass",
        "PHASE_EXCLUDE_SEED_SORTING": "+ 3rd pass",
        # "PHASE_EXCLUDE_SEED_CHAINING": "+ sorting",
        "PHASE_EXCLUDE_SEED_EXTENSION": "+ chaining",
        # "PHASE_EXCLUDE_SEED_OUTPUT": "+ others",
        "PHASE_EXCLUDE_SEED_OUTPUT": "+ extension",
        "ALL": "+ output",
    }
    variant_name_map = {
        key: f"{index + 1} {value}"
        for index, (key, value) in enumerate(variant_name_map.items())
    }

    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .map(
            lambda d: {**d, "variant_name": variant_name_map.get(d["variant"], "HIDE")}
        )
        .filter(_["variant_name"] != "HIDE")
        .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        .filter(_["numa_setting"] == "ALL_NODES")
        .map(lambda d: namedtuple("AxisTuple", d)(**d))
        .filter(_.num_queries == int(5e7))
        .filter(lambda t: "1" not in t.configuration["run_options"].split(" -"))
        .sorted(_.variant_name)
    )

    print_table(
        data.sorted(_.reference), ["reference", "hostname", "variant_name", "duration"]
    )

    machine_name_map = {
        "armnode-01": "A64FX",
        "node-19": "XL225n",
        "nvram-02": "RX2530",
        "ic922-04": "IC922",
    }
    machines = (
        data.map(_.hostname)
        .map(lambda name: machine_name_map[name])
        .distinct()
        .make_string(",")
    )
    fig, ax = new_figure(f"Machine [{machines}]", "Runtime (s)")

    bars, labels = grouped_stacked_barplot(
        ax, seq(data), _.reference, _.variant, _.variant_name, _.duration
    )

    legend_elements = [
        plotlib.patches.Patch(color=COLORS[label_index], label=label)
        for label_index, label in enumerate(
            seq(data).map(_.variant_name).distinct().list()
        )
    ]
    ax.legend(
        handles=legend_elements[::-1],
        loc="upper right",
        ncol=1,
        framealpha=1,
        fontsize=FONTSIZE.SMALL,
    )
    # bottom, top = ax.get_ylim()
    # ax.set_ylim(bottom, top * 1.2)

    # [annotate_bars(ax, bar, 0) for bar in bars]

    # fig.set_figheight(BASE_FIGHEIGHT * (3 / 4))
    return [(f"runtime_machines", fig)]


def print_request_combination(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["variant"] == "ALL")
        .filter(_["executable"] == "BWA-HBM")
        # .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        # .filter(lambda d: d["reference"] == "GRCh38")
        .map(
            lambda d: (
                d["reference"],
                1
                - (
                    (
                        d["performance_counters"]["num_bwt_forward_accesses"]
                        + d["performance_counters"]["num_bwt_backward_accesses"]
                    )
                    / (
                        d["performance_counters"]["bwt_forward_extend_calls"]
                        + d["performance_counters"]["bwt_backward_extend_calls"]
                    )
                    - 1
                ),
            )
        )
        .list()
    )
    print("Share of FM-Index mappings with request combination:")
    pretty_print(data)

    return []


def print_failed_tasks(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["variant"] == "ALL")
        .filter(_["executable"] == "BWA-HBM")
        .filter(lambda t: "1" not in t["configuration"]["run_options"].split(" -"))
        # .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        # .filter(lambda d: d["reference"] == "GRCh38")
        .map(
            lambda d: (
                d["reference"],
                d["accelerator_performance_counters"]["num_failed_tasks"]
                / d["num_queries"]
                * 100,
            )
        )
        .list()
    )
    print("Share of failed queries:")
    pretty_print(data)

    return []


def print_mappings_per_symbol(benchmark_data):
    data = (
        seq(benchmark_data)
        .map(parse_and_extend)
        .filter(_["executable"] == "BWA-MEM")
        # .filter(_["variant"] == "ALL")
        # .filter(lambda d: d["reference"] in ["GRCh38", "Generated (4 Gbp)"])
        # .filter(lambda d: d["reference"] == "GRCh38")
        .map(
            lambda d: {
                "reference": d["reference"],
                "variant": d["variant"],
                "query_file": d["configuration"]["fastq_file"],
                "FM-Index mappings per query symbol": (
                    d["performance_counters"]["bwt_forward_extend_calls"]
                    + d["performance_counters"]["bwt_backward_extend_calls"]
                )
                / (d["num_queries"] * 200),
                "BWT requests per query symbol": (
                    d["performance_counters"]["num_bwt_forward_accesses"]
                    + d["performance_counters"]["num_bwt_backward_accesses"]
                )
                / (d["num_queries"] * 200),
                "Share FM-Index mappings from backward extension": d[
                    "performance_counters"
                ]["bwt_backward_extend_calls"]
                / (
                    d["performance_counters"]["bwt_forward_extend_calls"]
                    + d["performance_counters"]["bwt_backward_extend_calls"]
                ),
                "Tasks per Symbol": (d["performance_counters"]["num_first_pass_tasks"] + d["performance_counters"]["num_second_pass_tasks"]) / (d["num_queries"] * 200)
            }
        )
        .list()
    )
    pretty_print(data)

    return []


def create_plot(timestamp, plot_dataset_names, plot_function):
    plot_dataset_names = (
        [plot_dataset_names]
        if isinstance(plot_dataset_names, str)
        else plot_dataset_names
    )
    REPO_PATH = Path(__file__).parents[2].resolve()

    benchmarks_dir = Path(REPO_PATH / "scripts/benchmarks/output_data")
    figures_dir = Path(benchmarks_dir / "figures")
    benchmark_dir = Path(benchmarks_dir / timestamp)

    plot_dataset = (
        seq(plot_dataset_names)
        .map(lambda file: Path(benchmark_dir / f"{file}.json"))
        .map(filename_to_dataset)
        .flatten()
    )

    figures = plot_function(plot_dataset)

    for (fig_name, figure) in figures:
        fig_path = Path(figures_dir / f"{fig_name}.pdf")
        fig_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"Writing plot {fig_name}")
        figure.savefig(
            fig_path,
            dpi=300,
            bbox_inches="tight",
            format="pdf",
        )


if __name__ == "__main__":
    # create_plot("2022_07_27_08_32_30", "experiment_num_smem_cores", plot_num_cores)
    # create_plot("2022_07_27_08_32_30", "experiment_pipeline_depth", plot_pipeline_depth)
    # create_plot("2022_07_27_08_32_30", "experiment_hbm_id_width", plot_hbm_id_width)
    # create_plot("2022_08_07_11_54_40", "experiment_addressing", plot_addressing)
    # create_plot(
    #     "2022_06_03_11_16_01", "experiment_bit_partitioning", plot_bit_partitioning
    # )
    # create_plot("2022_06_08_15_56_38", "experiment_cache_impact", plot_most_frequent_coverage)
    # create_plot(
    #     "2022_07_27_08_32_30",
    #     "experiment_runtime_phases",
    #     plot_runtime_variants,
    # )
    # create_plot("2022_06_21_20_45_56", "experiment_runtime_phases", plot_runtime_phases)
    # create_plot(
    #     "2022_06_23_21_28_32",
    #     [
    #         "experiment_machines_power",
    #         "experiment_machines_nvram",
    #         "experiment_machines_amd",
    #         "experiment_machines_arm",
    #     ],
    #     plot_machines,
    # )
    # create_plot(
    #     "2022_06_21_20_45_56",
    #     "experiment_sa_decompression",
    #     plot_runtime_sa_decompression,
    # )
    # create_plot(
    #     "2022_06_21_20_45_56",
    #     "experiment_runtime_phases",
    #     plot_speedup_no_offloading,
    # )

    # create_plot("2022_08_03_18_51_35", "experiment_only_forward_extension", plot_forward_extension)

    # create_plot(
    #     "2022_08_03_18_51_35",
    #     "experiment_only_forward_extension",
    #     plot_stream_utilization_forward,
    # )

    # create_plot("2022_08_07_11_54_40", "experiment_addressing", plot_stream_utilization)
    # create_plot("2022_07_27_08_32_30", "experiment_num_smem_cores", plot_stream_utilization)

    # create_plot(
    #     "2022_06_08_15_56_38", "experiment_cache_impact", print_request_combination
    # )
    # create_plot("2022_06_21_20_45_56", "experiment_runtime_phases", print_failed_tasks)
    
    # create_plot(
    #     "2022_06_10_11_37_13", "experiment_runtime", plot_runtime_comparison_end_to_end
    # )

    create_plot(
        "2022_08_03_18_51_35",
        "experiment_only_forward_extension",
        print_mappings_per_symbol,
    )    
