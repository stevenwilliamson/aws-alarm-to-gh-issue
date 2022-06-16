#!/bin/bash

rm function.zip
zip -r function.zip *
aws-vault exec dev -- aws lambda update-function-code --function-name alarm-to-gh-issue --zip-file fileb://function.zip
