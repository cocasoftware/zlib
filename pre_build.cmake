# zlib pre_build.cmake — COCA framework integration
# Configures zlib's upstream CMake options before add_subdirectory().

# Static-only platforms: musl sysroots and wasm-wasi lack shared libc, so
# shared libraries cannot be linked.  Fall back to static on these targets.
set(_ZLIB_STATIC_ONLY FALSE)
if(COCA_TARGET_PROFILE MATCHES "musl|wasm")
    set(_ZLIB_STATIC_ONLY TRUE)
endif()

if(_ZLIB_STATIC_ONLY)
    set(ZLIB_BUILD_SHARED OFF CACHE BOOL "" FORCE)
else()
    set(ZLIB_BUILD_SHARED ON  CACHE BOOL "" FORCE)
endif()
set(ZLIB_BUILD_STATIC ON  CACHE BOOL "" FORCE)

set(ZLIB_BUILD_TESTING ON CACHE BOOL "" FORCE)

# Disable install targets — COCA manages artifact layout.
set(ZLIB_INSTALL OFF CACHE BOOL "" FORCE)
