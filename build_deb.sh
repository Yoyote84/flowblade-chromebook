#!/bin/bash
#
# build_deb.sh - Script de construction Debian pour Flowblade
# Optimisé pour Chromebook ARM64 (Lenovo Duet 3) avec Crostini/Debian 13.7
#
# Ce script prépare un paquet .deb empaquetant Flowblade avec :
# - Support Python/GTK/MLT
# - Optimisations FFmpeg/MLT pour le rendu proxy (threads=2, preset=ultrafast)
# - Module Node Editor ajouté au menu Tools
# - Tous les fichiers de configuration modifiés
#

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLOWBLADE_DIR="$PROJECT_DIR/flowblade-trunk/Flowblade"
BUILD_DIR="$PROJECT_DIR/build"
DEBIAN_DIR="$BUILD_DIR/debian"

echo "========================================="
echo "Construction du paquet Flowblade .deb"
echo "Projet : flowblade-chromebook"
echo "Cible : Chromebook ARM64 / Debian 13.7 (Crostini)"
echo "========================================="

# -------------------------------------------------------------------------
# 1. Vérification des dépendances
# -------------------------------------------------------------------------
echo ""
echo "[1/8] Vérification des dépendances..."

if ! command -v dpkg-deb &>/dev/null; then
    echo "⚠  dpkg-deb non trouvé - Installation requise"
    echo "   Exécutez : sudo apt-get install debhelper dh-make build-essential"
    echo "   Ou dans Crostini : apk add dpkg devscripts build-essential"
fi

if ! python3 --version &>/dev/null; then
    echo "✗ Python3 non trouvé"
    exit 1
else
    echo "✓ Python3 $(python3 --version)"
fi

# -------------------------------------------------------------------------
# 2. Création de la structure de build
# -------------------------------------------------------------------------
echo ""
echo "[2/8] Création de la structure de build..."

rm -rf "$BUILD_DIR"
mkdir -p "$DEBIAN_DIR"
mkdir -p "$BUILD_DIR/usr/lib/flowblade/tools"
mkdir -p "$BUILD_DIR/usr/share/flowblade/res/render"
mkdir -p "$BUILD_DIR/usr/share/flowblade/Flowblade"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/pixmaps"
mkdir -p "$BUILD_DIR/usr/lib/flowblade"
mkdir -p "$BUILD_DIR/usr/bin"

# -------------------------------------------------------------------------
# 3. Création du fichier pyproject.toml
# -------------------------------------------------------------------------
echo ""
echo "[3/7] Création de pyproject.toml..."

cat > "$BUILD_DIR/pyproject.toml" << 'PYPROJECT'
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "flowblade"
version = "2.20"
description = "Non-linear video editor"
license = "GPL-3.0"
authors = [{name "Janne Liljeblad"}]
author-email = "janne.liljeblad@gmail.com"
requires-python = ">=3.8"

[project.optional-dependencies]
dev = ["pytest", "flake8"]

[tool.setuptools.packages.find]
where = ["."]
include = ["Flowblade*", "tools*", "vieweditor*"]

[tool.setuptools.package-data]
Flowblade = ["*.py", "glade/*.glade", "locale/*"]
tools = ["*.py"]
vieweditor = ["*.py"]

[tool.setuptools.install-requires]
gi = ">=3.0"
pycairo
pygobject
mlt7 >= 6.12.0
pyyaml
pyparsing
PYPROJECT

# -------------------------------------------------------------------------
# 4. Création du fichier debian/control
# -------------------------------------------------------------------------
echo ""
echo "[4/7] Création de debian/control..."

cat > "$DEBIAN_DIR/control" << 'CONTROL'
Source: flowblade
Section: science
Priority: optional
Maintainer: Flowblade Maintainers <janne.liljeblad@gmail.com>
Build-Depends: debhelper (>= 13), python3-setuptools, python3-gi,
               libgtk-3-dev, libmlt6-dev, libjson-glib-dev,
               intltool, gettext
Standards-Version: 4.6.0

Package: flowblade
Architecture: any
Depends: ${shlibs:Depends}, ${python3:Depends},
         python3-gi, python3-cairo, python3-pygobject,
         libmlt6, libjson-glib-2.0-0
Description: Non-linear video editor
  Flowblade is a non-linear video editor for Linux.
  Includes Node Editor module for advanced editing.
  Optimized for ARM64/Crostino with ultrafast proxy generation.
CONTROL

