#!/bin/bash
#
# This script verifies the sources downloaded by 'retrieve-sources.sh'.
#
# Cannot verify anything if the sources directory is missing.
if [ ! -d sources ]; then
  echo "Error: You must run 'retrieve-sources.sh' first." >&2
  exit 1
fi
# Change into the sources directory.
cd sources
# Run recursive sha256sum on all downloaded files.
cat ../source-urls.sha256 | sha256sum -c
STATUS=$?
# Ensure everything verified successfully.
if [ $STATUS -ne 0 ]; then
  echo -e "\nOne or file(s) failed to verify successfully." >&2
  echo "Check the above output to determine which one. Then, modify its" >&2
  echo "URL in 'source-urls', AND/OR its checksum in 'source-urls.sha256'." >&2
  exit $STATUS
else
  echo -e "\nGood, it looks like everything verified successfully!"
  echo "You can now begin the build of MassOS by running './stage1.sh'."
fi
