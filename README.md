# Linux Scoring Engine

This is a ScoringEngine used to create and score Linux Practice Rounds.
When creating a round, please copy all of the files in the 'ScoreEngine' folder to the same directory in the virtual machine. The default location the program expects is `/opt/ScoreEngine` (this is set with the `SEDIRECTORY` variable in `ScoringEngine.sh`). This README will use `/opt/ScoreEngine/` as the `SEDIREDCTORY`.

### Dependencies
These can be installed through your package manager (e.g. `apt-get`, `yum`)
- `sox`, `libsox-fmt-all`
- `notify-osd` (if on Debian-based system)
- `libnotify` (if on RedHat-based system)
- `dos2unix` (for converting script if written on Windows)
- `shc` (generic shell compiler)
    - [You can download shc from its GitHub page if your package manager cannot find it](https://github.com/neurobin/shc)

### The `master_se_functions.sh` file
When writing your code, sourcing `master_se_functions.sh` will (hopefully) make the image creation easier.
- `master_se_functions.sh` should try to automagically detect which type of operating system (e.g., Debian, Red Hat) you are using
    - This is still a work in progress, bugs are to be expected (please let me know if you find any!)
    - May not work with some distributions of Linux because of the way the script determines the system type (it looks at `/proc/version`)

### Custom scoring functions
The `master_se_functions.sh` file contains many functions pre-coded; if you want custom functions, you have 2 choices:

1. Put the functions in `master_se_functions.sh` (Note: you'll need to update the SHA512 hash in the `ScoringEngine.sh` file to make sure it passes the integrity check)
2. Put the functions in `ScoringEngine.sh` (This is easier, in my opinion)

### Compiling the Scoring Engine
This section is for if you want to protect/hide the contents of the `ScoringEngine.sh` (e.g. you don't want competitors being able to look at the answers [after all, they are written in plain text...])

0. `dos2unix` all of the `.sh` files you modified (e.g., `master_se_functions.sh` ; `ScoringEngine.sh`)
    - You MUST do this if you wrote the script on Windows and did not convert to Unix format (do this if you are unsure of what this means)
1. Download and install the `shc` package
2. Compile the `ScoringEngine.sh` file using `shc -Urf ScoringEngine.sh` (NOTE: The -U option may not always be available). You can also use other options the `shc` command offers
3. This will generate two files: `ScoringEngine.sh.x`, and `ScoringEngine.sh.x.c`. If you did not use the `-U` option, remove the `ScoringEngine.sh.x` file, as its code execution can be caught/traced more simply than if you compiled the `ScoringEngine.sh.x.c`
    - The `ScoringEngine.sh.x` file is an executable binary of the script
    - The `ScoringEngine.sh.x.c` file is C code generated from the script. It's not very human-readable. **KEEP THIS FILE!!!**
4. To ensure that the code is more hidden, compile `ScoringEngine.sh.x.c` using `gcc` or other C compiler.
    - The command may look something like this (Note: you might need root permissions to write into the `/opt` directory (and its subdirectories):

    ```
    # gcc /opt/ScoreEngine/ScoringEngine.sh.x.c -o /opt/ScoreEngine/ScoringEngine
    ```
5. Remove the following files if they exist in tge directory where your Scoring Engine is stored (***only do this if you are ABSOLUTELY sure that you a) are satisfied with your code or b) have a backup to edit in case something goes wrong, I recommend keeping these files until you are done testing your script***)
    - `ScoringEngine.sh`
    - `ScoringEngine.sh~` (this is a backup created by your system)
    - `ScoringEngine.sh.x` (you can ignore this if you use the `-U` option, for Untraceable.)
6. Keeping the `ScoringEngine.sh.x.c` file will allow the Scoring Engine to be recompiled in the event that it is either corrupted or deleted.
7. Make a file in `/usr/local/bin/` called `score` with the following contents:

    ```bash
    #!/bin/bash
    if [[ $USER != "root" ]]; then
       echo "You must be root to run this script!"
       exit 1
    fi

    /bin/rm /opt/ScoreEngine/ScoringEngine
    /usr/bin/gcc /opt/ScoreEngine/ScoringEngine.sh.x.c -o /opt/ScoreEngine/ScoringEngine
    /opt/ScoreEngine/ScoringEngine 2> /dev/null
    if [[ $? -ne 0 ]]; then
           echo "Something went wrong..."
           exit 1
    else
           echo "Your score has been updated"
           exit 0
    fi
    ```

8. ***OPTIONAL:*** Make a file in `/etc/sudoers.d/` called `ScoringEngine` with the following contents:

    ```
    ALL ALL=NOPASSWD: /usr/local/bin/score
    ```

    Save the file. Then run `# chmod 755 /usr/local/bin/score`. If you have coded everything right, then your competitors should be able to update their score using `sudo score` in the terminal without password. ***This step is necessary if you want to use the `.desktop` files (in Resources folder).***
9. Make the critical files immutable. This prevents them from being deleted.
 To do so, please use the following command:
 ```bash
 # chattr +i <filename>
 ```
 The files that will need this are:
 ```
 /opt/ScoreEngine/ScoringEngine.sh.x.c
 /opt/ScoreEngine/master_se_functions.sh
 /etc/sudoers.d/ScoringEngine
 /usr/local/bin/score
 ```

### The `.desktop` files
These files are found in the "resources" folder. (See the exampleSE)
#### Usage
1. The files are to be placed on the Desktop folder of the user specified in the `ACCOUNT` variable in the `ScoringEngine.sh` (the same place you would put Forensics Questions).
    - Note: you might need to allow desktop icons. Configure this using the tweak tool for your disaplay manager.
2. Make sure the `.desktop` file points to the correct place (the `SEDIRECTORY`)
    - You'll need to create a ReadMe in the `SEDIRECTORY` to use CyberPatriotReadme.desktop (below, pay attention to the `SEDIRECTORY`)
    ```
    [Desktop Entry]
    Name=README
    Type=Application
    Exec=x-www-browser "file:///opt/ScoreEngine/ReadMe.html"
    Icon=/opt/ScoreEngine/tux.png
    StartupNotify=true
    ```
3. Change the properties of the file (right click on the `.desktop file`, "Properties" on the context menu) so that it is allowed to execute as a program (might be under "Permissions" tab).
4. Double click on it to make sure it works. You might need to mark it as "trusted" (the system should give you a prompt).

### Miscellaneous
#### Editors
- [Atom](https://atom.io) (cross-platform)
  - To edit Markdown (`.md`) files:
    - Use Atom's `gfm-pdf` package to turn render Markdown into HTML (such as the ReadMe). Note: requires [wkhtmltopdf](https://wkhtmltopdf.org/)
    - If you are using Windows, you will need to configure `gfm-pdf` to look at `"C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"` and also to output as an HTML file (as opposed to a PDF)
- [Notepad++](https://notepad-plus-plus.org/) (Windows only)
- Microsoft Word (Windows only, price varies) to make and edit the ReadMe. Alternatives include [LibreOffice](https://www.libreoffice.org/) (cross-platform, free, open-source) and [Apache OpenOffice](https://www.openoffice.org/) (cross-platform, free, open-source). Make sure to export it as ReadMe.html and put it into `SEDIRECTORY` including any folders the export creates.

#### Getting the files onto the image
- [WinSCP](https://winscp.net/eng/index.php) - A graphical SCP for Windows. Easy to use.
- SCP (native if using Linux OR Bash on Ubuntu/Fedora/openSUSE on Windows -- the latter requires Windows 10 Creators Update)

#### Contact
kedwinchen.public@gmail.com, please put "Linux-ScoringEngine" in the subject line
