.PHONY : default install clean

BIN=walk
DEST=/usr/local/bin/$(BIN)
CHOWN=root:root

default:
clean:

install:
	cp src/walk*sh $(DEST)
	chown $(CHOWN) $(DEST)
	chmod 755 $(DEST)
