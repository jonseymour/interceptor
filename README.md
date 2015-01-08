NAME
====
interceptor.sh - implements a command that can intercept, and log, the arguments, stdin, stdout and exit status of every call to the intercepted command.

SYNOPSIS
========

interceptor.sh install {some-cmd}
---------------------------------
Install interceptor.sh in place of {some-cmd} and capture the arguments, stdin, stdout and exit status of every call to the intercepted command.

interceptor.sh uninstall {some-cmd}
-----------------------------------
Removes the interception hook.

interceptor.sh intercept {cmd} {args}
-------------------------------------
Run the specified command and log the results to a subdirectory of `interceptor.sh log-root {cmd}`

interceptor.sh is-intercepted {cmd}
-----------------------------------
Outputs true and exits with true if the specified cmd is currently intercepted or outputs false and exits with false otherwise.

interceptor.sh intercepted {cmd}
--------------------------------
Answers the name where the original implementaton of the intercepted command is moved to.

interceptor.sh log-root [{cmd}]
-------------------------------
Answers the directory containing the log files for all intercepted command or just the specified cmd.

