#!/bin/bash

cd ../coalesce;
npm run-script build;
cd ../coalesce-ember;
# Hack to use the latest version of Coalesce
cp ../coalesce/dist/* bower_components/coalesce/
npm run-script build;