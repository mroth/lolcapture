#!/bin/bash
# This is a simple example of a postcapture hook that uses terminal-notifier
# to post to the MacOSX notification center.
if hash terminal-notifier 2>/dev/null; then
    terminal-notifier \
        -title "lolcommits" \
        -message "History preserved for commit ${LOLCAPTURE_COMMIT_SHA} on ${LOLCAPTURE_REPO_NAME}" \
        -contentImage "$LOLCAPTURE_IMAGE" \
        -open "file://${LOLCAPTURE_IMAGE}"
else
    echo "terminal notifier is not installed!"
    echo "do `brew install terminal-notifier` to get it."
    exit 1
fi
