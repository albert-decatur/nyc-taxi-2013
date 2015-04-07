#!/bin/bash

# make a single table from NYC 2013 FOIL taxi data
# make an ID field using medallion,hack_license,pickup_datetime
# this is sha1sum without no field separators between these fields
# assumes you've downloaded the zips first
# NB: assumes the field positions in the dataset **and** that no commas appear as anything other than field delimiters! totally brittle
# user args: 1) url txt file, one URL per line
# example use: $0 urls.txt 

# download each csv in the urls list
function download_each {
	# download zips
	wget -ci $1
}

# unzip each zip, rm it
function unzip_each {
	# unzip
	for i in *.zip
	do
		# unzip the file
		unzip $i
		# now that it's unzipped, remove the zip
		rm $i
	done
}

# get the header of either fare or trip csv, prepending trip_ID field
function get_header {
	cat $1 |\
	head -n 1 |\
	# no whitespace allowed in header
	sed 's:\s::g' |\
	# tack ID column name onto beginning
	sed 's:^:trip_ID,:g'
}

# get header for a given example of a csv by type, eg fare or trip
function specific_header {
	example=$( find . -type f -iregex ".*${1}_data_0[.]csv$" )
	# only bother if a file is found
	if [[ -n $( echo $example | grep -vE "^$" ) ]]; then
		get_header $example
	fi
}

# for each csv of a given type - fare or trip - rm header, prepend trip_ID field (as medallion,hack_license,pickup_datetime sha1sum)
# write to new file
# and clean up tmp csv
function mk_sha1sum_id {
	# for each csv add ID field based on SHA1SUM
	for i in ${1}*.csv
	do 
		cat $i |\
		# ignore existing header
		sed '1d' |\
		# for each combination of medallion,hack_license,pickup_datetime make a sha1sum id
		# we choose these fields b/c they are available in both trip and fare csvs
		# NB: this only works because we want three columns in each case
		# would be more flexible to allow any number of fields in any order
		mawk -F, -v a=$2 -v b=$3 -v c=$4 '
			{
				OFS=",";\
				cmd="echo "$a$b$c" |\
				sha1sum |\
				grep -oE \"[^-]+\" |\
				sed \"s:\s*$::g\"";\
				while ( (cmd | getline sha1sum) > 0);\
				print sha1sum,$0;\
				close (cmd)
			}
		' > $5
	## clean up csvs
	# rm $i
	done
}

#download_each $1
#unzip_each


# for trip csvs, use fields 1,2, and 6 as your medallion,hack_license,pickup_datetime
mk_sha1sum_id trip 1 2 6 ../output/trip.csv
# same as for trip csvs, but use different field numbers for the same fields
mk_sha1sum_id fare 1 2 4 ../output/fare.csv
