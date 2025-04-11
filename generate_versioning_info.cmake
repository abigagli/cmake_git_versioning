# This script runs at build time
find_package(Git QUIET)

function(CheckGitWrite git_hash)
    file(WRITE ${CMAKE_BINARY_DIR}/git-state.txt ${git_hash})
endfunction()

function(CheckGitRead git_hash)
    if (EXISTS ${CMAKE_BINARY_DIR}/git-state.txt)
        file(STRINGS ${CMAKE_BINARY_DIR}/git-state.txt CONTENT)
        LIST(GET CONTENT 0 var)

        set(${git_hash} ${var} PARENT_SCOPE)
    endif ()
endfunction()


if(GIT_FOUND)
    # Get the latest commit hash
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_SHA
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Get the short commit hash
    execute_process(
            COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_SHA_SHORT
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    # Check if working tree is dirty
    execute_process(
            # Git diff-index returns 0 if clean, 1 if dirty
            COMMAND ${GIT_EXECUTABLE} diff-index --quiet HEAD --
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            RESULT_VARIABLE GIT_DIRTY_CHECK
            OUTPUT_QUIET
            ERROR_QUIET
    )

    # Get commit date
    execute_process(
            COMMAND ${GIT_EXECUTABLE} log -1 --format=%cd --date=iso
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE GIT_COMMIT_DATE
            OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    CheckGitRead(GIT_SHA_CACHE)
    if (NOT DEFINED GIT_SHA_CACHE)
        set(GIT_SHA_CACHE "INVALID")
    endif ()

    set (UPDATE_VERSION_OUTPUT OFF)
    # Only update the VERSION_OUTPUT file if the hash has changed. This will
    # prevent us from rebuilding the project more than we need to.
    if (NOT ${GIT_SHA} STREQUAL ${GIT_SHA_CACHE} OR NOT EXISTS ${VERSION_OUTPUT})
        # Set che GIT_SHA_CACHE variable so the next build won't have
        # to regenerate the source file if git state didn't change
        CheckGitWrite(${GIT_SHA})
        set (UPDATE_VERSION_OUTPUT ON)
    endif()



    if(GIT_DIRTY_CHECK)
        set(GIT_SHA "${GIT_SHA}-dirty")
        set(GIT_SHA_SHORT "${GIT_SHA_SHORT}-dirty")
    endif()

else()
    set(GIT_SHA "unknown")
    set(GIT_SHA_SHORT "unknown")
    set(GIT_COMMIT_DATE "unknown")
endif()

# Set build timestamp
string(TIMESTAMP BUILD_TIMESTAMP "%Y-%m-%d %H:%M:%S")

# Configure the VERSION_OUTPUT file if needed
if(UPDATE_VERSION_OUTPUT)
    message(STATUS "Updating ${VERSION_OUTPUT}")
    configure_file(
            ${VERSION_TEMPLATE}
            ${VERSION_OUTPUT}
    )
endif()