.PHONY : all install clean

BIN=walk
DEST=/usr/local/bin/$(BIN)
CHOWN=root:root

all:
clean:

install:
	mkdir -p /usr/local/share/man/man1
	
	cp -i man/*.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man?/walk.?
	gzip /usr/local/share/man/man?/walk.?
	
	cp src/walk*sh $(DEST)
	chown $(CHOWN) $(DEST)
	chmod 755 $(DEST)
