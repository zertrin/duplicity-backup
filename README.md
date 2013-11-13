# duplicity-backup

This bash script was designed to automate and simplify the remote backup process of duplicity on Amazon S3 primarily. Other backup destinations are possible (FTP, SFTP, SCP, rsync, file...), i.e. any of duplicity's supported outputs.

After your script is configured, you can easily backup, restore, verify and clean (either via cron or manually) your data without having to remember lots of different command options and passphrases.

Most importantly, you can easily backup the script and your gpg key in a convenient passphrase-encrypted file. This comes in in handy if/when your machine ever does go belly up.

Optionally, you can set up an email address where the log file will be sent, which is useful when the script is used via cron.

This version is a rewriting of the code originally written by [Damon Timm](https://github.com/thornomad), including many patches that have been brought to the original scripts by various forks on Github.


## Contributing

Latest version of the code is available at http://github.com/zertrin/duplicity-backup

Pull requests are welcome! However please **always use individual feature branches for each pull request**. I will not accept any pull request from master branches.

More information about this script is available at http://zertrin.org/projects/duplicity-backup/

The original version of the code is available at http://github.com/theterran/dt-s3-backup


## Before you start

This script requires user configuration. Instructions are in the config file itself and should be self-explanatory. You SHOULD NOT edit the example config file `duplicity-backup.conf.example`, but instead make a copy of it (typical examples are `duplicity-backup.conf` in the same directory as the script or `/etc/duplicity-backup.conf`) and edit this one.

Be sure to replace all the *foobar* values with your real ones. Almost every value needs to be configured in someway.

You can use one copy of the script with different settings for different backup scenarios. It is designed to run as a cron job and will log information to a text file (including remote file sizes, if you use Amazon S3 and have `s3cmd` installed).

Be sure to make the script executable (`chmod +x`) before you hit the gas.


## Requirements

* [duplicity](http://duplicity.nongnu.org/)
* Basic utilities like: [which](http://unixhelp.ed.ac.uk/CGI/man-cgi?which) and [tee](http://linux.die.net/man/1/tee) (should already be available on most Linux systems)
* [gpg](http://www.gnupg.org/) *`optional`*
* [Amazon S3](http://aws.amazon.com/s3/) *`optional`*
* [s3cmd](http://s3tools.org/s3cmd) *`optional`*
* [mailx](http://linux.die.net/man/1/mailx) *`optional`*


## Configuration

The configuration takes place in a separate config file and is documented there.

You want to copy `duplicity-backup.conf.example` to another place that suits your needs (for example `/etc/duplicity-backup.conf`)

The script looks for its configuration by reading the config file specified by the command line option `-c` or `--config` (see [Usage](#usage))

If no config file was given on the command line, the script will try to find the file specified in the `CONFIG` parameter at the beginning of the script (default: `duplicity-backup.conf` in the script's directory).

So be sure to either:
* specify the configuration file path on the command line with the -c option **[recommended]**
* or to edit the `CONFIG` parameter in the script to match the actual location of your config file. **[deprecated]**

NOTE: to ease future updates of the script, you may prefer NOT to edit the script at all and to specify systematically the path to your config file on the command line with the `-c` or `--config` option.


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

Note that the commands --restore-file and --restore-dir are equivalent.

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

**See the collection status (i.e. all the backup sets in the remore archive)**

    duplicity-backup.sh [-c config_file] --collection-status

**Verify the backup**

    duplicity-backup.sh [-c config_file] --verify

**Backup the script and gpg key in a encrypted tarfile (for safekeeping)**

    duplicity-backup.sh [-c config_file] --backup-script


## Cron Usage Example

    41 3 * * * cd /path/to/duplicity-backup; ./duplicity-backup.sh -c /etc/duplicity-backup.conf -b


## Troubleshooting

This script attempts to simplify the task of running a duplicity command; if you are having any problems with the script the first step is to determine if the script is generating an incorrect command or if duplicity itself is causing your error.

To see exactly what is happening when you run duplicity-backup, either pass the option `-d` or `--debug` on the command line, or head to the bottom of the configuration file and uncomment the `ECHO=$(which echo)` variable. 

This will stop the script from running and will, instead, output the generated command into your log file. You can then check to see if what is being generated is causing an error or if it is duplicity causing you woe.

You can also try the `-n` or `--dry-run` option. This will make duplicity to calculate what would be done, but does not perform any backend actions. Together with info verbosity level (-v8) duplicity will list all files that will be affected. This way you will know exactly which files will be backed up or restored.


## Wish List

* send mails only on failure
* support for include/exclude filelists


###### Thanks to all the [contributors](https://github.com/zertrin/duplicity-backup/graphs/contributors) for their help.