# -------------------------------------------------------------------------
# 5. Création du fichier debian/rules
# -------------------------------------------------------------------------
echo ""
echo "[5/7] Création de debian/rules..."

cat > "$DEBIAN_DIR/rules" << 'RULES'
#!/usr/bin/make -f
%:
	dh $@ --with python3

override_dh_auto_configure:
	python3 setup.py build

override_dh_auto_build:
	python3 setup.py build

override_dh_auto_install:
	python3 setup.py install --skip-build --root=debian/flowblade --install-layout=deb
	install -D -m 644 COPYING debian/flowblade/usr/share/doc/flowblade/copyright

RULES
chmod +x "$DEBIAN_DIR/rules"

# -------------------------------------------------------------------------
# 6. Création du fichier debian/install
# -------------------------------------------------------------------------
echo ""
echo "[6/7] Création de debian/install..."

cat > "$DEBIAN_DIR/install" << 'INSTALL'
bin/flowblade
usr/lib/flowblade/*.py
usr/share/flowblade/Flowblade/*.py
usr/share/flowblade/Flowblade/launch/*
usr/share/flowblade/Flowblade/tools/*.py
usr/share/flowblade/Flowblade/vieweditor/*.py
usr/share/glade3/flowblade/*
usr/share/pixmap/flowblade.xpm
usr/share/applications/flowblade.desktop
usr/share/icons/hicolor/*/apps/flowblade.png
usr/share/doc/flowblade/copyright
INSTALL

# -------------------------------------------------------------------------
# 7. Copie des fichiers modifiés et optimisations
# -------------------------------------------------------------------------
echo ""
echo "[7/7] Copie des fichiers modifiés et optimisations..."

# Module Node Editor
cp "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/tools/nodeditor.py" "$BUILD_DIR/usr/lib/flowblade/tools/nodeditor.py"

# Optimisations FFmpeg/MLT pour proxy rendering (renderencoding.xml)
cp "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/res/render/renderencoding.xml" "$BUILD_DIR/usr/share/flowblade/res/render/renderencoding.xml"

# Fichier principal editorwindow.py (avec NodeEditor et import nodeditor)
cp "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/editorwindow.py" "$BUILD_DIR/usr/share/flowblade/Flowblade/editorwindow.py"

# Scripts tools
cp "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/tools/nodeditor.py" "$BUILD_DIR/usr/lib/flowblade/tools/nodeditor.py" 2>/dev/null || true

# Icones et desktop (s'ils existent)
if [ -f "$FLOWBLADE_DIR/usr/share/pixmap/flowblade.xpm" ]; then
    cp "$FLOWBLADE_DIR/usr/share/pixmap/flowblade.xpm" "$BUILD_DIR/usr/share/pixmap/flowblade.xpm"
fi
if [ -f "$FLOWBLADE_DIR/usr/share/applications/flowblade.desktop" ]; then
    cp "$FLOWBLADE_DIR/usr/share/applications/flowblade.desktop" "$BUILD_DIR/usr/share/applications/flowblade.desktop"
fi

# Documentation
if [ -f "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/COPYING" ]; then
    cp "$FLOWBLADE_DIR/usr/share/flowblade/Flowblade/COPYING" "$BUILD_DIR/usr/share/doc/flowblade/copyright"
fi

echo ""
echo "========================================="
echo "Construction terminee avec succes !"
echo ""
echo "Emplacement du paquet : $BUILD_DIR/flowblade_2.20-1_$(dpkg --print-architecture 2>/dev/null || echo 'unknown').deb"
echo ""
echo "Fichiers crees :"
echo "  - $DEBIAN_DIR/control       (metadonnees du paquet)"
echo "  - $DEBIAN_DIR/rules        (rules makefile debhelper)"
echo "  - $DEBIAN_DIR/install      (liste de fichiers)"
echo "  - $BUILD_DIR/pyproject.toml (configuration Python)"
echo "  - $BUILD_DIR/usr/lib/flowblade/tools/nodeditor.py  (module Node Editor)"
echo "  - $BUILD_DIR/usr/share/flowblade/res/render/renderencoding.xml  (optimisations proxy)"
echo "  - $BUILD_DIR/usr/share/flowblade/Flowblade/editorwindow.py  (menu Tools -> Node Editor)"
echo ""
echo "Etapes suivantes manuelles :"
echo "  1. cd $BUILD_DIR && debuild -us -uc"
echo "  2. Installer : dpkg -i ../flowblade_2.20-1_*.deb"
echo "========================================="