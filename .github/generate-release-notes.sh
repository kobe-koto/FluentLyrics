#!/bin/bash

VERSION_NO_V=$(echo $RELEASE_VERSION | sed 's/^v//')
export VERSION_NO_V

echo "## Release $RELEASE_VERSION" > release.md
echo "" >> release.md
echo "New version has been released!" >> release.md
echo "" >> release.md
echo "### Changes" >> release.md
echo "" >> release.md
git log --pretty=format:"* %s" $(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD >> release.md
echo "" >> release.md
echo "" >> release.md

# Use envsubst to replace variables in the template
envsubst < .github/release-template.md >> release.md
