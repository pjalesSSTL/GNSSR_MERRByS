# MERRByS Data Processing (Matlab)

This repository contains some example files for the processing of the GNSS-Reflectometry (GNSS-R) data from www.merbys.co.uk.

Surrey Satellite Technology Ltd provides these functions under a permissive MIT license to make it easier for people to get started with this data source.

## Conventions

Data is segmented into 6 hour sections. When inputting start and stop times, these should use the boundary times of 03:00, 09:00, 15:00, 21:00.

## Downloading data

The functions expect that the data is available locally using the same directory structure as that used on the MERRByS FTP server. All the data could be downloaded, but a download script (`downloadData.m`) is provided to make it easier to select a subset.

For example the following will download 24 hours of data

e.g. `downloadData('20170217T21:00:00', '20170218T21:00:00', {'L1B', 'L2_FDI'}, 'c:\merrbysData\');`

​	This will download L1b and L2 in the time range specified into the c:\merrbysData folder.

## Inspecting the NetCDF data

The function `inspectNetCDF.m` can be run to inspect the NetCDF data and list out the structure of each of the Level 1B files.

## Running the Level 1B example:

This example displays a 2D histogram of parameters in the Level 1B Delay Doppler Maps. This is run through, `testMERRBySLevel1bBasic.m`.

1. Download data from [ftp://www.merrbys.co.uk](ftp://www.merrbys.co.uk) (include the whole folder structure. e.g. `\L1B\2017-04\21\H18\*`)
2. Load Matlab and inspect `testMERRBySLevel1bBasic.m`
   1. Look through and customise settings such as time range to process
   2. Change the base path to match where the data was downloaded: e.g. `basePath = 'Q:/merrbysData/';`
3. Run the script and a 2D histogram plot should be generated.

Further processing tasks can be added by using `ProcessingTaskHistogramExample.m` as a template.

## Running the Level 2 example:

Level 2 is the Fast Delivery Inversion (FDI) windspeed output.

The function, `displayL2FDI.m` will display this data on a map.

e.g. `displayL2FDI('20170217T21:00:00', '20170218T21:00:00', 'c:\merrbysData\')`

1. Download data from [ftp://www.merrbys.co.uk](ftp://www.merrbys.co.uk) (include the whole folder structure. e.g. `\L1B\2017-04\21\H18\*`)
2. Load Matlab and run `displayL2FDI.m`
	e.g. `displayL2FDI('20170217T21:00:00', '20170218T21:00:00', 'c:\merrbysData\')`
