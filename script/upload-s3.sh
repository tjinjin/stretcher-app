#!/bin/bash

aws s3 cp $CIRCLE_ARTIFACTS/application* $S3_BUCKET/assets/
