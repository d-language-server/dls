#!/usr/bin/env bash

modifiedFiles=$(git status --short | wc -l)

for sourceFile in $(find . -name '*.d')
do
    dfmt --inplace $sourceFile
done

if [[ $(git status --short | wc -l) != $modifiedFiles ]]
then
    exit 1
fi

exit 0
