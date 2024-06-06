#!/bin/sh

cd fe

elm-live src/Preview.elm --start-page=../preview.html -- --output=preview.js 
