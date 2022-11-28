function normalize()
    files_path = '.\\mediaData\selected_frogs';
    files = dir(files_path);
    outputPath = '.\\mediaData\created_frogs';
    for file = {files.name}
        if length(file{:}) < 3
            continue
        end
        path = sprintf('%s\\%s',files_path,file{:});
        mySound = ita_read(path);
        data = mySound.time;
        mySound.time = data/norm(data, "inf");
        ita_write_wav(mySound,sprintf('%s\\%s', outputPath, file{:}), 'overwrite',true);
    end
end