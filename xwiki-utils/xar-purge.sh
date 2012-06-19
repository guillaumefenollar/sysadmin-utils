#!/bin/bash

echo "Choose a version between XE and XEM [default:XE]"
read package_type


echo "What version of XE are you using?"
read xar_version


wget http://download.forge.objectweb.org/xwiki/xwiki-enterprise-ui-all-4.0.xar
