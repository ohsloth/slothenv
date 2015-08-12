# Cuebenv

What is it?
====
This is a companion utility to [Cueb](https://cueb.io) to trigger contextual information when you `cd`.

To enable it for a directory, create a `.cueb` file and enter the tags of the repos stored in cueb you
would like to trigger.

For example,

    $ touch project/.cueb
    $ echo #awesome > project/.cueb
    $ cd project

    Now visit https://cueb.io/stream

How to install
====
Install using git

    $ git clone git://github.com/cuebapp/cuebenv.git ~/.cuebenv
    $ echo 'source ~/.cuebenv/activate.sh' >> ~/.bashrc

Next, you need to open `~/.cuebenv/cred.ini` and enter your information

    cueb_username=YOUR_USERNAME
    cueb_api_key=YOUR_API_KEY

These information can be obtained on [settings](https://cueb.io/settings) after you create an account.

Disclaimer
===
This is based on [autoenv](https://github.com/kennethreitz/autoenv) and it overrides `cd`.

If you already do this, you will have to add `cuebenv_init` within your custom `cd` after sourcing `activate.sh`.

Credits
===
[autoenv](https://github.com/kennethreitz/autoenv).
