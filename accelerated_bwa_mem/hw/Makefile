#
# Copyright 2017, International Business Machines
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

python := python3.8
# python := python3

DFACCTO_VENV = $(shell realpath ./.venv)
DFACCTO_REPO = $(shell realpath ./dfaccto_tpl)
DFACCTO_DIR_TPL = $(shell realpath ./templates)
DFACCTO_DIR_OUT = $(shell realpath ./generated)
DFACCTO_CONFIG = $(shell realpath ./config/action_wrapper.py)

.PHONY: all config clean

all: config

$(DFACCTO_VENV): $(DFACCTO_REPO)
	@echo "# setup DFACCTO-TPL environment"
	@$(python) -m venv $(DFACCTO_VENV)
	@. $(DFACCTO_VENV)/bin/activate; \
	cd $(DFACCTO_REPO); \
	$(python) -m pip install --upgrade pip; \
	$(python) -m pip install .

config: $(DFACCTO_VENV)
	@echo "--- generating TPL sources"
	@. $(DFACCTO_VENV)/bin/activate; \
	 $(python) -m dfaccto_tpl --tpldir=$(DFACCTO_DIR_TPL) --outdir=$(DFACCTO_DIR_OUT) --config=$(DFACCTO_CONFIG)
	@echo "--- generating HLS sources"
	@$(MAKE) -C hls vhdl

clean:
	@$(RM) $(ACTION_ROOT)/ip/*.log
	@$(RM) $(ACTION_ROOT)/ip/*.jou
	@$(RM) -fr $(ACTION_ROOT)/ip/action_ip_prj
	@$(RM) -fr $(ACTION_ROOT)/ip/ip_user_files
	@$(RM) -fr $(DFACCTO_DIR_OUT)/*
	$(MAKE) -C hls clean