/*  see copyright notice in squirrel.h */

#include <errno.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <squirrel.h>
#include <sqstdaux.h>
#include <sqstdblob.h>
#include <sqstdio.h>
#include <sqstdmath.h>
#include <sqstdstring.h>
#include <sqstdsystem.h>

#ifdef SQUNICODE
#define scfprintf fwprintf
#define scvprintf vfwprintf
#else
#define scfprintf fprintf
#define scvprintf vfprintf
#endif

typedef struct BenchConfig {
    const char *script_path;
    int compile_repeat;
    int run_repeat;
    int warmup;
    int script_argc;
    char **script_argv;
} BenchConfig;

static void printfunc(HSQUIRRELVM SQ_UNUSED_ARG(v), const SQChar *s, ...)
{
    va_list vl;
    va_start(vl, s);
    scvprintf(stdout, s, vl);
    va_end(vl);
}

static void errorfunc(HSQUIRRELVM SQ_UNUSED_ARG(v), const SQChar *s, ...)
{
    va_list vl;
    va_start(vl, s);
    scvprintf(stderr, s, vl);
    va_end(vl);
}

static double now_seconds(void)
{
    return ((double)clock()) / ((double)CLOCKS_PER_SEC);
}

static void print_usage(void)
{
    fprintf(stderr,
        "usage: sqbench [options] <scriptpath> [script args]\n"
        "Options:\n"
        "  --compile-repeat N   Compile the script N times using a fresh VM per run (default: 1)\n"
        "  --run-repeat N       Execute the compiled top-level closure N times (default: 1)\n"
        "  --warmup N           Execute the compiled closure N times before timing (default: 0)\n"
        "  --help               Print this help\n");
}

static int parse_non_negative(const char *text, int *out_value)
{
    char *endptr = NULL;
    long value;

    if(text == NULL || *text == '\0') {
        return 0;
    }

    errno = 0;
    value = strtol(text, &endptr, 10);
    if(errno != 0 || endptr == text || *endptr != '\0' || value < 0 || value > INT_MAX) {
        return 0;
    }

    *out_value = (int)value;
    return 1;
}

static int parse_args(int argc, char **argv, BenchConfig *config)
{
    int arg = 1;

    config->script_path = NULL;
    config->compile_repeat = 1;
    config->run_repeat = 1;
    config->warmup = 0;
    config->script_argc = 0;
    config->script_argv = NULL;

    while(arg < argc) {
        if(strcmp(argv[arg], "--help") == 0) {
            print_usage();
            return 0;
        }
        if(strcmp(argv[arg], "--compile-repeat") == 0) {
            if(arg + 1 >= argc || !parse_non_negative(argv[arg + 1], &config->compile_repeat)) {
                fprintf(stderr, "invalid value for --compile-repeat\n");
                return 0;
            }
            arg += 2;
            continue;
        }
        if(strcmp(argv[arg], "--run-repeat") == 0) {
            if(arg + 1 >= argc || !parse_non_negative(argv[arg + 1], &config->run_repeat)) {
                fprintf(stderr, "invalid value for --run-repeat\n");
                return 0;
            }
            arg += 2;
            continue;
        }
        if(strcmp(argv[arg], "--warmup") == 0) {
            if(arg + 1 >= argc || !parse_non_negative(argv[arg + 1], &config->warmup)) {
                fprintf(stderr, "invalid value for --warmup\n");
                return 0;
            }
            arg += 2;
            continue;
        }
        break;
    }

    if(arg >= argc) {
        print_usage();
        return 0;
    }

    config->script_path = argv[arg];
    config->script_argc = argc - arg - 1;
    config->script_argv = argv + arg + 1;
    return 1;
}

static HSQUIRRELVM create_vm(void)
{
    HSQUIRRELVM v = sq_open(1024);
    if(v == NULL) {
        return NULL;
    }

    sq_setprintfunc(v, printfunc, errorfunc);
    sq_pushroottable(v);

    sqstd_register_bloblib(v);
    sqstd_register_iolib(v);
    sqstd_register_systemlib(v);
    sqstd_register_mathlib(v);
    sqstd_register_stringlib(v);
    sqstd_seterrorhandlers(v);

    return v;
}

static void report_last_error(HSQUIRRELVM v, const char *context)
{
    const SQChar *err = NULL;

    fprintf(stderr, "%s failed", context);
    if(v != NULL) {
        sq_getlasterror(v);
        if(SQ_SUCCEEDED(sq_getstring(v, -1, &err)) && err != NULL) {
            scfprintf(stderr, _SC(": %s"), err);
        }
        sq_pop(v, 1);
    }
    fprintf(stderr, "\n");
}

static int load_script(HSQUIRRELVM v, const char *script_path)
{
#ifdef SQUNICODE
    size_t len = strlen(script_path) + 1;
    SQChar *buffer = sq_getscratchpad(v, (SQInteger)(len * sizeof(SQChar)));
    mbstowcs(buffer, script_path, len);
    if(SQ_FAILED(sqstd_loadfile(v, buffer, SQTrue))) {
        report_last_error(v, "compile");
        return 0;
    }
#else
    if(SQ_FAILED(sqstd_loadfile(v, script_path, SQTrue))) {
        report_last_error(v, "compile");
        return 0;
    }
#endif
    return 1;
}

