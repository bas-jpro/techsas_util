/* Get data for a given time in a TechSAS NetCDF file */
/* JPRO 20/05/2018 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netcdf.h>
#include <udunits2.h>
#include <math.h>

int open_techsas_file(char *, int *, int *, char **, int *, size_t *);
cv_converter *setup_converter(ut_system *, char *, char *);
size_t search_time(double, double *, int, int, size_t, size_t);
void print_int(int, int, size_t);
void print_double(int, int, size_t);
void print_string(int, int, size_t);

#define UNITS          "units"
#define UNIXTIME_UNITS "seconds since 1970-01-01T00:00:00Z" 
#define MAXDIFF        5L // maximum difference for found timestamp

int main(int argc, char *argv[]) {
	if (argc < 3) {
		fprintf(stderr, "Usage: %s filename tstamp [maxdiff]\n", argv[0]);
		exit(-1);
	}
	
	long tstamp = atol(argv[2]);

	// Use default difference or user supplied
	long maxdiff = MAXDIFF;
	if (argc == 4) {
		maxdiff = atol(argv[3]);
	}
		
	// Open NETCDF file, and get units
	int ncid = -1;
	char *time_units = (char *) NULL;
	int time_var = -1;
	int nvars = -1;
	size_t time_len = -1;

	if (open_techsas_file(argv[1], &ncid, &nvars, &time_units, &time_var, &time_len) < 0) {
		fprintf(stderr, "Unable top open %s\n", argv[1]);
		exit(-1);
	}
	
	// Convert tpos to techsas time to search 
	ut_system *unitSystem = (ut_system *) NULL;
	cv_converter *unix_to_techsas = setup_converter(unitSystem, UNIXTIME_UNITS, time_units);
	if (unix_to_techsas == (cv_converter *) NULL) {
		fprintf(stderr, "Failed to create converter\n");
		exit(-1);
	}
	
	double techsas_tstamp = cv_convert_double(unix_to_techsas, (double)tstamp);

	// Binary search netcdf file for closest time to techsas_tstamp
	double found_tstamp = -1;
	size_t index = search_time(techsas_tstamp, &found_tstamp, ncid, time_var, 0, time_len-1);
	if (index < 0) {
		fprintf(stderr, "Failed to find time\n");
		exit(-1);
	}

	cv_converter *techsas_to_unix = setup_converter(unitSystem, time_units, UNIXTIME_UNITS);
	if (techsas_to_unix == (cv_converter *) NULL) {
		fprintf(stderr, "Failed to create converter\n");
		exit(-1);
	}
	
	long found_unix_tstamp = (long)cv_convert_double(techsas_to_unix, found_tstamp);
	
	if (abs(found_unix_tstamp - tstamp) > maxdiff) {
		fprintf(stderr, "Couldn't find close enough timestamp, diff was - %ld\n", abs(found_unix_tstamp - tstamp));
		exit(-1);
	}

	// Get values of each variable at the index found
	for (int v=0; v<nvars; v++) {
		nc_type var_type;
		if (nc_inq_var(ncid, v, (char *) NULL, &var_type, (int *) NULL, (int *) NULL, (int *) NULL)) {
			fprintf(stderr, "Couldn't get type of variable %d\n", v);
			exit(-1);
		}

		switch(var_type) {
		case NC_BYTE:
		case NC_SHORT:
		case NC_INT:
			print_int(ncid, v, index);
			break;
		case NC_FLOAT:
		case NC_DOUBLE:
			print_double(ncid, v, index);
			break;
		case NC_STRING:
			print_string(ncid, v, index);
			break;
		default:
			fprintf(stdout, "Variable %d - type %d\n", v, var_type);
		}
	}
			
	free(unix_to_techsas);
	free(techsas_to_unix);
	ut_free_system(unitSystem);
	free(time_units);

	if (nc_close(ncid)) {
		fprintf(stderr, "Failed to close file\n");
		exit(-1);
	}
	
	return 0;
}

void print_string(int ncid, int var, size_t index) {
	return;
}

void print_double(int ncid, int var, size_t index) {
	double val = 0;

	if (nc_get_var1_double(ncid, var, &index, &val)) {
		fprintf(stdout, "Failed to get value of variable %d\n", var);
		return;
	}

	fprintf(stdout, "%0.8f\n", val);
}

void print_int(int ncid, int var, size_t index) {
	int val = 0;
	if (nc_get_var1_int(ncid, var, &index, &val)) {
		fprintf(stdout, "Failed to get value of variable %d\n", var);
		return;
	}

	fprintf(stdout, "%d\n", val);
}
			   
// Binary search to find nearest pos to tstamp
size_t search_time(double tstamp, double *found_tstamp, int ncid, int time_var, size_t low, size_t high) {
	size_t mid = 0;
	double time_val = 0;
	
	while ((high - low) > 1) {
		//fprintf(stderr, "Searching between %d and %d\n", low, high);
		mid = (high + low) / 2;
		
		if (nc_get_var1_double(ncid, time_var, &mid, &time_val)) {
			// Couldn't read variable
			return -1;
		}

		//fprintf(stderr, "Pos %d, val %0.8f, target %0.8f\n", mid, time_val, tstamp);

		if (time_val < tstamp) {
			low = mid;
		} else {
			high = mid;
		}
	}

	// Find closest value
	double high_val = 0, low_val = 0;
	if (nc_get_var1_double(ncid, time_var, &high, &high_val)) {
		return -1; 
	}
	
	if (nc_get_var1_double(ncid, time_var, &low, &low_val)) {
	return -1;
	}

	if (fabs(high_val - tstamp) > fabs(tstamp - low_val)) {
		*found_tstamp = low_val;	
		return low;
	}

	*found_tstamp = high_val;
	return high;
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

int open_techsas_file(char *filename, int *ncid, int *nvars, char **time_units, int *time_var, size_t *time_len) {	
	int retval = 0;
	if (retval = nc_open(filename, NC_NOWRITE, ncid)) {
		fprintf(stderr, "Unable to open [%s] - %d\n", filename, retval);
		return -1;
	}

	int ndimsp = 0, nattsp = 0, unlimdimidp = 0;	
	if (retval = nc_inq(*ncid, &ndimsp, nvars, &nattsp, &unlimdimidp)) {
		fprintf(stderr, "Unable to inquire about [%s] - %d\n", filename, retval);
		return -1;
	}

	char name[NC_MAX_NAME+1];
	if (retval = nc_inq_dim(*ncid, unlimdimidp, name, time_len)) {
		fprintf(stderr, "Failed to get unlimited dimension name\n");
		return -1;
	}

	// Get time variable - assuming it's unlimited dimension name
	if (retval = nc_inq_varid(*ncid, name, time_var)) {
		fprintf(stderr, "Failed to get time variable\n");
		return -1;
	}

	// Get Units
	size_t attlen = 0;
	if (retval = nc_inq_attlen(*ncid, *time_var, UNITS, &attlen)) {
		fprintf(stderr, "Couldn't get units for %s\n", name);
		return -1;
	}
	
	char *units = (char *)malloc((attlen+1) * sizeof(char));
	memset(units, 0, (attlen+1) * sizeof(char));
	
	if (retval = nc_get_att_text(*ncid, *time_var, UNITS, units)) {
		fprintf(stderr, "Can't get attribute text %d\n", retval);
		return -1;
	}
	units[attlen] = '\0';

	*time_units = units;
	
	return 0;
}
