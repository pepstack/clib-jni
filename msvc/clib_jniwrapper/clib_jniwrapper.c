/**
 * com_github_jni_JNIWrapper.c
 */
#include "com_github_jni_JNIWrapper.h"

#include <clib/clib_api.h>


void JNICALL Java_com_github_jni_JNIWrapper_JNI_1clib_1lib_1version(JNIEnv *env, jobject obj)
{
    const char *libname;
    const char * libversion = clib_lib_version(&libname);

    printf("Java_com_github_jni_JNIWrapper_JNI_1clib_1lib_1version: %s-%s\n", libname, libversion);
}