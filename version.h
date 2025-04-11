#pragma once
#if defined(__cplusplus)
extern "C"
{
#endif

char const *git_sha();
char const *git_sha_short();
char const *git_commit_date();
char const *build_timestamp();

#if defined(__cplusplus)
}
#endif