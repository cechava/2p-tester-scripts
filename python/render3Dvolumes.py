#!/usr/bin/env python2

import scipy.io as spio
import os
import uuid
import numpy as np
import cPickle as pkl
import h5py
import pandas as pd
import optparse
from skimage import img_as_uint

## optparse for user-input:
#source = '/nas/volume1/2photon/RESDATA/TEFO'
#session = '20161219_JR030W'
##experiment = 'gratingsFinalMask2'
## datastruct_idx = 1
#animal = 'R2B1'
#receipt_date = '2016-12-30'
#create_new = True 
#
# todo:  parse everything by session, instead of in bulk (i.e., all animals)...
# animals = ['R2B1', 'R2B2']
# receipt_dates = ['2016-12-20', '2016-12-30']

# Need better loadmat for dealing with .mat files in a non-annoying way:

def loadmat(filename):
    '''
    this function should be called instead of direct spio.loadmat
    as it cures the problem of not properly recovering python dictionaries
    from mat files. It calls the function check keys to cure all entries
    which are still mat-objects
    '''
    data = spio.loadmat(filename, struct_as_record=False, squeeze_me=True)
    
    return _check_keys(data)


def _check_keys(dict):
    '''
    checks if entries in dictionary are mat-objects. If yes
    todict is called to change them to nested dictionaries
    '''
    for key in dict:
        if isinstance(dict[key], spio.matlab.mio5_params.mat_struct):
            dict[key] = _todict(dict[key])
    
    return dict        


def _todict(matobj):
    '''
    A recursive function which constructs from matobjects nested dictionaries
    '''
    dict = {}
    for strg in matobj._fieldnames:
        elem = matobj.__dict__[strg]
        if isinstance(elem, spio.matlab.mio5_params.mat_struct):
            dict[strg] = _todict(elem)
        elif isinstance(elem,np.ndarray):
            dict[strg] = _tolist(elem)
        else:
            dict[strg] = elem

    return dict


def _tolist(ndarray):
    '''
    A recursive function which constructs lists from cellarrays 
    (which are loaded as numpy ndarrays), recursing into the elements
    if they contain matobjects.
    '''
    elem_list = []            
    for sub_elem in ndarray:
        if isinstance(sub_elem, spio.matlab.mio5_params.mat_struct):
            elem_list.append(_todict(sub_elem))
        elif isinstance(sub_elem,np.ndarray):
            elem_list.append(_tolist(sub_elem))
        else:
            elem_list.append(sub_elem)

    return elem_list


dstructpath = '/nas/volume1/2photon/RESDATA/TEFO/20161219_JR030W/retinotopyFinal/analysis/datastruct_014/datastruct_014.mat'
dstruct = loadmat(dstructpath)
meta = loadmat(dstruct['metaPath'])

tracestructnames = dstruct['traceNames3D']

tiffidx = 3

tracestruct = loadmat(os.path.join(dstruct['tracesPath'], tracestructnames[tiffidx]))
#rawtraces = tracestruct['rawTracesNMF']
rawtraces = tracestruct['rawTraceMatDCNMF']
#rawtracestmp = tracestruct['rawTraceMatDCNMF']
#rawtraces = exposure.rescale_intensity(rawtracestmp, out_range=(0, 2**16-1))

#old_min = np.nanmin(rawtraces)
#old_max = np.nanmax(rawtraces)
#old_range = (old_max - old_min)

#new_min = 0
#new_max = 2**16
#new_range = (new_max - new_min)


maskstruct = loadmat(dstruct['maskarraymatPath'])
masks = maskstruct['maskmat']
nframes = rawtraces.shape[0]
nrois = rawtraces.shape[1]

volumesize = meta['volumeSizePixels']

#nmfvolume = np.empty((volumesize[0], volumesize[1], volumesize[2], nframes), dtype=[('x','uint8'), ('y', 'uint8'), ('z', 'uint8'), ('t', 'uint8')])
nmfvolume = np.empty((volumesize[0], volumesize[1], volumesize[2], nframes), dtype='uint16')
for roi in range(nrois):
    roimask = np.reshape(masks[:,roi], volumesize, order='F')
    #roimask = scipy.ndimage.filters.gaussian_filter(np.reshape(masks[:,roi], volumesize, order='F'), sigma=(.5,.5,.5))
    #roimask = np.swapaxes(roimasktmp, 0, 2)
    #currtrace = np.array([(((val - old_min) * new_range) / old_range) + new_min for val in rawtraces[:, roi]])
    currtrace = np.empty((roimask.shape[0], roimask.shape[1], roimask.shape[2], nframes), dtype='uint16')
    currtrace[np.logical_or(currtrace[:,:,:,0], roimask)] = rawtraces[:, roi]
    nmfvolume[np.logical_or(nmfvolume[:,:,:,0], roimask)] = rawtraces[:, roi] #currtrace #rawtraces[:,roi]

nmfvolume = np.swapaxes(nmfvolume, 0, 3)
nmfvolume = np.swapaxes(nmfvolume, 1, 2)


outpath = '/nas/volume1/2photon/RESDATA/TEFO/20161219_JR030W/retinotopyFinal/memfiles/processed_tiffs'
outfile_fn = 'nmf_File%03d_rawtracematdcnmf.tif' % int(tiffidx+1)
tf.imsave(os.path.join(outpath, outfile_fn), nmfvolume)



# Check mask:
sums = np.nansum(masks, axis=0)
print sums.shape
print max(sums)
print [i for i,s in enumerate(sums) if s>5]

roimask = np.reshape(masks[:,roi], volumesize, order='F')

roimask2 = scipy.ndimage.filters.gaussian_filter(np.reshape(masks[:,roi], volumesize, order='F'), sigma=(.5,.5,.5))

src = mlab.pipeline.scalar_field(roimask)
mlab.pipeline.iso_surface(src, contours=[roimask2.min()+0.1*roimask2.ptp(), ], opacity=0.3)
mlab.pipeline.iso_surface(src, contours=[roimask2.max()-0.1*roimask2.ptp(), ],)

mlab.show()
