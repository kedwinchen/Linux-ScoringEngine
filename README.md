# Linux Scoring Engine

### Objective
The Linux Scoring Engine (hereafter: the "Software") was created and is distributed in an effort to create a framework to more easily score how secure a Linux-based operating system (such as GNU/Linux distributions) is based on a set of rules determined by the user of the Software.

### Usage
The Software was implemented using the Bash scripting language for use on [most] Linux-based operating systems.  
Using the modules/pre-made functions in the `master_se_functions.sh` file, the user can define the condition for a successful patch/fix of a vulnerability in `ScoringEngine.sh`.  
The `ScoringEngine.sh` script, when run, should test the system according to the user-defined rules.   
This software is recommended to be deployed in a virtual environment. There is no optimization for deployment on physical or virtual hardware.  
***Please reference the `GETTING_STARTED.md` file for more detailed information.***

### Operating System Compatibility
##### GNU/Linux (tested)
- Debian-like
    - Debian
    - Ubuntu
    - Linux Mint
- Red Hat/Fedora-like
    - RHEL (Red Hat Enterprise Linux)
    - Fedora
    - CentOS (Community ENTerprise Operating System)  

##### BSD
- Unknown; untested

### Use of other works:
The Software relies on at least two other pieces of Free and Open Source Software (FOSS) that are the intellectual property of others.  
The Software uses these works by default to provide extra, but optional functionality.
The works are as follows:
- Classification Banner
    - GitHub link: https://github.com/fcaviggia/classification-banner
    - This FOSS provides the ability for the end user to quickly see how many user-defined vulnerabilities have already been patched in a banner at the top of the screen
- `shc` Shell Script Compiler
    - GitHub link: https://github.com/neurobin/shc
    - This FOSS provides the ability to "encrypt" or otherwise obfuscate the source code so that the criteria for patching a user-defined vulnerability is hidden from the end user
