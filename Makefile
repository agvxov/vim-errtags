bundle: clean
	-mkdir object/.vim/
	-mkdir object/.vim/plugin/
	cp errtags.vim object/.vim/plugin/
	tar -C object/ -c .vim/ -f errtags.tar

install: bundle
	tar -x -f errtags.tar --dereference -C ~/
	-mkdir ~/bin/
	cp wrappers/* ~/bin/

clean:
	-rm -frfr object/.vim/
