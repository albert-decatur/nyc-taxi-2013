#!/bin/bash

# make an ID field using medallion,hack_license,pickup_datetime
# this is sha1sum without no field separators between these fields
# assumes you've downloaded the zips first
# NB: assumes the field positions in the dataset! totally brittle
# user args: 1) input url list for zips

# download each zip
wget -ci $1

# unzip each zip
for i in *.zip
do
	unzip $i
	rm $i
done

# for each trip_data csv, grab header, put aside, add ID field based on SHA1SUM, put header back on, write to original file
for trip_data in trip_data_*.csv
do 
	header=$( 
		cat $trip_data |\
		head -n 1 |\
		# no whitespace
		sed 's:\s*::g' |\
		# add ID field name
		sed 's:^:trip_ID,:g'
	)
	cat $trip_data |\
	sed '1d' |\
	mawk -F, '{OFS=",";cmd="echo "$1$2$6" |\
	sha1sum - |\
	grep -oE \"[^-]+\" |\
	sed \"s:\s*$::g\""; cmd |\
	getline sha1sum; print sha1sum,$0}' |\
	sed "1 i${header}" |\
	sponge $trip_data
done

# same again for fares but these same data are found in different fields
# yes these should be a function but mawk -v would not help me out due to var expansion in bash!
for trip_fare in trip_fare_*.csv
do 
	header=$( 
		cat $trip_fare |\
		head -n 1 |\
		# no whitespace
		sed 's:\s*::g' |\
		# add ID field name
		sed 's:^:trip_ID,:g'
	)
	cat $trip_fare |\
	sed '1d' |\
	mawk -F, '{OFS=",";cmd="echo "$1$2$4" |\
	sha1sum - |\
	grep -oE \"[^-]+\" |\
	sed \"s:\s*$::g\""; cmd |\
	getline sha1sum; print sha1sum,$0}' |\
	sed "1 i${header}" |\
	sponge $trip_fare
done
