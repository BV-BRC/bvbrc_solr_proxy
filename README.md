# BV-BRC Solr Proxy

Proxies write access to the BV-BRC solr installation.

We define a collection credentials file as a tab-delimited file
with the following columns:

  collection-name	BRC username	perms

Perms is a string including 'i' for insert, 'u' for update, 'd' for delete.


