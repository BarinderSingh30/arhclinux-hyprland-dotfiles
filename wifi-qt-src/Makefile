# wifi-qt -- plain g++ build, no cmake/ninja: everything this needs
# (g++, make, pkg-config, Qt6Widgets dev headers) is already installed for
# other reasons on this machine, and cmake is not. See main.cpp's header
# comment for why no moc step is needed either.

CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -O2 -fPIC $(shell pkg-config --cflags Qt6Widgets Qt6Gui Qt6Core)
LDFLAGS  := -pie $(shell pkg-config --libs Qt6Widgets Qt6Gui Qt6Core)
PREFIX   := $(HOME)/.local/bin

wifi-qt: main.cpp
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

install: wifi-qt
	install -Dm755 wifi-qt $(PREFIX)/wifi-qt

clean:
	rm -f wifi-qt

.PHONY: install clean
