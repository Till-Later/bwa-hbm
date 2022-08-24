from pathlib import Path
import subprocess
import sys
import re
from functional import seq
from fn import _, F
from fn.func import curried


class Color:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


class Instance:
    def __init__(
        self,
        parent,
        name,
        total_luts=0,
        logic_luts=0,
        lutrams=0,
        srls=0,
        flipflops=0,
        ramb36=0,
        ramb18=0,
        uram=0,
        dsp48=0,
    ):
        self.parent = parent
        self.name = name
        self.children = []
        self.total_luts = total_luts
        self.logic_luts = logic_luts
        self.lutrams = lutrams
        self.srls = srls
        self.flipflops = flipflops
        self.ramb36 = ramb36
        self.ramb18 = ramb18
        self.uram = uram
        self.dsp48 = dsp48

    def get_parent(self):
        return self.parent

    def get_children(self):
        return self.children

    def add_child(self, child):
        self.children.append(child)

    def traverse(self, func):
        func(self)
        for child in self.children:
            child.traverse(func)

    def get_full_name(self):
        if self.parent is None:
            return ""
        return f"{self.parent.get_full_name()} > {self.name}"

    def print(self, layer=0, max_layer=None):
        if max_layer and layer > max_layer:
            return
        print(f"{' ' * layer}{self.name}")
        for child in self.children:
            child.print(layer + 1, max_layer)


def expect_shell_command(command_string, error_message, show_stdout=False):
    cmd = f"""
        source /tools/Xilinx/Vivado/2019.2/settings64.sh; 
        export XILINXD_LICENSE_FILE=/home/till/Till/Xilinx_A8_5E_45_60_42_CE.lic; 
        {command_string}"""
    output = subprocess.run(
        ["/bin/bash", "-c", cmd],
        stdout=sys.stdout if show_stdout else subprocess.DEVNULL,
        stderr=sys.stderr,
        universal_newlines=True,
        # shell=True,
    )

    if output.returncode != 0:
        print(f"{Color.FAIL}ERROR: {error_message}{Color.ENDC}")
        raise RuntimeError("ERROR: {error_message}")


def get_utilization_report(checkpoint_dir):
    checkpoint_file = Path(checkpoint_dir / "opt_routed_design.dcp")
    report_file = Path(
        checkpoint_dir / "Reports" / "hierarchical_utilization_report.rpt"
    ).resolve()

    with open("create_utilization_report.tcl", "w") as report_script:
        report_script.write(f"open_checkpoint {checkpoint_file}\n")
        report_script.write(
            f"report_utilization -hierarchical -hierarchical_percentages -file {report_file}\n"
        )
        report_script.write(f"close_design\n")

    expect_shell_command(
        "vivado -quiet -mode batch -source create_utilization_report.tcl",
        "Could not create utilization report",
        show_stdout=True,
    )


@curried
def get_components_larger_than(percent, instance):
    if len(instance.children):
        max_child = seq(instance.children).map(_.total_luts[1]).max()
    else:
        max_child = 0

    if instance.total_luts[1] > percent and not max_child > percent:
        print(f"{instance.get_full_name()} : {instance.total_luts[1]}%")


def parse_utilization_report(report_file):
    root = Instance(None, "root")
    with open(report_file) as report:
        layers = [root]
        for line in report.readlines():
            parsed_line = re.search(
                "\| ( *)(.*?) *?\|(.*?)\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\| *?([0-9]+)\((.+?)%\) *\|\n",
                line,
            )

            if not parsed_line:
                continue

            groups = parsed_line.groups()

            instance_layer = int(len(groups[0]) / 2)
            # print(instance_layer)

            if instance_layer + 1 == len(layers):
                ()
            elif instance_layer + 1 < len(layers):
                del layers[(instance_layer + 1 - len(layers)) :]
            else:
                raise RuntimeError("ERROR: Tree parsing failed")

            instance = Instance(
                layers[-1],
                groups[1],
                total_luts=(int(groups[3]), float(groups[4])),
                logic_luts=(int(groups[5]), float(groups[6])),
                lutrams=(int(groups[7]), float(groups[8])),
                srls=(int(groups[9]), float(groups[10])),
                flipflops=(int(groups[11]), float(groups[12])),
                ramb36=(int(groups[13]), float(groups[14])),
                ramb18=(int(groups[15]), float(groups[16])),
                uram=(int(groups[17]), float(groups[18])),
                dsp48=(int(groups[19]), float(groups[20])),
            )
            layers[-1].add_child(instance)
            layers.append(instance)

    # root.print(layer=0, max_layer=5)

    # print(vars(root.get_children()[0]))

    # def check_utilization_consistency(instance):
    #     child_sum = seq(instance.children).map(_.total_luts[0]).map(int).sum()
    #     if len(instance.children) and abs(child_sum - int(instance.total_luts[0])) > 5:
    #         print(f"{instance.name}, num_children: {len(instance.get_children())}, child_sum: {child_sum}, parent: {instance.total_luts[0]}")
    # root.children[0].traverse(get_components_larger_than(0.8))

    return root.children[0]


