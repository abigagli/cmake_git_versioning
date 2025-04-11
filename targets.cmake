set(VERSION_TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/version.c.in")
set(VERSION_OUTPUT "${CMAKE_BINARY_DIR}/generated/version.c")

# Usually the correct approach to use generated files is a custom_command / custom_target combination because:
# 1) It avoids rerunning the command every time: if you make the custom target directly contain the COMMAND
#    that generates the VERSION_OUTPUT file, since a custom_target is always considered out-of-date,
#    then the file generation will take place everytime that any target that depends on _generate_versionoing_info
#    custom target is considered. If instead the custom target depends on a file that is produced by a custom command
#    then such custom command will only be invoked when the file dependency needs to be created
# 2) It avoids problems with parallel builds: you could directly list the output of the custom command
#    (i.e. the generated file) in the source files of your real target, and the custom command would be run
#    if such file doesn't exist, but this causes problems if multiple targets needs that file and you
#    perform a parallel build

#add_custom_command(
#        OUTPUT ${VERSION_OUTPUT}
#        DEPENDS ${VERSION_TEMPLATE} ${CMAKE_CURRENT_LIST_DIR}/generate_versioning_info.cmake
#        COMMAND ${CMAKE_COMMAND}
#        -DVERSION_TEMPLATE=${VERSION_TEMPLATE}
#        -DVERSION_OUTPUT=${VERSION_OUTPUT}
#        -P ${CMAKE_CURRENT_LIST_DIR}/generate_versioning_info.cmake
#        COMMENT "Generating versioning information"
#)
#add_custom_target(
#        _generate_versioning_info
#        DEPENDS ${VERSION_OUTPUT}
#)

# But in this specific case, where the generated file must be regenerated upon git status changes,
# it is better to ensure the command is executed directly by the custom target so that it will be
# executed everytime, and then put some logic in the generate_versioning_info.cmake script that avoids
# changing the VERSION_OUTPUT file if the git state didn't change, so that the actual target that
# depends on VERSION_OUTPUT is not rebuilt everytime

add_custom_target(
        _generate_versioning_info
        COMMENT "Generating versioning information"
        DEPENDS ${VERSION_TEMPLATE} ${CMAKE_CURRENT_LIST_DIR}/generate_versioning_info.cmake
        COMMAND ${CMAKE_COMMAND}
        #-DGIT_SHA_CACHE=${GIT_SHA_CACHE}
        -DGIT_FOLDER="${CMAKE_SOURCE_DIR}/.git"
        -DVERSION_TEMPLATE=${VERSION_TEMPLATE}
        -DVERSION_OUTPUT=${VERSION_OUTPUT}
        -P ${CMAKE_CURRENT_LIST_DIR}/generate_versioning_info.cmake
        BYPRODUCTS ${VERSION_OUTPUT})

add_library(git_version ${VERSION_OUTPUT})
target_include_directories(git_version PUBLIC ${CMAKE_CURRENT_LIST_DIR})
add_dependencies(git_version _generate_versioning_info)
add_library(VERSIONING::git_version ALIAS git_version)

# REMEMBER: include this file, then add a dependency on the "VERSIONING::git_version" target
# to your targets
#
# e.g.:
#
# include (cmake/versioning/targets.cmake)
# add_executable (my_application main.cpp ...)
# target_link_libraries (my_application VERSIONING::git_version)
