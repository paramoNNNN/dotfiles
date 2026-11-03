#!/usr/bin/env python3
"""A transient, clickable screenshot thumbnail on a Wayland layer surface."""

import math
import subprocess
import sys

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
gi.require_foreign("cairo")
from gi.repository import Gdk, GdkPixbuf, Gio, GLib, Gtk, GtkLayerShell


class Preview(Gtk.Application):
    def __init__(self):
        super().__init__(
            application_id="io.github.taha.ScreenshotPreview",
            flags=Gio.ApplicationFlags.HANDLES_COMMAND_LINE,
        )
        self.timer = None
        self.animation_tick = None
        self.preview_window = None
        self.card = None
        self.closing = False
        self.connect("command-line", self.on_command_line)

    def cancel_timer(self):
        if self.timer is not None:
            GLib.source_remove(self.timer)
            self.timer = None

    def destroy_windows(self):
        self.cancel_timer()
        if self.animation_tick is not None:
            self.preview_window.remove_tick_callback(self.animation_tick)
            self.animation_tick = None
        self.preview_window = None
        self.card = None
        self.closing = False
        for window in self.get_windows():
            window.destroy()
        return GLib.SOURCE_REMOVE

    def dismiss(self, *_args, immediate=False):
        self.cancel_timer()
        if immediate:
            return self.destroy_windows()
        if self.card is not None and not self.closing:
            self.closing = True
            self.fade_to(0.0, 140, self.destroy_windows)
        return GLib.SOURCE_REMOVE

    def fade_to(self, opacity, duration_ms, finished=None):
        window, card = self.preview_window, self.card
        if self.animation_tick is not None:
            window.remove_tick_callback(self.animation_tick)
            self.animation_tick = None
        if not window.get_settings().get_property("gtk-enable-animations"):
            card.set_opacity(opacity)
            if finished is not None:
                finished()
            return
        initial = card.get_opacity()
        started = None

        def tick(_widget, frame_clock):
            nonlocal started
            now = frame_clock.get_frame_time()
            if started is None:
                started = now
            progress = min(1.0, (now - started) / (duration_ms * 1000))
            eased = 1 - (1 - progress) ** 3
            card.set_opacity(initial + (opacity - initial) * eased)
            if progress < 1:
                return GLib.SOURCE_CONTINUE
            self.animation_tick = None
            if finished is not None:
                finished()
            return GLib.SOURCE_REMOVE

        # Animate only pixels: keep the layer surface's size and anchors fixed.
        self.animation_tick = window.add_tick_callback(tick)

    def arm_timer(self, *_args):
        self.cancel_timer()
        if not self.closing:
            self.timer = GLib.timeout_add_seconds(8, self.expire)

    def expire(self):
        self.timer = None
        return self.dismiss()

    def edit(self, _button, command):
        subprocess.Popen(command, start_new_session=True)
        self.dismiss()

    def on_command_line(self, _app, command_line):
        args = command_line.get_arguments()[1:]
        self.dismiss(immediate=True)
        if args == ["--dismiss"]:
            return 0
        if len(args) < 2:
            command_line.printerr("Usage: screenshot-preview IMAGE COMMAND [ARGS...]\n")
            return 2

        window = Gtk.ApplicationWindow(application=self)
        self.preview_window = window
        window.set_title("Screenshot preview")
        window.set_decorated(False)
        window.set_resizable(False)
        window.set_app_paintable(True)
        visual = window.get_screen().get_rgba_visual()
        if visual is not None:
            window.set_visual(visual)
        window.get_style_context().add_class("screenshot-preview")
        css = Gtk.CssProvider()
        css.load_from_data(b"""
            window.screenshot-preview { background-color: transparent; }
            .screenshot-preview .preview-card {
                background-color: @theme_bg_color;
                border: 1px solid alpha(@theme_fg_color, 0.18);
                border-radius: 18px;
            }
            .screenshot-preview .thumbnail {
                padding: 0; border: none; border-radius: 12px;
                background: transparent; box-shadow: none;
            }
        """)
        Gtk.StyleContext.add_provider_for_screen(
            window.get_screen(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        GtkLayerShell.init_for_window(window)
        GtkLayerShell.set_namespace(window, "screenshot-preview")
        GtkLayerShell.set_layer(window, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(window, GtkLayerShell.KeyboardMode.NONE)
        GtkLayerShell.set_exclusive_zone(window, -1)
        for edge in (GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.BOTTOM):
            GtkLayerShell.set_anchor(window, edge, True)
            GtkLayerShell.set_margin(window, edge, 20)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        card.get_style_context().add_class("preview-card")
        self.card = card
        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content.set_border_width(12)
        card.add(content)
        window.add(card)

        pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(args[0], 300, 200, True)
        thumbnail = Gtk.Button()
        thumbnail.get_style_context().add_class("thumbnail")
        image = Gtk.DrawingArea()
        image.set_size_request(pixbuf.get_width(), pixbuf.get_height())
        image.connect("draw", self.draw_thumbnail, pixbuf)
        thumbnail.add(image)
        thumbnail.set_tooltip_text("Open in Satty to annotate")
        thumbnail.connect("clicked", self.edit, args[1:])
        content.pack_start(thumbnail, True, True, 0)

        footer = Gtk.Box(spacing=12)
        footer.set_margin_start(6)
        footer.set_margin_end(6)
        footer.set_margin_top(2)
        footer.set_margin_bottom(6)
        label = Gtk.Label(label="Copied · Click to edit")
        label.set_xalign(0)
        footer.pack_start(label, True, True, 0)
        close = Gtk.Button.new_from_icon_name("window-close-symbolic", Gtk.IconSize.MENU)
        close.set_relief(Gtk.ReliefStyle.NONE)
        close.set_tooltip_text("Dismiss preview")
        close.connect("clicked", self.dismiss)
        footer.pack_end(close, False, False, 0)
        content.pack_end(footer, False, False, 0)

        # Crossing between child widgets must not restart the countdown.
        window.add_events(Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.LEAVE_NOTIFY_MASK)
        window.connect("enter-notify-event", self.on_enter)
        window.connect("leave-notify-event", self.on_leave)
        card.set_opacity(0)
        window.connect("map", lambda _window: self.fade_to(1.0, 180))
        window.show_all()
        self.arm_timer()
        return 0

    @staticmethod
    def draw_thumbnail(_widget, context, pixbuf):
        width, height = pixbuf.get_width(), pixbuf.get_height()
        radius = min(12, width / 2, height / 2)
        context.new_sub_path()
        for x, y, start in (
            (width - radius, radius, -math.pi / 2),
            (width - radius, height - radius, 0),
            (radius, height - radius, math.pi / 2),
            (radius, radius, math.pi),
        ):
            context.arc(x, y, radius, start, start + math.pi / 2)
        context.close_path()
        context.clip()
        Gdk.cairo_set_source_pixbuf(context, pixbuf, 0, 0)
        context.paint()
        return False

    def on_enter(self, _window, event):
        if event.detail != Gdk.NotifyType.INFERIOR:
            self.cancel_timer()
        return False

    def on_leave(self, _window, event):
        if event.detail != Gdk.NotifyType.INFERIOR:
            self.arm_timer()
        return False


if __name__ == "__main__":
    sys.exit(Preview().run(sys.argv))
