#include "my_application.h"
#include <stdlib.h>

int main(int argc, char** argv) {
  setenv("WEBKIT_DISABLE_DMABUF_RENDERER", "1", 0);
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
