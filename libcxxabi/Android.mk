#
# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH := $(call my-dir)

LIBCXX_PATH := $(LOCAL_PATH)/../libcxx

libcxxabi_src_files := \
    cxa_aux_runtime.cpp \
    cxa_default_handlers.cpp \
    cxa_demangle.cpp \
    cxa_exception_storage.cpp \
    cxa_guard.cpp \
    cxa_handlers.cpp \
    cxa_vector.cpp \
    cxa_virtual.cpp \
    stdlib_exception.cpp \
    stdlib_stdexcept.cpp \
    stdlib_typeinfo.cpp \
    abort_message.cpp \
    fallback_malloc.cpp \
    private_typeinfo.cpp \
    stdlib_new_delete.cpp \
    cxa_exception.cpp \
    cxa_personality.cpp \
    cxa_thread_atexit.cpp \

libcxxabi_src_files := $(libcxxabi_src_files:%=src/%)

libcxxabi_includes := \
    $(LOCAL_PATH)/include \
    $(LIBCXX_PATH)/include \
    $(LIBCXX_PATH)/src \

libcxxabi_cflags := -D__STDC_FORMAT_MACROS
libcxxabi_cppflags := -std=c++20 -Wno-unknown-attributes -DHAS_THREAD_LOCAL
libcxxabi_cppflags += -DLIBCXXABI_USE_LLVM_UNWINDER=1 -D_LIBCPP_BUILDING_LIBRARY

ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
    libcxxabi_cppflags += -mbranch-protection=standard
endif

ifneq ($(LIBCXX_FORCE_REBUILD),true) # Using prebuilt

include $(CLEAR_VARS)
LOCAL_MODULE := libc++abi
LOCAL_SRC_FILES := $(SYSROOT_LIB_DIR)/$(LOCAL_MODULE)$(TARGET_LIB_EXTENSION)
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include

# Unlike the platform build, ndk-build will actually perform dependency checking
# on static libraries and topologically sort them to determine link order.
# Though there is no link step, without this we may link libunwind before
# libc++abi, which won't succeed.
LOCAL_STATIC_LIBRARIES += libunwind
LOCAL_EXPORT_STATIC_LIBRARIES := libunwind
include $(PREBUILT_STATIC_LIBRARY)

else # Building

include $(CLEAR_VARS)
LOCAL_MODULE := libc++abi
LOCAL_SRC_FILES := $(libcxxabi_src_files)
LOCAL_C_INCLUDES := $(libcxxabi_includes)
LOCAL_CPPFLAGS := $(libcxxabi_cppflags)
LOCAL_CPP_FEATURES := rtti exceptions
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)/include

# Unlike the platform build, ndk-build will actually perform dependency checking
# on static libraries and topologically sort them to determine link order.
# Though there is no link step, without this we may link libunwind before
# libc++abi, which won't succeed.
LOCAL_STATIC_LIBRARIES += libunwind
LOCAL_EXPORT_STATIC_LIBRARIES := libunwind
include $(BUILD_STATIC_LIBRARY)

endif # Prebuilt/building

# Define a prebuilt module for libunwind.a so that ndk-build adds it to the
# linker command-line before any shared libraries, ensuring that the unwinder
# is linked statically even if a shared library dependency exports an unwinder.
include $(CLEAR_VARS)
LOCAL_MODULE := libunwind
LOCAL_SRC_FILES := $(NDK_TOOLCHAIN_LIB_DIR)/$(TARGET_TOOLCHAIN_ARCH_LIB_DIR)/libunwind.a
include $(PREBUILT_STATIC_LIBRARY)

$(call import-module, android/support)
