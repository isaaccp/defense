#!/bin/sh

cd $(git rev-parse --show-toplevel)

cp git/hooks/* .git/hooks/
