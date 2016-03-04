ns_SetLibrary('nsCedSon.dll')

BASE_PATH = 'F:/GSK/Rat_Expts/Feinstein/FIMR_0%d.smr'; 

all_chans = cell(1,3);
for iFile = 1:3
    [ns_RESULT, hFile] = ns_OpenFile(sprintf(BASE_PATH,iFile));
    [ns_RESULT, nsFileInfo] = ns_GetFileInfo(hFile);

    [ns_RESULT, nsEntityInfo] = ns_GetEntityInfo(hFile, 1:nsFileInfo.EntityCount);
    [ns_RESULT, nsAnalogInfo] = ns_GetAnalogInfo(hFile, 1);
    [ns_RESULT, ContCount, Data] = ns_GetAnalogData(hFile, 1, 1, nsEntityInfo.ItemCount);

    ns_RESULT = ns_CloseFile(hFile);
    all_chans{iFile} = sci.time_series.data(Data*1e6,1/(nsAnalogInfo.SampleRate),'uV');
end

for iFile = 1:3
    ax(iFile) = subplot(3,1,iFile);
    plot(all_chans{iFile});
    ylabel('Voltage (uV)','FontSize',18)
end

linkaxes(ax,'x')
set(gca,'xlim',[0 3000])
xlabel('Time (s)','FontSize',18)