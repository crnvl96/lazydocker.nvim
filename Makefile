NVIM_EXEC ?= nvim

test:
	for nvim_exec in $(NVIM_EXEC); do \
		printf "\n======\n\n" ; \
		$$nvim_exec --version | head -n 1 && echo '' ; \
		$$nvim_exec --headless --noplugin -u ./scripts/minimal_init.lua \
			-c "lua MiniTest.run()" ; \
	done

documentation:
	$(NVIM_EXEC) --headless --noplugin -u ./scripts/minimal_init.lua \
    -c "lua MiniDoc.generate()" \
    -c "qa!"
