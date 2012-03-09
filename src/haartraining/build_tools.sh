#! /bin/bash

# Build the tools mergevec, haartraining, and createsamples for training
# haar-like classifier

echo 'Building tools.'
for tool in mergevec haartraining createsamples; do
    g++ -I. `pkg-config --cflags opencv` `pkg-config --libs opencv` -o $tool \
        $tool.cpp cvboost.cpp cvcommon.cpp cvsamples.cpp cvhaarclassifier.cpp \
        cvhaartraining.cpp
done