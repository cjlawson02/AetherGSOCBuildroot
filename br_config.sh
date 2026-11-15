#!/usr/bin/bash

make -C buildroot BR2_EXTERNAL=../br2_external O=../build GSOC_defconfig
