#ifndef GLIBC_COMPAT_H
#define GLIBC_COMPAT_H

#if defined(__x86_64__) && defined(__gnu_linux__)
__asm__(".symver cosh,cosh@GLIBC_2.2.5");
__asm__(".symver sinh,sinh@GLIBC_2.2.5");
#endif

#endif // GLIBC_COMPAT_H