def format_utilization(pair):
    absolute = int(pair[0]) if pair[0] < 10000 else f"{int(pair[0] / 1000)}K"
    relative = pair[1]
    return f"{absolute} ({relative}%)"


if __name__ == "__main__":
    # for configuration in [
    #     "second_layer_crossbar/cores_4/pipeline_id_width_1/",
    #     "second_layer_crossbar/cores_4/pipeline_id_width_4/",
    #     "second_layer_crossbar/cores_4/pipeline_id_width_5/",
    #     "second_layer_crossbar/cores_4/pipeline_id_width_6/",
    #     "second_layer_crossbar/cores_4/pipeline_id_width_7/",
    #     "second_layer_crossbar/cores_4/pipeline_id_width_8/",
    #     "second_layer_crossbar/cores_8/pipeline_id_width_1/",
    #     "second_layer_crossbar/cores_8/pipeline_id_width_4/",
    #     "second_layer_crossbar/cores_8/pipeline_id_width_5/",
    #     "second_layer_crossbar/cores_8/pipeline_id_width_7/",
    #     "second_layer_crossbar/cores_12/pipeline_id_width_4/",
    #     "second_layer_crossbar/cores_12/pipeline_id_width_6/",
    #     "second_layer_crossbar/cores_12/pipeline_id_width_8/",
    #     "second_layer_crossbar/cores_16/pipeline_id_width_6/",
    #     "second_layer_crossbar/cores_16/pipeline_id_width_7/",
    #     "local_addressing/cores_4/pipeline_id_width_6/",
    #     "local_addressing/cores_4/pipeline_id_width_7/",
    #     "local_addressing/cores_8/pipeline_id_width_6/",
    #     "local_addressing/cores_8/pipeline_id_width_7/",
    #     "local_addressing/cores_16/pipeline_id_width_6/",
    #     "first_layer_crossbar/cores_4/pipeline_id_width_6/",
    #     "first_layer_crossbar/cores_4/pipeline_id_width_7/",
    #     "first_layer_crossbar/cores_8/pipeline_id_width_6/",
    #     "first_layer_crossbar/cores_16/pipeline_id_width_7/",
    #     "hbm_id_width/cores_4/hbm_id_width_1/",
    #     "hbm_id_width/cores_4/hbm_id_width_2/",
    #     "hbm_id_width/cores_4/hbm_id_width_3/",
    #     "hbm_id_width/cores_4/hbm_id_width_4/",
    #     "hbm_id_width/cores_4/hbm_id_width_5/",
    #     "hbm_id_width/cores_4/hbm_id_width_6/",
    #     "hbm_id_width/cores_8/hbm_id_width_1/",
    #     "hbm_id_width/cores_8/hbm_id_width_2/",
    #     "hbm_id_width/cores_8/hbm_id_width_4/",
    #     "hbm_id_width/cores_8/hbm_id_width_5/",
    #     "hbm_id_width/cores_8/hbm_id_width_6/",
    #     "hbm_id_width/cores_16/hbm_id_width_2/",
    #     "hbm_id_width/cores_16/hbm_id_width_3/",
    #     "hbm_id_width/cores_16/hbm_id_width_4/",
    #     "hbm_id_width/cores_16/hbm_id_width_5/",
    #     "hbm_id_width/cores_16/hbm_id_width_6/",
    # ]:
    #     get_utilization_report(Path(f"/home/till/Till_remote_server/images/V2/{configuration}"))

    configurations = [
        ("4", "local_addressing/cores_4/pipeline_id_width_6/", 1),
        ("8", "local_addressing/cores_8/pipeline_id_width_6/", 2),
        ("16", "local_addressing/cores_16/pipeline_id_width_6/", 4),
        ("4", "first_layer_crossbar/cores_4/pipeline_id_width_6/", 1),
        ("8", "first_layer_crossbar/cores_8/pipeline_id_width_6/", 2),
        ("16", "first_layer_crossbar/cores_16/pipeline_id_width_7/", 4),
        ("4", "second_layer_crossbar/cores_4/pipeline_id_width_6/", 4),
        ("8", "second_layer_crossbar/cores_8/pipeline_id_width_7/", 4),
        ("12", "second_layer_crossbar/cores_12/pipeline_id_width_6/", 8),
        ("16", "second_layer_crossbar/cores_16/pipeline_id_width_6/", 8),
        ("32", "second_layer_crossbar/cores_4/pipeline_id_width_5/", 4),
        ("64", "second_layer_crossbar/cores_4/pipeline_id_width_6/", 4),
        ("128", "second_layer_crossbar/cores_4/pipeline_id_width_7/", 4),
        ("256", "second_layer_crossbar/cores_4/pipeline_id_width_8/", 4),
        ("16", "hbm_id_width/cores_16/hbm_id_width_4/", 8),
        ("32", "hbm_id_width/cores_16/hbm_id_width_5/", 8),
        ("64", "hbm_id_width/cores_16/hbm_id_width_6/", 8),
    ]

    top_instances = (
        seq(configurations)
        .starmap(
            lambda x, configuration, z: parse_utilization_report(
                Path(
                    Path(f"/home/till/Till_remote_server/images/V2")
                    / configuration
                    / "Reports"
                    / "hierarchical_utilization_report.rpt"
                ).resolve()
            )
        )
        .cache()
    )

    lut_util_range = (
        top_instances.map(_.total_luts[1]).min(),
        top_instances.map(_.total_luts[1]).max(),
    )

    ff_util_range = (
        top_instances.map(_.flipflops[1]).min(),
        top_instances.map(_.flipflops[1]).max(),
    )

    bram_util_range = (
        top_instances.map(lambda el: el.ramb36[1] + el.ramb18[1]).min(),
        top_instances.map(lambda el: el.ramb36[1] + el.ramb18[1]).max(),
    )

    uram_util_range = (
        top_instances.map(_.uram[1]).min(),
        top_instances.map(_.uram[1]).max(),
    )

    def wrap_color(minmax, value, text):
        color_index = round((value - minmax[0]) * (4 - 0) / (minmax[1] - minmax[0]) + 0)

        # decile = int((value - minmax[0]) / (minmax[1] - minmax[0]) * 4)
        return f"{{\\color{{mono_{color_index}}}{text}}}"

    print("& LUTs & FFs & BRAM & URAM & HBM")

    top_instances_list = top_instances.list()
    for index, (name, configuration, hbm_gb_used) in enumerate(configurations):
        top = top_instances_list[index]

        lut_util = f"{int(top.total_luts[0] / 1000)}K ({top.total_luts[1]:.1f}\\%)"
        ff_util = f"{int(top.flipflops[0] / 1000)}K ({top.flipflops[1]:.1f}\\%)"
        bram_util = f"{(36 * (top.ramb36[0] + top.ramb18[0] / 2)) / (2**10):.1f} Mib ({top.ramb36[1] + top.ramb18[1]:.1f}\\%)"
        uram_util = f"{288 * top.uram[0] / (2**10):.1f} ({top.uram[1]:.1f}\\%)"
        hbm_util = f"{hbm_gb_used} GiB ({(hbm_gb_used / 8) * 100:.0f}\%)"
        print(
            f"{name} & {wrap_color(lut_util_range, top.total_luts[1], lut_util)} & {wrap_color(ff_util_range, top.flipflops[1], ff_util)} & {wrap_color(bram_util_range, top.ramb36[1] + top.ramb18[1], bram_util)} & {wrap_color(uram_util_range, top.uram[1], uram_util)} & {wrap_color((0,8), hbm_gb_used, hbm_util)}\\\\"
        )
