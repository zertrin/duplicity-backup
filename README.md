[![Build Status](https://travis-ci.org/zertrin/duplicity-backup.svg?branch=dev)](https://travis-ci.org/zertrin/duplicity-backup)

# duplicity-backup.sh

This bash script was designed to automate and simplify the remote backup process of [duplicity](http://duplicity.nongnu.org/) on Amazon S3 primarily. Other backup destinations are possible (Google Cloud Storage, FTP, SFTP, SCP, rsync, file...), i.e. any of duplicity's supported outputs.

After your script is configured, you can easily backup, restore, verify and clean (either via cron or manually) your data without having to remember lots of different command options and passphrases.

Most importantly, you can easily backup the script and your gpg key in a convenient passphrase-encrypted file. This comes in in handy if/when your machine ever does go belly up.

Optionally, you can set up an email address where the log file will be sent, which is useful when the script is used via cron.

This version is a rewriting of the code originally written by [Damon Timm](https://github.com/thornomad), including many patches that have been brought to the original scripts by various forks on Github. Thanks to all the contributors!

More information about this script is available at https://zertrin.org/projects/duplicity-backup/

The original version of the code is available at https://github.com/theterran/dt-s3-backup


## duplicity-backup.sh IS NOT duplicity

It is only a wrapper script for duplicity written in bash!

This means the following:

* You need to install AND configure duplicity BEFORE using duplicity-backup.sh
* [The official documentation of duplicity](http://duplicity.nongnu.org/duplicity.1.html) is relevant to duplicity-backup.sh too. Virtually any option supported by duplicity can be specified in the config file of duplicity-backup.sh. See the `STATIC_OPTIONS`, `CLEAN_UP_TYPE` and `CLEAN_UP_VARIABLE` parameters in particular.
* Before asking something about duplicity-backup.sh, ensure that your question isn’t actually concerning duplicity ;) First, make sure you can perform a backup with duplicity without using this script. If you can't make the backup work with duplicity alone, the problem is probably concerning duplicity and not this script. If you manage to make a backup with duplicity alone but not with this script, then there is probably a problem with duplicity-backup.sh.
* In particular, to the question "_Does duplicity-backup.sh support the backend XXX_" (with XXX being for example Amazon Glacier), the answer is always the same: "_duplicity-backup.sh uses duplicity, so ask the developers of duplicity ;) Once it's in duplicity, it's automatically available to duplicity-backup.sh_"


## Contributing

The development version of the code is available at https://github.com/zertrin/duplicity-backup in the `dev` branch. It is a bleeding-edge version with the latests changes that have not yet been tested a lot, but that's the best starting point to contribute.

Pull requests are welcome! However please **always use individual feature branches for each pull request**. I may not accept a pull request from a master or dev branch.

Here is how to do it:

Fork the repository first and then clone your fork on your machine:

    git clone git@github.com:YOURNAME/duplicity-backup.git
    cd duplicity-backup

Add a remote for the upstream repository:

    git remote add upstream git@github.com:zertrin/duplicity-backup.git
    git fetch upstream

Create a new topic branch for the changes you want to make, based on the `dev` branch from upstream:

    git checkout -b my-fix-1 upstream/dev

Make your changes, test them, commit them and push them to Github:

    git push origin my-fix-1

Open a Pull request from `YOURNAME:my-fix-1` to `zertrin:dev`.

If you want to open another pull request for another change which is independant of the previous one, just create another topic branch based on master (`git checkout -b my-fix-2 upstream/dev`)


## Installation

### 1. Get the script

You can clone the repository (which makes it easy to get future updates):

    git clone https://github.com/zertrin/duplicity-backup.git duplicity-backup

If you prefer the stable version do:

    git checkout stable

... or if you want the latest version (might still have bugs), then:

    git checkout master

... or if you like living on the edge, you can stay at the development version which is automatically cloned.

Or just download the ZIP file:

* For the stable branch: https://github.com/zertrin/duplicity-backup/archive/stable.zip
* For the normal branch: https://github.com/zertrin/duplicity-backup/archive/master.zip

### 2. Configure the script

This script requires user configuration. Instructions are in the config file itself and should be self-explanatory. You SHOULD NOT edit the example config file `duplicity-backup.conf.example`, but instead make a copy of it (for example to `/etc/duplicity-backup.conf`) and edit this one.

Be sure to replace all the *foobar* values with your real ones. Almost every value needs to be configured in someway.

The script looks for its configuration by reading the path to the config file specified by the command line option `-c` or `--config` (see [Usage](#usage))

If no config file was given on the command line, the script will try to find the file specified in the `CONFIG` parameter at the beginning of the script (default: `duplicity-backup.conf` in the script's directory).

So be sure to either:
* specify the configuration file path on the command line with the -c option **[recommended]**
* or to edit the `CONFIG` parameter in the script to match the actual location of your config file. **[deprecated]** _(will be removed in future versions of the script)_

NOTE: to ease future updates of the script, you may prefer NOT to edit the script at all and to specify systematically the path to your config file on the command line with the `-c` or `--config` option.

You can use one copy of the script and call it with different config file for different backup scenarios. It is designed to run as a cron job and will log information to a text file (including remote file sizes, if you use Amazon S3 and have `s3cmd` installed).

### Misc

Be sure to make the script executable if needed (`chmod +x`) before you hit the gas.


## Upgrade

### 1. Get the new version

If you got the script by cloning the repository, upgrading is easy:

    git pull

else just download again the ZIP archive an extract it over the existing folder. (Don't forget to keep a backup of the previous folder to be able to rollback easily if needed)

### 2. Adapt the config file if needed

Then compare the example config file (`duplicity-backup.conf.example`) with your modified version (for example `/etc/duplicity-backup.conf`) and adapt your copy to reflect the changes in the example file.

Thare are many ways to do so, here are some examples (adapt the path to your actual files):

    diff duplicity-backup.conf.example /etc/duplicity-backup.conf
    vimdiff duplicity-backup.conf.example /etc/duplicity-backup.conf


## Dependancies

* [duplicity](http://duplicity.nongnu.org/)
* Basic utilities like: [bash](https://www.gnu.org/software/bash/), [which](http://unixhelp.ed.ac.uk/CGI/man-cgi?which), [find](https://www.gnu.org/software/findutils/) and [tee](http://linux.die.net/man/1/tee) (should already be available on most Linux systems)
* [gpg](https://www.gnupg.org/) *`optional`* (if using encryption)
* [mailx](http://linux.die.net/man/1/mailx) *`optional`* (if sending mail is activated in the script)

For the [Amazon S3](https://aws.amazon.com/s3/) storage backend *`optional`*
* [s3cmd](http://s3tools.org/s3cmd) *`optional`*

For the [Google Cloud Storage](https://cloud.google.com/storage/) storage backend *`optional`*
* [boto](https://github.com/boto/boto) (may already have been installed with duplicity)
* [gsutil](https://cloud.google.com/storage/docs/gsutil) *`optional`*


## Usage

    duplicity-backup.sh [options]

      Options:
        -c, --config CONFIG_FILE   specify the config file to use

        -b, --backup               runs an incremental backup
        -f, --full                 forces a full backup
        -v, --verify               verifies the backup
        -l, --list-current-files   lists the files currently backed up in the archive
        -s, --collection-status    show all the backup sets in the archive

            --restore [PATH]       restores the entire backup to [path]
            --restore-file [FILE_TO_RESTORE] [DESTINATION]
                                   restore a specific file
            --restore-dir [DIR_TO_RESTORE] [DESTINATION]
                                   restore a specific directory

        -t, --time TIME            specify the time from which to restore or list files
                                   (see duplicity man page for the format)

        --backup-script            automatically backup the script and secret key(s) to
                                   the current working directory

        -n, --dry-run              perform a trial run with no changes made
        -d, --debug                echo duplicity commands to logfile


## Usage Examples

**View help:**

    duplicity-backup.sh

**Run an incremental backup:**

    duplicity-backup.sh [-c config_file] --backup

**Force a one-off full backup:**

    duplicity-backup.sh [-c config_file] --full

**Restore your entire backup:**

    # You will be prompted for a restore directory
    duplicity-backup.sh [-c config_file] --restore

    # You can also provide a restore folder on the command line.
    duplicity-backup.sh [-c config_file] --restore /home/user/restore-folder

**Restore a specific file or directory in the backup:**

Note that the commands `--restore-file` and `--restore-dir` are equivalent.

    # You will be prompted for a file to restore to the current directory
    duplicity-backup.sh [-c config_file] --restore-file

    # Restores the file img/mom.jpg to the current directory
    duplicity-backup.sh [-c config_file] --restore-file img/mom.jpg

    # Restores the file img/mom.jpg to /home/user/i-love-mom.jpg
    duplicity-backup.sh [-c config_file] --restore-file img/mom.jpg /home/user/i-love-mom.jpg

    # Restores the directory rel/dir/path to /target/restorepath
    duplicity-backup.sh [-c config_file] --restore-dir rel/dir/path /target/restorepath

**List files in the remote archive**

    duplicity-backup.sh [-c config_file] --list-current-files

**See the collection status (i.e. all the backup sets in the remote archive)**

    duplicity-backup.sh [-c config_file] --collection-status

**Verify the backup**

    duplicity-backup.sh [-c config_file] --verify

**Backup the script and gpg key in a encrypted tarfile (for safekeeping)**

    duplicity-backup.sh [-c config_file] --backup-script


## Cron Usage Example

    41 3 * * * /absolute/path/to/duplicity-backup.sh -c /etc/duplicity-backup.conf -b


## Known issues

If your system's locale is not english, an error can happen when duplicity is trying to encrypt the files with gpg. This problem concerns duplicity and has been reported upstream ([see bug report](https://bugs.launchpad.net/duplicity/+bug/510625)). A simple workaround is to set the following environement variable: `LANG=C`. For example: `LANG=C duplicity-backup.sh [-c config_file] ...` or in the cron `41 3 * * * LANG=C /absolute/path/to/duplicity-backup.sh -c /etc/duplicity-backup.conf -b`


## Troubleshooting

This script attempts to simplify the task of running a duplicity command; if you are having any problems with the script the first step is to determine if the script is generating an incorrect command or if duplicity itself is causing your error.

To see exactly what is happening when you run duplicity-backup, either pass the option `-d` or `--debug` on the command line, or head to the bottom of the configuration file and uncomment the `ECHO=$(which echo)` variable. 

This will stop the script from running and will, instead, output the generated command into your log file. You can then check to see if what is being generated is causing an error or if it is duplicity causing you woe.

You can also try the `-n` or `--dry-run` option. This will make duplicity to calculate what would be done, but does not perform any backend actions. Together with info verbosity level (-v8) duplicity will list all files that will be affected. This way you will know exactly which files will be backed up or restored.


## Wish List

* Backup to multiple destinations with one config file
* Show backup-ed files in today incremental backup email


###### Thanks to all the [contributors](https://github.com/zertrin/duplicity-backup/graphs/contributors) for their help.

