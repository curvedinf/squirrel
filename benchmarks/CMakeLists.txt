set(CMAKE_C_STANDARD 99)

if(NOT DISABLE_DYNAMIC)
  add_executable(sqbench sqbench.c)
  target_link_libraries(sqbench squirrel sqstdlib)
  target_include_directories(sqbench PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )
endif()

if(NOT DISABLE_STATIC)
  add_executable(sqbench_static sqbench.c)
  target_link_libraries(sqbench_static squirrel_static sqstdlib_static)
  target_include_directories(sqbench_static PUBLIC
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
    )
endif()

if(LONG_OUTPUT_NAMES)
  if(NOT DISABLE_DYNAMIC)
    set_target_properties(sqbench PROPERTIES OUTPUT_NAME squirrel3_bench)
  endif()

  if(NOT DISABLE_STATIC)
    set_target_properties(sqbench_static PROPERTIES OUTPUT_NAME squirrel3_bench_static)
  endif()
endif()
