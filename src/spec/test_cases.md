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

### **T01** | Main loop - CTRL+C

**Description**: when running CLIMate, the app should exit gracefully and
notify the user that it is exiting when the Ctrl+C key combination is issued.

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
2. Issue the CTRL+C key combination.

**Expected Results**: the application should exit gracefully and display
messages to notify the user, such as the following:

```
Welcome to CLIMate! You can use CTRL+C to exit at any time :)

Determining your timezone...

Your timezone was detected as Australia/Sydney.

Please select a location type: (Press ???/??? arrow to move and Enter to select)
??? Local
  Elsewhere
Thanks for using CLIMate!

Exiting
```

### **T02** | Main loop - determine timezone

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

Please select a location type: (Press ???/??? arrow to move and Enter to select)
??? Local
  Elsewhere
```

**Exceptional Results**: The application should print output similar to the
following if there is no internet connection:

```
Welcome to CLIMate! You can use CTRL+C to exit at any time :)

Determining your timezone...

Oops - there was a connection error. Make sure you're connected to the internet.

CLIMate needs to know your timezone to fetch forecasts.


Thanks for using CLIMate!

Exiting
```

where 'Australia/Sydney` should be substituted with the user's current timezone.

### **T03** | Main loop - place name search

**Description**: when running CLIMate, the app should display a list of all
locations for a valid place name entered by the user.

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
2. When prompted to select a location type, enter either of the 2 alternatives.
4. When prompted to enter a place name, enter a place name that is known to be
valid for a real location.

**Expected Results**: the user should be presented with output similar to the following
(this example uses Brisbane as input):

```
Welcome to CLIMate! You can use CTRL+C to exit at any time :)

Determining your timezone...

Your timezone was detected as Australia/Melbourne.

Please select a location type: Local

Enter a place name for your current location: Brisbane

Searching for 'Brisbane' geocode info...

Please choose the correct location from the following list of alternatives: (Press ???/???/???/??? arrow to move and Enter to select)
??? Brisbane City, Queensland, Australia
  Brisbane, San Mateo County, California, 94005, United States
  Brisbane, Will County, Illinois, 60451, United States
  Brisbane, Erin, Wellington County, Southwestern Ontario, Ontario, N0B 1T0, Canada
  Brisbane, Grant County, North Dakota, United States
  Brisbane, Vista Real Classica, 2nd District, Quezon City, Eastern Manila District, Metro Manila, 1100, Philippines
  ...
```

The user should the location they are searching for in the list of alternatives
(distinguishable from all alternatives by the full location name).

**Exceptional Results**: if the place name entered by the user is not valid
for a real location, output similar to the following can be expected:

```
Welcome to CLIMate! You can use CTRL+C to exit at any time :)

Determining your timezone...

Your timezone was detected as Australia/Sydney.

Please select a location type: Local

Enter a place name for your current location: qwertyuiop

Searching for 'qwertyuiop' geocode info...

Sorry - CLIMate couldn't find location info for 'qwertyuiop'.

Try again? (Y/n) 
```

