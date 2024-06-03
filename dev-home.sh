#!/bin/sh

cd fe

elm-live src/Home.elm --start-page=../index.html -- --output=elm.js 
