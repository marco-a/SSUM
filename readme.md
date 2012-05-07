# what is SSUM?
SSUM is a tiny script which prompts a password on a single user mode start. 
this is useful when you want to avoid unauthorized access on your mac. 

> information: this script does not prevent a boot from a disk, it only secures single user mode with a user defined password!

## requirements
you'll need root access, mac osx 10.6+ and the curl extension installed. 

## install SSUM
first, log into your root account:

```bash
$ login root
```
then, download the latest SSUM setup.

```bash
$ rm -f install.sh && curl -so install.sh https://raw.github.com/marco-a/SSUM/master/install.sh
````
set chmod and run the setup.

```bash
$ chmod +x install.sh && ./install.sh
````

then just follow the instructions on the setup. and you're done.