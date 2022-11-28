function write_file(mySound_binaural, n_iteration)
    global RECIEVER
    ita_write_wav(mySound_binaural,sprintf('.\\Media\\wetland_%s_%05d.wav', RECIEVER,n_iteration),'nbits',32','overwrite',true);
end
