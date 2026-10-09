#!/usr/bin/env python3
"""
    Flowblade Node Editor module.
    Provides a simple node editor interface.

    Copyright 2024 Flowblade Project

    This file is part of Flowblade.

    Flowblade is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Flowblade is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Flowblade. If not, see <http://www.gnu.org/licenses/>.
"""

import gi
gi.require_version('Gtk', '3.0')

from gi.repository import Gtk
import node_editor_test


def launch_node_editor():
    """Launch the node editor window."""
    print("Launching Node Editor...")
    win = node_editor_test.NodeEditorWindow()
    win.show_all()