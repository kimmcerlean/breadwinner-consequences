* This is an example setup file. You should create your own setup file named
* setup_username.do that replaces the directories for project code, log files,
* etc to the location for these files on your computer

global homedir "T:"

* STANDARD PROJECT MACROS-------------------------------------------------------
global projcode 		"$homedir/github/breadwinner-consequences"
global logdir 			"$homedir/Research Projects/Breadwinner - consequences/logs"
global tempdir 			"$homedir/Research Projects/Breadwinner - consequences/data"
global SIPP14keep 		"$homedir/Research Projects/Breadwinner - consequences/data"
global combined_data 	"$homedir/Research Projects/Breadwinner - consequences/data"

// Where you want produced tables, html or putdoc output files to go (NOT SHARED)
global results 		    "$homedir/Research Projects/Breadwinner - consequences/results"

// Input data: SIPP 2014
global SIPP2014 		"/data/sipp/2014"
