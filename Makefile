NAME := calibre_filemon
PLUGIN_DIR := $(NAME).koplugin
OUT_DIR := release
VERSION := $(shell sed -n 's/.*version = "\(.*\)".*/\1/p' _meta.lua)
ZIP_FILE := $(NAME).koplugin-v$(VERSION).zip

.PHONY: all build clean version

all: build

build: $(OUT_DIR)/$(ZIP_FILE)

$(OUT_DIR)/$(ZIP_FILE): _meta.lua main.lua
	mkdir -p $(OUT_DIR)
	cd .. && zip "$(CURDIR)/$(OUT_DIR)/$(ZIP_FILE)" \
		"$(PLUGIN_DIR)/_meta.lua" \
		"$(PLUGIN_DIR)/main.lua"

clean:
	rm -rf $(OUT_DIR)

version:
	@echo $(VERSION)
