# Test Cases For CLIMate

## Global Preconditions

1. The user must have a device with a Unix derived operating system
that supports the Bash shell installed.
2. The user must have Ruby installed on their device.
3. The user must have Internet access so that all application dependencies
can be installed, and the application can be used.

## Suite 1: setup.sh & main.rb

### **T01** | App Configuration - Create configuration directory and files

**Description**: after running `setup.sh`, the configuration directory
and all it's files should be created.

**Preconditions**:

1. The configuration directory for the application (`~/.CLIMate`) must not
already exist. This can be ensured by issuing the following command:

```
rm -r ~/.CLIMate
```

**Test Steps**:

1. Clone the application's repository to a suitable device (one that meets
preconditions 1-3).
2. Once cloned, navigate to the root directory of the repository.
3. Execute `setup.sh` by issuing the following command:
```
./setup.sh
```
4. Enter 'n' for all questions prompted by the script.
5. When the script's execution is complete. Navigate to the current user's
home directory using the command line and list its contents using `ls -a`.
6. List the contents of the `.CLIMate` directory using `ls .CLIMate`.*

*Note that step 6 depends on the output of `ls -a` - see step 5.

**Expected Result**: a directory called `.CLIMate` should be listed in the 
the output of `ls -a`. If this is the case, after step 6 is complete the 
following 4 files should appear in the output of `ls .CLIMate`:

- `config.json`
- `favourites.json`
- `history.json`
- `locations.json`

### **T02** | App Configuration - Choose exports directory

**Description**: when running `setup.sh`, the user should be able
to configure their desired PDF exports directory for the app.

**Test Steps**:

1. Clone the application's repository to a suitable device (one that meets
preconditions 1-3).
2. Once cloned, navigate to the root directory of the repository.
3. Execute `setup.sh` by issuing the following command:
```
./setup.sh
```
4. Enter 'y' when the script asks if you would like to change the default
exports directory.
5. Enter the full path for a directory other than `~/Documents/CLIMate`.
6. Answer 'n' when asked if you would like to launch the application.
7. Issue the following command:
```
./start.sh --config list
```

**Expected Result**: output similar to the following should appear in the 
console:

```
Current CLIMate configuration:

output------------------------> <directory>
```

Where `<directory>` will be the full path entered during step 5.

### **T03** | App Configuration - Launch App Without Configuration Errors

**Description**: by running `setup.sh`, the user should be able to 
run the application without configuration errors.

**Test Steps**:

1. Clone the application's repository to a suitable device (one that meets
preconditions 1-3).
2. Once cloned, navigate to the root directory of the repository.
3. Execute `setup.sh` by issuing the following command:
```
./setup.sh
```
4. Answer 'n' to the first question.
5. Answer 'y' to the second question.

**Expected Result**: If the application does not output something similar to
the following:

```
Oops! There were some configuration errors:

CONFIG ERROR: /home/username/.CLIMate/config.json: file missing

CONFIG ERROR: /home/username/.CLIMate/locations.json: file missing

CONFIG ERROR: /home/username/.CLIMate/favourites.json: file missing

CONFIG ERROR: /home/username/.CLIMate/history.json: file missing

Please run the setup script to sort things out!
```

with 1 or more `CONFIG ERROR` messages, the test has succeeded.

## Suite 2: app.rb

### T01 | Main loop - determine timezone

**Description**: when running CLIMate, the app should correctly determine the 
timezone of the user and notify the user.

**Preconditions**:

1. The application's repository must be cloned to the user's device.
2. The user must have already executed `setup.sh` successfully.
3. The user's current working directory must be the root directory
of the repository.

**Test Steps**:

1. Launch the application by issuing one of the following commands:
```
./start.sh

# or

ruby src/main.rb
```

**Expected Results**: the application should print output similar to the 
following:

```
Welcome to CLIMate! You can use CTRL+C to exit at any time :)

Determining your timezone...

Your timezone was detected as Australia/Sydney.

Please select a location type: (Press ↑/↓ arrow to move and Enter to select)
‣ Local
  Elsewhere
```

where 'Australia/Sydney` should be substituted with the user's current timezone.