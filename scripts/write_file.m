function write_file(mySound_binaural, n_iteration)
    ita_write_wav(mySound_binaural,sprintf('D:\\Wetland\\Data_generated\\wetland_%s%05d.wav', 'binarural_',n_iteration),'nbits',32','overwrite',true);
end
