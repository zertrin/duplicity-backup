Between version 0.10.0 and 0.8.3, versionning had been neglected and no CHANGELOG entry was kept up to date.

Here is an export from `git log` for all changes that affected `duplicity-backup.sh` or `duplicity-backup.conf.example` between 2013-01-14 and 2016-08-31.

```
2016-08-31 23:03:09 +0200 - 73adf5d - Fixes related to new warnings coming from the new version of shellcheck
2016-08-31 17:09:28 -0300 - 6ce9a64 - Wrong identation
2016-08-31 16:36:29 -0300 - 4f96d72 - Send notification if stale lock is detected
2016-08-31 15:26:12 -0300 - 465ae13 - Add IFTTT notification service
2016-08-31 15:13:34 -0300 - c9bd2a4 - Add IFTTT notification service
2016-07-13 18:23:27 +0200 - 2f07d0e - Adding -e, --cleanup flag...
2016-07-03 01:07:08 +0200 - 1604d02 - Support mailx from mailutils
2016-06-15 13:38:18 +0200 - 7a84fbd - Fix for issue #128
2016-04-29 15:31:56 +0200 - dcdc081 - changed my mind about where to place NOTIFICATION_SERVICE
2016-04-29 15:27:40 +0200 - b90289d - minor comment changes to notifications
2016-04-28 15:58:49 -0400 - 0501d23 - fixed error
2016-04-28 21:28:54 +0200 - 6dc6d19 - Restore the functionality to specify a custom mail script
2016-04-23 14:15:09 -0400 - 3ffde78 - Adding Pushover notifications
2016-04-06 11:05:19 -0400 - a719668 - added -r flag to bash read to allow backslashes in GPG passphrases
2016-04-01 23:21:19 +0200 - fad4bd2 - Full rework of email handling
2016-03-28 23:47:39 +0200 - f3f4ddc - rework code for email and notifications (more DRY)
2016-03-28 23:21:02 +0200 - 74f637d - Typo
2016-03-25 20:40:46 +0100 - bcd64c1 - first iteration after activation of Travis-CI
2016-03-25 20:00:39 +0100 - 6c63877 - one last cleaning in the conf file with shellcheck
2016-03-25 19:47:29 +0100 - 3797960 - massive cleaning with shellcheck: from 5 errors and 200 warnings to zero
2016-03-24 21:12:17 +0100 - 454d278 - minor changes to the pull request before merging
2016-03-24 20:59:42 +0100 - 471cc9f - minor changes to the pull request before merging
2016-03-16 18:01:49 +0530 - 491b045 - Add storage class option for AWS S3 to specify storage class to be used
2016-02-26 14:56:31 +0800 - 3eabe0d - Add config sample for Slack notifications
2016-02-26 14:54:34 +0800 - fcfa9ac - Add Slack incoming webhook notifications support
2016-02-26 14:44:46 +0800 - 4fca444 - Better comment
2016-01-27 10:50:15 -0500 - ff1e827 - Adding support for custom mail scripts.
2016-01-23 15:12:03 +1100 - 931fe9e - added ftps and ftpes to list of possible destinations
2015-10-19 13:59:34 +0800 - 423a1d3 - Fix typo
2015-10-10 13:31:12 +0200 - 3a48d5a - Fix bug #106 (unary operator expected)
2015-10-08 10:15:56 +0200 - e5d5785 - also send email on cleanup failure + replace introduced tabs with spaces
2015-09-02 10:17:14 +0200 - 8985d9c - - added EMAIL_FAILURE_ONLY option to send e-mails only if there was an error while doing backup - added HOSTNAME option to inform in e-mail report for which server is this report for - e-mail subject is rewrited now to know if backup was OK or not
2015-08-17 14:58:00 -0500 - 689eb23 - add more backslashes to unweildy awk script
2015-07-29 21:56:53 +0200 - 498ac97 - Rework of duplicity-backup.conf.example, no functionality changes
2015-07-29 15:38:48 +0200 - 5bdb816 - Add OpenStack Swift support
2015-07-05 20:08:51 +0200 - 0dfa26a - change mode of script to 755
2015-06-24 13:33:06 +0200 - 0644d76 - Make tar stdin/stdout explicit in backup function
2015-05-21 09:09:10 +0200 - 19951b7 - Fix issue #94
2015-05-18 18:40:23 +0200 - a69eeaa - Delete trailing spaces
2015-05-18 18:17:34 +0200 - 4be3671 - Fix bug #93 : make message about unsupported destination disk usage more explicit
2015-05-14 16:17:20 +0200 - 2be958e - Human readable size for Google Cloud
2015-05-14 16:16:56 +0200 - 01143b6 - Size GCS with gsutil
2015-05-14 14:16:59 +0200 - 8abfd40 - Google Cloud Storage support
2015-04-20 13:33:44 -0400 - 528cc41 - Move --exclude-device-files to beginning of EXCLUDE variable
2015-04-17 08:54:36 -0500 - c8d249d - removed perl dependancy
2015-04-13 17:13:08 -0500 - 20ded18 - Appending usage information to EMAIL_SUBJECT 	modified:   duplicity-backup.sh
2015-04-10 15:26:28 -0500 - a749d24 - Add support for getting size of remote disk connected via ssh
2015-01-27 15:23:11 +0000 - e94732a - Add destination type to disk use report and make format consistent with source du report
2015-01-27 13:13:18 +0000 - 08cb675 - improve s3cmd not installed message, ie mention PATH
2015-01-26 19:20:44 +0000 - 3fcfb22 - add s3cmd config not found to dest disk use report
2015-01-23 19:12:57 +0000 - 92a3932 - unset ftp_password variable
2015-01-23 17:02:25 +0000 - 258e68c - copy whole array rather than one element
2015-01-23 16:25:51 +0000 - ea14212 - remove not on -z INCLIST check
2015-01-21 16:29:42 +0100 - 2e6e383 - Rework on the pull request to refactor the new code
2015-01-21 15:59:42 +0100 - b34c7a5 - Include the include/exclude globbing file in the backup tarball if present
2015-01-19 20:13:52 +0000 - 6f5b0dc - My typo in code comment - du not df
2015-01-19 19:08:23 +0000 - 01ec946 - Correct log reports of file size to disk use, plus some log file formatting cleanups
2015-01-19 18:36:11 +0000 - 646f8c4 - Excluded directories were no excluded from source disk usage report - quotes issue
2015-01-19 17:17:56 +0000 - 6ccf691 - Don't skip source disk use report when INCLIST unconfigured
2015-01-18 18:01:32 +0000 - bdcb1bf - Update example config with log dir creation info
2015-01-18 14:50:35 +0000 - d3c2102 - If we create the log dir chown it to log file owner
2014-12-05 09:39:05 +1100 - 59f2339 - add an option to set the tmpdir for duplicity to use.
2014-12-05 09:30:05 +1100 - 83b7ecd - doing a collection status and file list need to eval the command (like all the other commands already do) because if you have ssh options set in your config, it causes an error ("duplicity: error: no such option: -o")
2014-08-10 03:08:38 +0200 - 7b20db3 - fix: ensure a trailing slash in log dir name
2014-06-06 12:11:58 +0300 - 456f5cd - Add a note in configuration about escaping "$" in passphrase
2014-06-06 12:09:04 +0300 - 615a988 - Add Google Docs destination to configuration
2014-06-06 12:03:18 +0300 - a148ac8 - Fix typos, remove trailing whitespace
2014-04-16 15:05:23 +0200 - 1bde60d - Add REMOVE_LOGS_OLDER_THAN parameter to the config file
2014-03-30 14:44:31 -0400 - 9f5626b - Add option to remove old log files.
2014-03-30 14:44:17 -0400 - 36f87c7 - Only change log file ownership if necessary.
2014-03-30 14:43:53 -0400 - b20f7ab - Clarification when remote size unavailable.
2014-03-04 12:22:14 +0100 - 4f90cc7 - add support for DragonFly and OpenBSD
2014-02-05 16:59:34 +0100 - 3bfd78c - duplicity-backup.sh: Fix quotation issue
2014-01-06 17:24:51 -0500 - 2209955 - dont include --sign-key when restoring w/ hidden-enc key
2014-01-03 16:25:26 -0500 - 417d526 - only cleanup if CLEAN_UP_TYPE and CLEAN_UP_VARIABLE are defined
2014-01-03 15:26:26 -0500 - 1864e3a - added HIDE_KEY_ID and SECRET_KEYRING options
2014-01-02 16:16:23 +0200 - 07c1fd2 - Added the option to skip cleanup
2013-11-22 10:32:19 +0100 - 1bd7c26 - Fixes issue zertrin/duplicity-backup/issues/41 - conf revert
2013-11-22 10:29:07 +0100 - 7d83629 - Fixes issue zertrin/duplicity-backup/issues/41
2013-11-13 21:56:12 +0100 - 54f9aaf - Complete the half-done work of previous commit
2013-11-13 21:36:34 +0100 - 03ef054 - Add the --restore-dir synonym and update the documentation accordingly
2013-11-13 20:08:34 +0100 - e9af0ab - Some little modifications and additions in the doc of the config file
2013-11-13 19:55:47 +0100 - dd05ff6 - Add support for mail sending via msmtp
2013-11-13 19:36:15 +0100 - 5c99b4c - fixed variable name (cherry picked from commit 19c80a83a2819bdac73dfe4bc08e270205a9a666)
2013-11-11 00:06:31 +0000 - 22e3904 - Renamed the --dry-run option to --debug.Created proper duplicity --dry-run command (recommended -v8, info verbosity level)
2013-08-12 11:06:09 +0200 - c3aa58b - Small improvements to the fix of cippino before merge
2013-08-02 10:52:08 +0200 - 0275cb5 - Fixed INCLIST
2013-07-22 11:59:41 +0200 - dbf78cf - Better explanation of the FTP_PASSWORD variable based on official documentation
2013-07-22 10:20:29 +0200 - 63d38be - Add notes about the difference between "mailx" and "mail" commands
2013-07-22 10:11:31 +0200 - 68931e4 - Move the new section about remove-all-inc-of-but-n-full a bit lower in the config file.
2013-07-21 19:58:46 -0500 - 9b34c04 - Adds the option to use remove-all-inc-of-but-n-full to prune incrementals of backups with long history.
2013-07-09 11:52:03 -0300 - 582416f - A small contribution with a set a ftp variable to run on a script
2013-07-07 19:03:42 +0200 - 7275aaf - sendmail error
2013-07-03 09:21:20 +0200 - 31da9c8 - Sendmail as mail command
2013-05-14 22:12:27 -0500 - e636dd4 - Fix typos.
2013-03-31 01:24:26 +0100 - 89a78ed - Be a bit more specific about configuration problems
2013-03-31 01:21:43 +0100 - 7bb45ff - Let s3cmd have the correct bucket name when using s3 scheme
2013-03-23 00:14:23 +0100 - ee1b759 - Fix issue #38 : Multiple recipients
2013-01-29 14:32:05 +0100 - bc0fa15 - Fix for du --exclude-from and mail on OS X
2013-01-14 21:25:36 +0100 - 02fae5c - Update duplicity-backup.sh
2013-01-14 01:04:56 +0100 - 6df0902 - Fix issue #33 : Allow to specify the s3cmd configuration file
```
