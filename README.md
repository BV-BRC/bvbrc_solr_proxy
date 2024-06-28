# BV-BRC Solr Proxy

## Overview

The BV-BRC Solr proxy provides write access to the BV-BRC solr installation based on preconfigured credentials

The permissions for each collection are stored in a tab-delimited file
with the following columns:
```
  collection-name	BV_BRC username	  perms
```
Perms is a string including 'i' for insert, 'u' for update, 'd' for delete.

This proxy is used for services such as the [CEIRR data submission service](https://github.com/BV-BRC/bvbrc_ceirr_data_submission/tree/master) which upload data into the BV-BRC Solr database on behalf of an approved external user.

## About this module

This module is a component of the BV-BRC build system. It is designed to fit into the
`dev_container` infrastructure which manages development and production deployment of
the components of the BV-BRC. More documentation is available [here](https://github.com/BV-BRC/dev_container/tree/master/README.md).

