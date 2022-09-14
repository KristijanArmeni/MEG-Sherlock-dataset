/meg hosts MATLAB code for curating and preprocessing MEG data.

This code is a minimal collection of functions that allows for basic
processing of the data, such as sensor-level preprocessing, parcellated
beamformer source reconstruction, and temporal response function (TRF)
computation. FieldTrip needs to be installed for it to run.

For full functionality, both the raw data and the data contained in the 
derivatives are required.

The majority of code has hard coded paths that mirror the local filesystem
of the compute infrastructure at the Donders Institute. In order to use
this code in combination with the downloaded data from the repository the
paths to the raw data files and the derived files need to be adjusted.


Getting started

To get on the way with preprocessing, dm_preprocessing_wrapper.m would be the 
function to start with. For a given subject name, and session it computes 
preprocessed sensor-level data, with optional filtering, IC-cleaning, and
artifact rejection. The output data are represented as a FieldTrip raw data
structure.

To obtain source-level time courses dm_lcmv can be used, in combination with
the data computed by dm_preprocessing_wrapper.m
  
To obtain source-level word onset locked time courses, dm_extractwords.m can be used.

Visualisation of the reconstructed word onset locked time courses can be done with
../../plots/plot_tlck2.m 

The function dm_trf_wrapper can be used to obtain temporal response functions (TRFs).
The results of this analysis have not been used for the dataset paper.
 