static int run_compiled_closure(
    HSQUIRRELVM v,
    HSQOBJECT *closure,
    int script_argc,
    char **script_argv,
    SQObjectType *result_type,
    SQInteger *result_value)
{
    int i;
    SQInteger oldtop = sq_gettop(v);

    sq_pushobject(v, *closure);
    sq_pushroottable(v);
    for(i = 0; i < script_argc; i++) {
#ifdef SQUNICODE
        size_t len = strlen(script_argv[i]) + 1;
        SQChar *buffer = sq_getscratchpad(v, (SQInteger)(len * sizeof(SQChar)));
        mbstowcs(buffer, script_argv[i], len);
        sq_pushstring(v, buffer, -1);
#else
        sq_pushstring(v, script_argv[i], -1);
#endif
    }

    if(SQ_FAILED(sq_call(v, script_argc + 1, SQTrue, SQTrue))) {
        report_last_error(v, "run");
        sq_settop(v, oldtop);
        return 0;
    }

    if(result_type != NULL) {
        *result_type = sq_gettype(v, -1);
    }
    if(result_value != NULL && sq_gettype(v, -1) == OT_INTEGER) {
        sq_getinteger(v, -1, result_value);
    }

    sq_pop(v, 1);
    sq_settop(v, oldtop);
    return 1;
}

static int benchmark_compile(const BenchConfig *config, double *elapsed_seconds)
{
    int i;
    double start;

    *elapsed_seconds = 0.0;
    if(config->compile_repeat <= 0) {
        return 1;
    }

    start = now_seconds();
    for(i = 0; i < config->compile_repeat; i++) {
        HSQUIRRELVM v = create_vm();
        if(v == NULL) {
            fprintf(stderr, "failed to create VM for compile benchmark\n");
            return 0;
        }
        if(!load_script(v, config->script_path)) {
            sq_close(v);
            return 0;
        }
        sq_pop(v, 1);
        sq_close(v);
    }
    *elapsed_seconds = now_seconds() - start;
    return 1;
}

static int benchmark_run(
    const BenchConfig *config,
    double *elapsed_seconds,
    SQObjectType *result_type,
    SQInteger *result_value)
{
    int i;
    double start;
    HSQUIRRELVM v = create_vm();
    HSQOBJECT closure;

    *elapsed_seconds = 0.0;
    if(config->run_repeat <= 0 && config->warmup <= 0) {
        return 1;
    }
    if(v == NULL) {
        fprintf(stderr, "failed to create VM for run benchmark\n");
        return 0;
    }
    if(!load_script(v, config->script_path)) {
        sq_close(v);
        return 0;
    }

    sq_resetobject(&closure);
    sq_getstackobj(v, -1, &closure);
    sq_addref(v, &closure);
    sq_pop(v, 1);

    for(i = 0; i < config->warmup; i++) {
        if(!run_compiled_closure(v, &closure, config->script_argc, config->script_argv, NULL, NULL)) {
            sq_release(v, &closure);
            sq_close(v);
            return 0;
        }
    }

    start = now_seconds();
    for(i = 0; i < config->run_repeat; i++) {
        if(!run_compiled_closure(v, &closure, config->script_argc, config->script_argv, result_type, result_value)) {
            sq_release(v, &closure);
            sq_close(v);
            return 0;
        }
    }
    *elapsed_seconds = now_seconds() - start;

    sq_release(v, &closure);
    sq_close(v);
    return 1;
}

int main(int argc, char **argv)
{
    BenchConfig config;
    double compile_seconds = 0.0;
    double run_seconds = 0.0;
    SQObjectType result_type = OT_NULL;
    SQInteger result_value = 0;

    if(!parse_args(argc, argv, &config)) {
        return 1;
    }

    if(!benchmark_compile(&config, &compile_seconds)) {
        return 2;
    }
    if(!benchmark_run(&config, &run_seconds, &result_type, &result_value)) {
        return 3;
    }

    printf("script=%s\n", config.script_path);
    printf("compile_repeat=%d compile_total_ms=%.3f compile_avg_ms=%.3f\n",
        config.compile_repeat,
        compile_seconds * 1000.0,
        config.compile_repeat > 0 ? (compile_seconds * 1000.0) / (double)config.compile_repeat : 0.0);
    printf("warmup=%d run_repeat=%d run_total_ms=%.3f run_avg_ms=%.3f\n",
        config.warmup,
        config.run_repeat,
        run_seconds * 1000.0,
        config.run_repeat > 0 ? (run_seconds * 1000.0) / (double)config.run_repeat : 0.0);
    if(result_type == OT_INTEGER) {
        printf("result_type=integer checksum=%lld\n", (long long)result_value);
    } else {
        printf("result_type=%d\n", (int)result_type);
    }

    return 0;
}
