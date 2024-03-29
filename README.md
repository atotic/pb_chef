+ Can we have a vagrantfile (yes)
+ are database migrations happening? (yes)
- how do i rollback
- what is it doing?

Everything lives in /var/www/pookio
/var/www/pookio/pb_server/shared/pb_data is where logs are
service chrome restart to restart chrome

Inside pb_server you get 3 dirs: shared/release/current
When deploying, pulls git, runs migrations, less compile
site-cookbooks/pookio/recipes/default.rb is where stuff happens

pb\_chef
=======

The chef scripts here will help you bring up a new machine for pook.io development/production. If you want to bring up a VM at `dev.pook.io`, you should first:

  * add `dev.pook.io` to your `/etc/hosts` at the IP you assign the VM.
    If you're using Vagrant, you can assign an IP in the `Vagrantfile` like this:

        config.vm.network :private_network, ip: "192.168.2.11"

  * add an entry to your `~/.ssh/config` for `dev.pook.io` like this:

        Host dev.pook.io
        HostName 192.168.2.11
        User vagrant
        ForwardAgent yes

  * Drop your ssh public key in `~vagrant/.ssh/authorized_keys` (or wherever is appropriate). (You can get on the box to do this by running `vagrant ssh`.)

Then you'll be ready to do chef work. Pook.io uses chef-solo, which works by opening an ssh connection from your machine to the box-to-be-configured, and running the appropriate commands remotely.

A couple commands to get started:

    bundle install          # installs gems from Gemfile
    librarian-chef install  # installs cookbooks from Cheffile

You only need to run those commands once, and they will install all the gems and cookbooks you'll need. (A "cookbook" is a collection of one or more "recipes," which are scripts in Chef to do some discrete task, like installing a web server.) Next you'll need to install chef on the remote machine. You can do that like this:

    knife solo prepare dev.pook.io

While that works, you should add the `secrets.json` data bag file, which is kept out of Git because it contains passwords and other secrets. First create a directory for it:

    mkdir -p data_bags/pookio

Then create a file in that directory called secrets.json. It should look like this:

    {
      "id": "secrets",
      "production": {
        "postgres_user": "pookio",
        "postgres_pw": "TODO",
        "fb_app_id": "TODO",
        "fb_secret": "TODO",
        "google_key": "TODO",
        "google_secret": "TODO"
      },
      "development": {
        "postgres_user": "pookio",
        "postgres_pw": "TODO",
        "fb_app_id": "TODO",
        "fb_secret": "TODO",
        "google_key": "TODO",
        "google_secret": "TODO"
      }
    }

Of course you should use real values instead of `TODO`.

When that's done, you can actually apply the chef scripts like this:

    knife solo cook dev.pook.io

You only need to run `prepare` once, when you have a fresh machine. After than you should just run `cook` to apply new changes.

Chef's "run list" for a machine is defined in `nodes`. For instance, for `dev.pook.io`, `nodes/dev.pook.io.json` controls how the machine will be configured. That file has a "run list," or a list of recipes to apply to the machine, along with a bunch of attributes that are used as arguments to the recipes.

Most of the recipes are standard, like install nginx or postgres, but the final recipe, `pookio`, has our application-specific instructions. This recipe is implemented in `site-cookbooks/pookio/recipes/default.rb`.


vagrant
=======

To bring up a VM, you can ignore the above and just use the Vagrantfile provided here. Once you've installed vagrant, just run these commands:

    bundle install
    vagrant plugin install vagrant-librarian-chef
    vagrant plugin install vagrant-omnibus
    vangrant up

The Vagrantfile is configured to automatically run the same recipes as described above when vagrant brings up the VM.

