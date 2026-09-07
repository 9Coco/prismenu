#!/usr/bin/env bash
# Extraction script for ki18n / Messages
$XGETTEXT `find package -name '*.qml' -o -name '*.js'` -o po/plasma_applet_com.github.9coco.prismenu.pot
