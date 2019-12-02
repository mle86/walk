.PHONY : all install clean test

BIN=walk
DEST=/usr/local/bin/$(BIN)
CHOWN=root:root

all:
clean:

test:
	git submodule update --init test/framework/
	test/run-all-tests.sh

README.md: doc/walk.1 doc/*.md
	git submodule update --init doc/man-to-md/
	perl doc/man-to-md.pl --comment --formatted-code --paste-after HEADLINE:'Badges.md' --paste-section-after DESCRIPTION:'Installation.md' <$< >$@

install:
	mkdir -p /usr/local/share/man/man1
	
	cp doc/walk.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man1/walk.1
	gzip -f /usr/local/share/man/man1/walk.1
	
	cp src/walk.sh $(DEST)
	chmod 0755 $(DEST)
	chown $(CHOWN) $(DEST)

