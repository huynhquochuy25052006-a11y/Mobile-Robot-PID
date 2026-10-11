fs = 50;     % t?n s? l?y m?u (Hz) -> ch?nh theo Arduino g?i
fc = 5;       % t?n s? c?t (Hz) -> ch?n th?p h?n fs/2
y1 = xlsread('K:\STUDY\Final\Excel\Remake\Only1RawDataOnLoad.xlsx','RightRaw','A2:A1295');
N = length(y1);                 % s? m?u d? li?u
t = (0:N-1)/fs;                       % tr?c th?i gian (giây)
[b,a] = butter(4, fc/(fs/2), 'low');  % l?c b?c 4 thông th?p
filtered_data = filtfilt(b,a,y1);

% V? k?t qu?
plot(t, y1, 'b','LineWidth', 3); hold on; grid on;
plot(t, filtered_data, 'r', 'LineWidth', 3);
xlabel('Time [s]');
ylabel('Speed [cm/s]')
legend('Tin hieu goc','Tin hieu sau loc nhieu');
xlswrite('K:\STUDY\Final\Excel\Remake\Only1RawDataOnLoad.xlsx',filtered_data,'RightFilter','A2');