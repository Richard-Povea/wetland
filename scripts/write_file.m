function write_file(mySound_binaural, n_iteration, reciever)
    ita_write_wav(mySound_binaural,sprintf('D:\\Wetland\\Data_generated\\wetland_%s_%05d.wav', reciever,n_iteration),'nbits',32','overwrite',true);
end
