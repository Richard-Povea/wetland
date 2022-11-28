function bg_frogs(rpf)
    files_path = '.\\mediaData\selected_frogs';
    files = dir(files_path);
    outputPath = '.\\mediaData\created_frogs';
    for file = {files.name}
        if length(file{:}) < 5
            continue
        end
        path = sprintf('%s\\%s',files_path,file{:});
        [my_Sound, ~, ~] = generate_new_sound(rpf, [125, 0.5, -150], path);
        
        BG_NOISE_PATH = 'bg_noise.wav';
        %distance
        BG_NOISE_DISTANCE = 15; %Distance between reciever and bg_noise (+- Z)
        bgNoise = bg_noise(rpf, BG_NOISE_PATH, BG_NOISE_DISTANCE);
        mySound = ita_add(my_Sound, bgNoise);
        ita_write_wav(mySound,sprintf('%s\\%s', outputPath, file{:}), 'overwrite',true);
    
    end
end