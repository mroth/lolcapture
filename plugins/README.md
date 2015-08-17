lolcapture plugins function almost identically to git hooks, in that they can be
any executable file, and lolcapture will run them agnostically. (Unlike actual
git hooks, they are configured via `gitconfig` rather than via a specific file
path in a repository, so that one can easily configure them globally.)

Currently there is only one plugin hook: `lolcapture.post-hook`, which is executed postcapture.

You should configure this variable to be the path to an executable.  When
lolcapture finishes doing it's thing, it will execute your

For example:

    $ git config --global lolcapture.post-hook ~/lolcapture/plugins/notifier.sh

By using `git config --local` or `--global` you can setup a plugin either for
all lolcaptures or only for specific repositories. See the main README on the
lolcapture configuration system for more details on this.

See the example files in this directory for some ideas as to how to write your
own plugins.

Currently only a single plugin can be assigned to a hook.  _This is a feature._
