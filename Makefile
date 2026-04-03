PLENARY_PATH ?= /tmp/plenary.nvim

.PHONY: test

$(PLENARY_PATH):
	git clone --depth=1 https://github.com/nvim-lua/plenary.nvim $(PLENARY_PATH)

test: $(PLENARY_PATH)
	nvim --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"
