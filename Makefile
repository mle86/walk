.PHONY : all install clean test

BIN=walk
DEST=/usr/local/bin/$(BIN)
CHOWN=root:root

all:
clean:

test:
	git submodule update --init test/framework/
	test/run-all-tests.sh

README.md: man/*
	perl man/to-readme.pl <man/walk.1 >README.md

install:
	mkdir -p /usr/local/share/man/man1
	
	cp man/walk.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man1/walk.1
	gzip -f /usr/local/share/man/man1/walk.1
	
	cp src/walk-2.0.sh $(DEST)
	chmod 0755 $(DEST)
	chown $(CHOWN) $(DEST)

