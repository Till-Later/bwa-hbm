#
# Copyright 2017 International Business Machines
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Generate HDL version of the HLS sources
#
# The generated HDL depends on the chip which is used and
# therefore must match what is being used to build the
# toplevel SNAP bitstream.
#
# FIXME Pass part_number and other parameters from toplevel
#      build-system as required.
#

# SNAP_ROOT=$(abspath ../../oc-accel)
#
# # Finding $SNAP_ROOT
# ifndef SNAP_ROOT
# # check if we are in hw folder of an action (three directories below snap root)
# ifneq ("$(wildcard ../../../actions)","")
# SNAP_ROOT=$(abspath ../../../)
# else
# $(info You are not building your software from the default directory (/path/to/snap/actions/<action_name>/sw) or specified a wrong $$SNAP_ROOT.)
# $(error Please make sure that $$SNAP_ROOT is set up correctly.)
# endif
# endif

# This is solution specific. Check if we can replace this by generics too.
SNAP_ROOT = $(realpath ../../../../oc-accel)
WRAPPER = results_to_host_manager
SOLUTION_NAME ?= resultsToHostManager
SOLUTION_DIR ?= hlsResultsToHostManager
srcs += hls_results_to_host_manager.cpp ../include/hls_accelerator_result_buffer_definitions.cpp ../include/hls_stream_processing.cpp ../include/hls_bwt_definitions.cpp


# If you have the action code outside of the default snap directory structure,
# change to /path/to/snap/actions/hls.mk
include $(SNAP_ROOT)/actions/hls.mk
