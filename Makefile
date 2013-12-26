.PHONY : all install clean

BIN=walk
DEST=/usr/local/bin/$(BIN)
CHOWN=root:root

all:
clean:

install:
	mkdir -p /usr/local/share/man/man1
	
	cp -i man/walk.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man1/walk.1
	gzip /usr/local/share/man/man1/walk.1
	
	cp src/walk-1.1.sh $(DEST)
	chmod 0755 $(DEST)
	chown $(CHOWN) $(DEST)
