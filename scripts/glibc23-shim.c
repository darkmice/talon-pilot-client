/*
 * glibc 2.38 兼容 shim。
 *
 * libtalon.a(0.1.39 的 linux-amd64 预编译)是在 glibc ≥2.38 上编的,引用了
 * __isoc23_* 这组新符号(aws-lc 解析 CPU env 等处用到)。在 glibc <2.38 的
 * 发行版(如 Ubuntu 22.04 = 2.35)上链接会报 "undefined symbol: __isoc23_sscanf"。
 *
 * 这里把这组 C23 变体函数转发到标准实现,补上缺口,让产物能在 glibc ≥2.35 上跑。
 * 编译:cc -c -fPIC -O2 glibc23-shim.c -o glibc23-shim.o,再 -Clink-arg=.../glibc23-shim.o。
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int __isoc23_sscanf(const char *s, const char *f, ...) {
    va_list a; va_start(a, f); int r = vsscanf(s, f, a); va_end(a); return r;
}
int __isoc23_vsscanf(const char *s, const char *f, va_list a) { return vsscanf(s, f, a); }
int __isoc23_fscanf(FILE *s, const char *f, ...) {
    va_list a; va_start(a, f); int r = vfscanf(s, f, a); va_end(a); return r;
}
int __isoc23_scanf(const char *f, ...) {
    va_list a; va_start(a, f); int r = vscanf(f, a); va_end(a); return r;
}
long __isoc23_strtol(const char *n, char **e, int b) { return strtol(n, e, b); }
long long __isoc23_strtoll(const char *n, char **e, int b) { return strtoll(n, e, b); }
unsigned long __isoc23_strtoul(const char *n, char **e, int b) { return strtoul(n, e, b); }
unsigned long long __isoc23_strtoull(const char *n, char **e, int b) { return strtoull(n, e, b); }
