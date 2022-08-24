DFACCTO_VENV = $(shell realpath ./.venv)
DFACCTO_REPO = $(shell realpath ./dfaccto_tpl)
DFACCTO_DIR_TPL = $(shell realpath ./templates)
DFACCTO_DIR_OUT = $(shell realpath ./generated)
DFACCTO_CONFIG = $(shell realpath ./config/action_wrapper.py)

.PHONY: all config clean

all: config

$(DFACCTO_VENV): $(DFACCTO_REPO)
	@echo "# setup DFACCTO-TPL environment"
	@python3.8 -m venv $(DFACCTO_VENV)
	@. $(DFACCTO_VENV)/bin/activate; \
	cd $(DFACCTO_REPO); \
	python3.8 -m pip install --upgrade pip; \
	python3.8 -m pip install .
	touch .venv

config: $(DFACCTO_VENV)
	@echo "# generating TPL sources"
	@. $(DFACCTO_VENV)/bin/activate; \
	 python3.8 -m dfaccto_tpl --tpldir=$(DFACCTO_DIR_TPL) --outdir=$(DFACCTO_DIR_OUT) --config=$(DFACCTO_CONFIG)
	@echo "# generating HLS sources"
	@make -C hls vhdl

clean:
	@$(RM) $(ACTION_ROOT)/ip/*.log
	@$(RM) $(ACTION_ROOT)/ip/*.jou
	@$(RM) -fr $(ACTION_ROOT)/ip/action_ip_prj
	@$(RM) -fr $(ACTION_ROOT)/ip/ip_user_files
	@$(RM) -fr $(DFACCTO_DIR_OUT)/*
	make -C hls clean
