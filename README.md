In your top-level CMakeLists.txt:

```cmake
project(
  myproject
  LANGUAGES ...
  VERSION 1.0)

include(cmake/versioning/targets.cmake)
```

Then for every target that you want to enable versioning on:

```cmake
add_executable (my_application main.cpp ...)
target_link_libraries (my_application VERSIONING::git_version)

```
