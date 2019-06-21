#!/bin/bash

# https://gohugo.io/hosting-and-deployment/hosting-on-github/

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

(
    cd public &&
    git fetch && 
    git checkout -f master &&
    git reset --hard origin/master
)

# Build the project.
hugo # if using a theme, replace by `hugo -t <yourtheme>`

# Go To Public folder
cd public
# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date +\"%F %T\"`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ..
