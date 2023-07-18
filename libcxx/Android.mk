# This file is dual licensed under the MIT and the University of Illinois Open
# Source Licenses. See LICENSE.TXT for details.

LOCAL_PATH := $(call my-dir)

# Normally, we distribute the NDK with prebuilt binaries of libc++
# in $LOCAL_PATH/libs/<abi>/. However,
#

LIBCXX_FORCE_REBUILD := $(strip $(LIBCXX_FORCE_REBUILD))
ifndef LIBCXX_FORCE_REBUILD
  ifeq (,$(strip $(wildcard $(SYSROOT_LIB_DIR)/libc++_static$(TARGET_LIB_EXTENSION))))
    $(call __ndk_info,WARNING: Rebuilding libc++ libraries from sources!)
    $(call __ndk_info,You might want to use $$NDK/build/tools/build-cxx-stl.sh --stl=libc++)
    $(call __ndk_info,in order to build prebuilt versions to speed up your builds!)
    LIBCXX_FORCE_REBUILD := true
  endif
endif

libcxx_includes := $(LOCAL_PATH)/include $(LOCAL_PATH)/src
libcxx_export_includes := $(libcxx_includes)
libcxx_sources := \
    algorithm.cpp \
    any.cpp \
    atomic.cpp \
    barrier.cpp \
    bind.cpp \
    charconv.cpp \
    chrono.cpp \
    condition_variable.cpp \
    condition_variable_destructor.cpp \
    exception.cpp \
    filesystem/filesystem_clock.cpp \
    filesystem/filesystem_error.cpp \
    filesystem/path_parser.h \
    filesystem/path.cpp \
    functional.cpp \
    future.cpp \
    hash.cpp \
    legacy_pointer_safety.cpp \
    memory.cpp \
    memory_resource.cpp \
    mutex.cpp \
    mutex_destructor.cpp \
    new.cpp \
    new_handler.cpp \
    new_helpers.cpp \
    optional.cpp \
    random_shuffle.cpp \
    ryu/d2fixed.cpp \
    ryu/d2s.cpp \
    ryu/f2s.cpp \
    shared_mutex.cpp \
    stdexcept.cpp \
    string.cpp \
    system_error.cpp \
    thread.cpp \
    typeinfo.cpp \
    valarray.cpp \
    variant.cpp \
    vector.cpp \
    verbose_abort.cpp \

libcxx_random_src := random.cpp

libcxx_locale_src := \
    ios.cpp \
    ios.instantiations.cpp \
    iostream.cpp \
    locale.cpp \
    regex.cpp \
    strstream.cpp \

libcxx_filesystem_src := \
    filesystem/operations.cpp \
    filesystem/directory_iterator.cpp \
    filesystem/int128_builtins.cpp \
    filesystem/directory_entry.cpp \

libcxx_sources += \
    $(libcxx_random_src) \
    $(libcxx_locale_src) \
    $(libcxx_filesystem_src) \

libcxx_sources := $(libcxx_sources:%=src/%)

libcxx_export_cxxflags :=

ifeq (,$(filter clang%,$(NDK_TOOLCHAIN_VERSION)))
# Add -fno-strict-aliasing because __list_imp::_end_ breaks TBAA rules by declaring
# simply as __list_node_base then casted to __list_node derived from that.  See
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=61571 for details
libcxx_export_cxxflags += -fno-strict-aliasing
endif

libcxx_cxxflags := \
    -std=c++20 \
    -DLIBCXX_BUILDING_LIBCXXABI \
    -D_LIBCPP_BUILDING_LIBRARY \
    -D__STDC_FORMAT_MACROS \
    $(libcxx_export_cxxflags) \

libcxx_ldflags :=
libcxx_export_ldflags :=

ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
    libcxx_cxxflags += -mbranch-protection=standard
endif

ifneq ($(LIBCXX_FORCE_REBUILD),true)

$(call ndk_log,Using prebuilt libc++ libraries)

libcxxabi_c_includes := $(LOCAL_PATH)/../llvm-libc++abi/include

