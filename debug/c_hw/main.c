// header name typo
//#include <studio.h>
// NOTE: LOL.
//        you thought gcc can report syntax errors if preprocessing failed?
//       LMAO EVEN.

#include "header.h"

// messed up struct syntax
struct {
    int a,
    int b;
} k;

int f(void) {
    // statement with no effect
    10 + 10;
    // missing return statement
}

signed main(void) {
    // non-sensical break
    break;

    return f();
}
