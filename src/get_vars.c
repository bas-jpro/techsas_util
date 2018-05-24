/* Show vars in a TechSAS NetCDF file */
/* JPRO 20/05/2018 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <netcdf.h>

// attribute holding units
#define UNITS "units"

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage: %s filename\n", argv[0]);
		exit(-1);
	}

	int ncid = 0;
	
	int retval = 0;
	if (retval = nc_open(argv[1], NC_NOWRITE, &ncid)) {
		fprintf(stderr, "Unable to open [%s] - %d\n", argv[1], retval);
		exit(-1);
	}

	int ndimsp = 0, nvarsp = 0, nattsp = 0, unlimdimidp = 0;	
	if (retval = nc_inq(ncid, &ndimsp, &nvarsp, &nattsp, &unlimdimidp)) {
		fprintf(stderr, "Unable to inquire about [%s] - %d\n", argv[1], retval);
		exit(-1);
	}

	//	fprintf(stdout, "Number of dimensions %d, variables %d, attributes %d, unlimited dimension id %d\n", ndimsp, nvarsp, nattsp, unlimdimidp);

	size_t lenp = 0;
	char name[NC_MAX_NAME+1];

	if (retval = nc_inq_dim(ncid, unlimdimidp, name, &lenp)) {
		fprintf(stderr, "Failed to get unlimited dimension name\n");
		exit(-1);
	}

	// fprintf(stdout, "Unlimited dimension: %s, length: %d\n", name, lenp);

	for (int v=0; v<nvarsp; v++) {
		char varname[NC_MAX_NAME+1];

		if (retval = nc_inq_varname(ncid, v, varname)) {
			fprintf(stderr, "Failed to get name of variable %d\n", v);
			exit(-1);
		}

		fprintf(stdout, "%s", varname);
		
		// Get Units
		size_t attlen = 0;
		if (retval = nc_inq_attlen(ncid, v, UNITS, &attlen)) {
			fprintf(stderr, "Couldn't get units for %s\n", varname);
			exit(-1);
		}

		char *string_attr = (char *)malloc((attlen+1) * sizeof(char));
		memset(string_attr, 0, (attlen+1) * sizeof(char));

		if (retval = nc_get_att_text(ncid, v, UNITS, string_attr)) {
			fprintf(stderr, "Can't get attribute text %d\n", retval);
			exit(-1);
		}
		string_attr[attlen] = '\0';
		
		fprintf(stdout, "\t%s\n", string_attr);
		free(string_attr);
	}
	
	if (retval = nc_close(ncid)) {
		fprintf(stderr, "Unable to close [%s] - %d\n", argv[1], retval);
		exit(-1);
	}

	return 0;
}

