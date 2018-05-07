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
	git submodule update --init man/man-to-md/
	perl man/man-to-md.pl --comment --formatted-code --paste-section-after DESCRIPTION:'Installation.md' <man/walk.1 >$@

install:
	mkdir -p /usr/local/share/man/man1
	
	cp man/walk.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man1/walk.1
	gzip -f /usr/local/share/man/man1/walk.1
	
	cp src/walk.sh $(DEST)
	chmod 0755 $(DEST)
	chown $(CHOWN) $(DEST)

