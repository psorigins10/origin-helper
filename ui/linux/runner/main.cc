#include "my_application.h"
#include <gdk/gdk.h>

int main(int argc, char** argv) {
  gdk_set_allowed_backends("x11");  // force XWayland so window positioning works
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}