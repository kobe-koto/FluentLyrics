#!/bin/bash

VERSION_STRING=$(echo "$RELEASE_VERSION" | sed 's/^v//')
IFS='+'
read -r -a parts <<< "$VERSION_STRING"
unset IFS

VERSION_NAME="${parts[0]}"
VERSION_CODE="${parts[1]}"


if [ "$PRERELEASE" == "true" ]; then
    CHANGELOG_START_TAG="$(git describe --tags --abbrev=0 HEAD^ --match 'v*' 2>/dev/null)"
else
    CHANGELOG_START_TAG="$(git describe --tags --abbrev=0 HEAD^ --match 'v*' --exclude 'v*-r*' 2>/dev/null)"
fi
CHANGELOG_START="$(echo "$CHANGELOG_START_TAG" || git rev-list --max-parents=0 HEAD)"

{
    echo "## Release $RELEASE_VERSION"
    echo ""
    echo "New version has been released!"
    echo ""
    echo "### Changes since $CHANGELOG_START"
    echo ""
    git log --pretty=format:"* %s" "$CHANGELOG_START..HEAD"
    echo ""
    echo ""
    # Use envsubst to replace variables in the template
    VERSION_NAME=$VERSION_NAME envsubst < tool/downloads-template.md
} > release.md
