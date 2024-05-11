#include "utils.h"
#include <stdio.h>

void error(const char *msg) {
    fprintf(stderr, "Error: %s\n", msg);
}
