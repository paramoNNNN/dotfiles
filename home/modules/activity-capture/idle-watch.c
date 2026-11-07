/* Track actual input inactivity, including when a video inhibits screen blanking. */
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>
#include "idle-notify.h"

static struct wl_seat *seat;
static struct ext_idle_notifier_v1 *notifier;
static uint32_t seat_name, notifier_name;
static const char *state_path;

static void write_state(const char *state) {
    char *temporary = malloc(strlen(state_path) + 5);
    if (!temporary)
        exit(1);
    sprintf(temporary, "%s.tmp", state_path);
    FILE *file = fopen(temporary, "w");
    if (!file || fputs(state, file) < 0 || fclose(file) || rename(temporary, state_path)) {
        perror("idle state");
        exit(1);
    }
    free(temporary);
}

static void idled(void *data, struct ext_idle_notification_v1 *notification) {
    (void)data;
    (void)notification;
    write_state("idle");
}

static void resumed(void *data, struct ext_idle_notification_v1 *notification) {
    (void)data;
    (void)notification;
    write_state("active");
}

static const struct ext_idle_notification_v1_listener idle_listener = {
    .idled = idled,
    .resumed = resumed,
};

static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version) {
    (void)data;
    if (!seat && strcmp(interface, wl_seat_interface.name) == 0) {
        seat = wl_registry_bind(registry, name, &wl_seat_interface, 1);
        seat_name = name;
    }
    if (!notifier && strcmp(interface, ext_idle_notifier_v1_interface.name) == 0 && version >= 2) {
        notifier = wl_registry_bind(registry, name, &ext_idle_notifier_v1_interface, 2);
        notifier_name = name;
    }
}

static void removed(void *data, struct wl_registry *registry, uint32_t name) {
    (void)data;
    (void)registry;
    /* Reconnect rather than risk retaining a stale seat or notifier. */
    if (name == seat_name || name == notifier_name)
        exit(1);
}

static const struct wl_registry_listener registry_listener = {
    .global = global,
    .global_remove = removed,
};

int main(int argc, char **argv) {
    if (argc != 3)
        return 2;
    char *end;
    errno = 0;
    unsigned long seconds = strtoul(argv[1], &end, 10);
    if (errno || *end || !seconds || seconds > UINT32_MAX / 1000)
        return 2;
    state_path = argv[2];
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "Cannot connect to Wayland; refusing captures.\n");
        return 1;
    }
    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    if (wl_display_roundtrip(display) < 0 || !seat || !notifier) {
        fprintf(stderr, "Input idle notification v2 unavailable; refusing captures.\n");
        return 1;
    }
    struct ext_idle_notification_v1 *notification =
        ext_idle_notifier_v1_get_input_idle_notification(notifier, seconds * 1000, seat);
    ext_idle_notification_v1_add_listener(notification, &idle_listener, NULL);
    write_state("active");
    while (wl_display_dispatch(display) >= 0) {}
    unlink(state_path);
    return 1;
}
