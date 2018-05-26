/* Convert time from techsas to date */
/* JPRO 20/05/2018 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <udunits2.h>

#define UNIXTIME_UNITS "seconds since 1970-01-01T00:00:00Z" 
#define TECHSAS_UNITS  "days since 1899-12-30 00:00:00 UTC"

cv_converter *setup_converter(ut_system *, char *, char *);

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage: %s tstamp\n", argv[0]);
		exit(-1);
	}
	
	double tstamp = strtod(argv[1], (char **) NULL);

	// Convert techsas time to unix 
	ut_system *unitSystem = (ut_system *) NULL;
	cv_converter *techsas_to_unix = setup_converter(unitSystem, TECHSAS_UNITS, UNIXTIME_UNITS);
	if (techsas_to_unix == (cv_converter *) NULL) {
		fprintf(stderr, "Failed to create converter\n");
		exit(-1);
	}
	
	long unix_tstamp = (long)cv_convert_double(techsas_to_unix, tstamp);

	fprintf(stdout, "Techsas: %0.8f, Unix timestamp: %ld\n", tstamp, unix_tstamp);
	
	return 0;
}

cv_converter *setup_converter(ut_system *unitSystem, char *from_str, char *to_str) {
	// Suppress errors
	ut_set_error_message_handler(ut_ignore);

	// Create a unit system unless we have one
	if (unitSystem == (ut_system *) NULL) {
		unitSystem = ut_read_xml((const char *)NULL);

		if (unitSystem == (ut_system *) NULL) {
			return (cv_converter *) NULL;
		}
	}
	
	ut_unit *from = ut_parse(unitSystem, from_str, UT_ASCII);
	if (from == (ut_unit *) NULL) {
		return (cv_converter *) NULL;
	}

	ut_unit *to = ut_parse(unitSystem, to_str, UT_ASCII);
	if (to == (ut_unit *) NULL) {
		return (cv_converter *) NULL;
	}

	cv_converter *conv = ut_get_converter(from, to);
	if (conv == (cv_converter *) NULL) {
		return (cv_converter *) NULL;
	}

	return conv;
}
