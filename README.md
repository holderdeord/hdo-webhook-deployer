[![Build Status](https://secure.travis-ci.org/holderdeord/hdo-webhook-deployer.png?branch=master)](http://travis-ci.org/holderdeord/hdo-webhook-deployer)
[![Coverage Status](https://coveralls.io/repos/holderdeord/hdo-webhook-deployer/badge.png?branch=master)](https://coveralls.io/r/holderdeord/hdo-webhook-deployer)
[![Code Climate](https://codeclimate.com/github/holderdeord/hdo-webhook-deployer.png)](https://codeclimate.com/github/holderdeord/hdo-webhook-deployer)
[![Dependency Status](https://gemnasium.com/holderdeord/hdo-webhook-deployer.png)](https://gemnasium.com/holderdeord/hdo-webhook-deployer)

Enables continuous deployment using [Travis webhooks](http://about.travis-ci.org/docs/user/notifications/#Webhook-notification) (https://github.com/holderdeord/hdo-site/issues/367).

Command replacements
--------------------

The 'command' from the config file may contain the following replacements:

* %{sha} - revision sha