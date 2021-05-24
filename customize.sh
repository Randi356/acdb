SKIPUNZIP=1

# Audio Configuration Database operations
# gh

unzip -o "$ZIPFILE" module.prop -d $MODPATH >&2
unzip -o "$ZIPFILE" 'META-INF/*' -d $TMPDIR >&2

source $TMPDIR/META-INF/functions

go
