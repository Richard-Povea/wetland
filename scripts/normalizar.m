base_path = 'D:\mediaData\frogs\frog';
output_path = 'D:\mediaData\frog\frog';
for i = 1:94
    pathfile = sprintf('%s%03d.wav',base_path , i);
    mySound = ita_read(pathfile);
    promedio = mean(mySound.time);
    mySound.time = mySound.time - promedio;
    max = norm(mySound.time, "inf");
    mySound.time = mySound.time./max; 
    output_pathfile = sprintf('%s%03d.wav',output_path , i);
    ita_write(mySound, output_pathfile)
end