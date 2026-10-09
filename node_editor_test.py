#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import cairo

# ---------------------------------------------------------------------------
# Structure de données POO simple, indépendante de la vue GTK
# ---------------------------------------------------------------------------

class Node:
    """Représente un nœud dans l'éditeur."""
    def __init__(self, title, x, y, color):
        self.title = title      # texte affiché sur le nœud
        self.x = x              # coordonnée x du centre
        self.y = y              # coordonnée y du centre
        self.color = color      # tuple (r, g, b) entre 0 et 1


class Connection:
    """Représente une connexion entre deux nœuds."""
    def __init__(self, source, target, source_port='output', target_port='input'):
        self.source = source
        self.target = target
        self.source_port = source_port
        self.target_port = target_port


# ---------------------------------------------------------------------------
# Fenêtre GTK contenant un DrawingArea géré par Cairo
# ---------------------------------------------------------------------------

class NodeEditorWindow(Gtk.Window):
    """Fenêtre principale affichant les nœuds et les connexions."""
    def __init__(self):
        Gtk.Window.__init__(self, title="Éditeur de nœuds simple")
        self.set_default_size(800, 600)
        self.connect('destroy', Gtk.main_quit)

        # Zone de dessin Cairo
        self.drawing_area = Gtk.DrawingArea()
        self.add(self.drawing_area)
        self.drawing_area.connect('draw', self.on_draw)

        # Deux nœuds exemple
        self.node_source = Node(title="Source", x=200, y=200, color=(0.68, 0.85, 0.9))  # bleu clair
        self.node_filter = Node(title="Filtre", x=500, y=300, color=(0.68, 0.93, 0.68))  # vert clair
        self.conn = Connection(self.node_source, self.node_filter)

    def on_draw(self, widget, cr):
        # Fond blanc
        cr.set_source_rgb(1, 1, 1)
        cr.paint()

        # Police de caractères
        cr.select_font_face("Sans", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
        cr.set_font_size(12)
        cr.set_source_rgb(0, 0, 0)

        # Dessiner les nœuds
        self._draw_node(cr, self.node_source)
        self._draw_node(cr, self.node_filter)

        # Dessiner la connexion
        self._draw_connection(cr, self.conn)

    def _draw_node(self, cr, node):
        """Dessine un rectangle de titre coloré."""
        width = 120
        height = 60
        # Rectangle du nœud
        cr.set_fill_rgb(*node.color)
        cr.rectangle(node.x - width / 2, node.y - height / 2, width, height)
        cr.fill()
        # Titre du nœud
        cr.move_to(node.x - width / 2 + 5, node.y - height / 2 + 20)
        cr.show_text(node.title)

    def _draw_connection(self, cr, conn):
        """Dessine une ligne reliant les deux nœuds."""
        # Sortie du bas du nœud source et entrée du haut du nœud cible
        x1 = conn.source.x
        y1 = conn.source.y + 30      # bas du rectangle
        x2 = conn.target.x
        y2 = conn.target.y - 30      # haut du rectangle

        cr.move_to(x1, y1)
        cr.line_to(x2, y2)
        cr.set_source_rgb(0, 0, 0)
        cr.set_line_width(2)
        cr.stroke()


# ---------------------------------------------------------------------------
# Point d’entrée
# ---------------------------------------------------------------------------

if __name__ == '__main__':
    win = NodeEditorWindow()
    win.show_all()
    Gtk.main()