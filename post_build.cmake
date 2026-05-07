# zlib post_build.cmake — COCA framework integration
# Executed after add_subdirectory(zlib) to:
#   (1) provide a uniform `zlib` target for static-only platforms
#   (2) fix coverage linking on clang-cl + lld-link

# -- (1) Uniform target name -----------------------------------------------
# Architectural invariant: COCA's auto-generated framework CMakeLists.txt
# spells dependencies by framework NAME, e.g. ``target_link_libraries(
# test_zlib PUBLIC catch2 zlib)``.  Upstream zlib only creates the ``zlib``
# CMake target when ``ZLIB_BUILD_SHARED`` is ON; on static-only platforms
# (musl, wasm) ``pre_build.cmake`` forces it OFF so only ``zlibstatic``
# exists.  Without this alias, the consumer's link line silently degrades
# to a literal ``-lzlib`` flag, dropping zlib's INTERFACE include dirs and
# breaking the build with ``'zlib.h' file not found``.
#
# Synthesise the alias so the framework's public surface (the target named
# after the framework itself) is identical across every platform — the
# platform-specific shared-vs-static choice stays an implementation detail
# of the zlib framework, never leaks to consumers.
if(TARGET zlibstatic AND NOT TARGET zlib)
    add_library(zlib ALIAS zlibstatic)
endif()

# -- (2) Coverage linking fix ----------------------------------------------
# Problem: zlib's test/CMakeLists.txt adds `-coverage` as a link option for
# the `infcover` target.  In clang-cl + lld-link mode, `-coverage` is passed
# directly to lld-link which ignores it (unknown argument warning).  The
# compiler-rt profile runtime (providing llvm_gcda_* symbols) is never linked.
#
# Fix: if the `infcover` target exists, replace the broken `-coverage` link
# option with an explicit link to clang_rt.profile and add the compiler-rt
# library directory to its search path.

if(TARGET infcover)
    # Remove the raw `-coverage` link option that lld-link cannot understand
    get_target_property(_infcover_link_opts infcover LINK_OPTIONS)
    if(_infcover_link_opts)
        list(REMOVE_ITEM _infcover_link_opts "-coverage")
        set_target_properties(infcover PROPERTIES LINK_OPTIONS "${_infcover_link_opts}")
    endif()

    # Explicitly link the compiler-rt profile runtime.
    # zlib uses the plain signature for target_link_libraries on infcover
    # (line 97: target_link_libraries(infcover ZLIB::ZLIBSTATIC)), so we
    # must also use the plain signature to avoid CMake's mixed-signature error.
    if(MSVC OR CMAKE_C_SIMULATE_ID STREQUAL "MSVC")
        target_link_libraries(infcover clang_rt.profile-x86_64)
    else()
        # GNU-like driver: --coverage as a linker flag works through the driver
        target_link_options(infcover PRIVATE --coverage)
    endif()
endif()
