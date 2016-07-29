-- FHS directories for binaries and manual pages:
shell.setPath(shell.path()..':/bin')
help.setPath(help.path()..':/usr/man')
-- man => help
shell.setAlias("man", "help")
