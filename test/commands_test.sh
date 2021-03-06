#!/bin/bash

. test/assert.sh

STUBS=test/stubs
PATH="$STUBS:./:$PATH"
DOKKU_ROOT="test/fixtures/dokku"
dokku="PATH=$PATH DOKKU_ROOT=$DOKKU_ROOT commands"

cp "test/fixtures/dokku/rad-app/nginx.conf.org" "test/fixtures/dokku/rad-app/nginx.conf"
cp "test/fixtures/dokku/readme-app/nginx.conf.org" "test/fixtures/dokku/readme-app/nginx.conf"
cp "test/fixtures/dokku/secure-app/nginx.conf.org" "test/fixtures/dokku/secure-app/nginx.conf"

# `domains` requires an app name
assert "$dokku domains" "You must specify an app name"
assert_raises "$dokku domains" 1

# `domains` requires an existing app
assert "$dokku domains foo" "App foo does not exist"
assert_raises "$dokku domains" 1

# `domains:set` requires an app name
assert "$dokku domains:set" "You must specify an app name"
assert_raises "$dokku domains:set" 1

# `domains:set` requires an existing app
assert "$dokku domains:set foo" "App foo does not exist"
assert_raises "$dokku domains:set foo" 1

# `domains:set` requires at least one domain
assert "$dokku domains:set rad-app" "Usage: dokku domains:set APP DOMAIN1 [DOMAIN2 ...]\nMust specify a DOMAIN."
assert_raises "$dokku domains:set rad-app" 1

# `domains:set` should modify nginx.conf, call pluginhook, and reload nginx
assert "$dokku domains:set rad-app radapp.com www.radapp.com" "[stub: pluginhook nginx-pre-reload rad-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/rad-app-nginx.conf")
assert "cat test/fixtures/dokku/rad-app/nginx.conf" "$expected"

# `domains` should read the set domains
assert "$dokku domains rad-app" "radapp.com www.radapp.com"

# test against an app configured with ssl
assert "$dokku domains:set secure-app vault.it www.vault.it " "[stub: pluginhook nginx-pre-reload secure-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/secure-app-nginx.conf")
assert "cat test/fixtures/dokku/secure-app/nginx.conf" "$expected"

assert "$dokku domains secure-app" "vault.it www.vault.it"

# run through the readme examples

## Create vhost with a second domain
assert "$dokku domains:set readme-app myawesomeapp.com www.myawesomeapp.com" "[stub: pluginhook nginx-pre-reload readme-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/readme-app-1-custom-domain-nginx.conf")
assert "cat test/fixtures/dokku/readme-app/nginx.conf" "$expected"
assert "$dokku domains readme-app" "myawesomeapp.com www.myawesomeapp.com"

## Create vhost with a second sub-domain:
assert "$dokku domains:set readme-app subdomain.myawesomeapp.com" "[stub: pluginhook nginx-pre-reload readme-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/readme-app-2-subdomain-nginx.conf")
assert "cat test/fixtures/dokku/readme-app/nginx.conf" "$expected"
assert "$dokku domains readme-app" "subdomain.myawesomeapp.com"

## Create vhost with a wildcard domain:
assert "$dokku domains:set readme-app *.myawesomeapp.com" "[stub: pluginhook nginx-pre-reload readme-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/readme-app-3-wildcard-nginx.conf")
assert "cat test/fixtures/dokku/readme-app/nginx.conf" "$expected"
assert "$dokku domains readme-app" "*.myawesomeapp.com"

## Create vhost with multiple additional domains:
assert "$dokku domains:set readme-app myawesomeapp.com www.myawesomeapp.com anotherawesomedomain.com www.anotherawesomedomain.com" "[stub: pluginhook nginx-pre-reload readme-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/readme-app-4-multiple-domains-nginx.conf")
assert "cat test/fixtures/dokku/readme-app/nginx.conf" "$expected"
assert "$dokku domains readme-app" "myawesomeapp.com www.myawesomeapp.com anotherawesomedomain.com www.anotherawesomedomain.com"

### Remove domains - Unlike heroku that uses `domains:add` and `domains:remove`, this plugin has only `domains:set`. To remove a domain, omit them from the arguments. So, if the domains are `myawesomeapp.com www.myawesomeapp.com anotherawesomedomain.com www.anotherawesomedomain.com` and you want to remove `anotherawesomedomain.com www.anotherawesomedomain.com`, run
assert "$dokku domains:set readme-app myawesomeapp.com www.myawesomeapp.com" "[stub: pluginhook nginx-pre-reload readme-app]\n[stub: sudo /etc/init.d/nginx reload]"
expected=$(< "test/expected/readme-app-1-custom-domain-nginx.conf")
assert "cat test/fixtures/dokku/readme-app/nginx.conf" "$expected"
assert "$dokku domains readme-app" "myawesomeapp.com www.myawesomeapp.com"

# end of test suite
assert_end examples

echo "" > test/fixtures/dokku/rad-app/DOMAINS
echo "" > test/fixtures/dokku/secure-app/DOMAINS
echo "" > test/fixtures/dokku/readme-app/DOMAINS
rm "test/fixtures/dokku/rad-app/nginx.conf"
rm "test/fixtures/dokku/secure-app/nginx.conf"
rm "test/fixtures/dokku/readme-app/nginx.conf"

exit 0
