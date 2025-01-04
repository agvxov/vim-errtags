bundle:
	-mkdir object/.vim/
	-mkdir ~/bin/
    cp wrappers/* ~/bin/

install: bundle
	tar -x -f errtags.tar --dereference -C ~/
