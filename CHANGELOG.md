# 1.1.1+1
* Fix a bug that threw when `--observe` was not present.

# 1.1.1
* Disable the observatory from pausing the isolate
on exceptions, because Angel already handles
all exceptions by itself.