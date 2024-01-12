.PHONY: all clean install

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
SWIFTC ?= swiftc
INSTALL ?= install

all: lcrename

lcrename: lcrename.swift
	$(SWIFTC) -v -O -o $@ $<

install: lcrename
	$(INSTALL) -v -C -m 755 $< $(BINDIR)/$<
	$(INSTALL) -v -C -m 644 lcrename.1 $(MANDIR)/lcrename.1

uninstall:
	rm -f $(BINDIR)/lcrename
	rm -f $(MANDIR)/lcrename.1

clean:
	rm -f lcrename
