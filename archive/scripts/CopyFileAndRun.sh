#!/bin/bash

# Combining suggestions in http://stackoverflow.com/questions/36597108,
# http://stackoverflow.com/questions/9057387

# If the first argument exists as a file, copy it to replace the
# second argument.  Either way, notify of what happened.
if [ -e $1 ]; then
  echo "Copying file in $1 to $2"
  cp $1 $2
else 
  echo "No file found in $1, $2 is not updated"
fi

# Then run the requested command
exec ${@:3}