include $(CLEAR_VARS)
LOCAL_MODULE := c++_static
LOCAL_SRC_FILES := $(SYSROOT_LIB_DIR)/lib$(LOCAL_MODULE)$(TARGET_LIB_EXTENSION)
LOCAL_EXPORT_C_INCLUDES := $(libcxx_export_includes)
LOCAL_STATIC_LIBRARIES := libc++abi
LOCAL_EXPORT_CPPFLAGS := $(libcxx_export_cxxflags)
LOCAL_EXPORT_LDFLAGS := $(libcxx_export_ldflags)
LOCAL_EXPORT_STATIC_LIBRARIES := libc++abi

ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    # This doesn't affect the prebuilt itself since this is a prebuilt library,
    # but the build system needs to know about the dependency so we can sort the
    # exported includes properly.
    LOCAL_STATIC_LIBRARIES += libandroid_support
    LOCAL_EXPORT_STATIC_LIBRARIES += libandroid_support
endif

LOCAL_EXPORT_STATIC_LIBRARIES += libunwind
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := c++_shared
LOCAL_SRC_FILES := $(SYSROOT_LIB_DIR)/lib$(LOCAL_MODULE)$(TARGET_SONAME_EXTENSION)
LOCAL_EXPORT_C_INCLUDES := \
    $(libcxx_export_includes) \
    $(libcxxabi_c_includes) \

LOCAL_EXPORT_CPPFLAGS := $(libcxx_export_cxxflags)
LOCAL_EXPORT_LDFLAGS := $(libcxx_export_ldflags)

ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    # This doesn't affect the prebuilt itself since this is a prebuilt library,
    # but the build system needs to know about the dependency so we can sort the
    # exported includes properly.
    LOCAL_STATIC_LIBRARIES := libandroid_support
    LOCAL_EXPORT_STATIC_LIBRARIES := libandroid_support
endif

LOCAL_EXPORT_STATIC_LIBRARIES += libunwind
include $(PREBUILT_SHARED_LIBRARY)

$(call import-module, cxx-stl/llvm-libc++abi)

else
# LIBCXX_FORCE_REBUILD == true

$(call ndk_log,Rebuilding libc++ libraries from sources)

include $(CLEAR_VARS)
LOCAL_MODULE := c++_static
LOCAL_SRC_FILES := $(libcxx_sources)
LOCAL_C_INCLUDES := $(libcxx_includes)
LOCAL_CPPFLAGS := $(libcxx_cxxflags) -ffunction-sections -fdata-sections
LOCAL_CPP_FEATURES := rtti exceptions
LOCAL_EXPORT_C_INCLUDES := $(libcxx_export_includes)
LOCAL_EXPORT_CPPFLAGS := $(libcxx_export_cxxflags)
LOCAL_EXPORT_LDFLAGS := $(libcxx_export_ldflags)
LOCAL_STATIC_LIBRARIES := libc++abi

ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    LOCAL_STATIC_LIBRARIES += android_support
endif

LOCAL_STATIC_LIBRARIES += libunwind
LOCAL_EXPORT_STATIC_LIBRARIES += libunwind
include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := c++_shared
LOCAL_STRIP_MODE := none
LOCAL_SRC_FILES := $(libcxx_sources)
LOCAL_C_INCLUDES := $(libcxx_includes)
LOCAL_CPPFLAGS := $(libcxx_cxxflags) -fno-function-sections -fno-data-sections
LOCAL_CPP_FEATURES := rtti exceptions
LOCAL_WHOLE_STATIC_LIBRARIES := libc++abi
LOCAL_EXPORT_C_INCLUDES := $(libcxx_export_includes)
LOCAL_EXPORT_CPPFLAGS := $(libcxx_export_cxxflags)
LOCAL_EXPORT_LDFLAGS := $(libcxx_export_ldflags)
ifeq ($(NDK_PLATFORM_NEEDS_ANDROID_SUPPORT),true)
    LOCAL_STATIC_LIBRARIES := android_support
endif
LOCAL_LDFLAGS := $(libcxx_ldflags)
# Use --as-needed to strip the DT_NEEDED on libstdc++.so (bionic's) that the
# driver always links for C++ but we don't use.
# See https://github.com/android-ndk/ndk/issues/105
LOCAL_LDFLAGS += -Wl,--as-needed
LOCAL_STATIC_LIBRARIES += libunwind
LOCAL_EXPORT_STATIC_LIBRARIES += libunwind

# But only need -latomic for armeabi.
ifeq ($(TARGET_ARCH_ABI),armeabi)
    LOCAL_LDLIBS += -latomic
endif
include $(BUILD_SHARED_LIBRARY)

$(call import-add-path, $(LOCAL_PATH)/../../..)
$(call import-module, toolchain/llvm-project/libcxxabi)

endif # LIBCXX_FORCE_REBUILD == true

$(call import-module, android/support)
