
%% Chris' build after 8/17/2019
mex RAK_MatlabBridge.cpp RAK5206.cpp SharedMemory.cpp Log.cpp VideoAndAudioObtainer.cpp Socket.cpp -IC:\boost_1_69_0 -LC:\boost_1_69_0\stage\lib -LC:\ffmpeg\bin -IC:\ffmpeg\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc141-mt-x64-1_69 -llibboost_chrono-vc141-mt-x64-1_69 -D_WIN32_WINNT=0x0A00

%% Stanislav's build after 8/17/2019
% mex -v RAK_MatlabBridge.cpp RAK5206.cpp SharedMemory.cpp Log.cpp VideoAndAudioObtainer.cpp Socket.cpp -IC:\Users\Stanislav\Downloads\boost_1_69_0-1\boost_1_69_0 -LC:\Users\Stanislav\Desktop\ffmpeg-djordje\install\bin -LC:\Users\Stanislav\Downloads\boost_1_69_0-1\boost_1_69_0\stage\lib -LC:\Users\Stanislav\Desktop\ffmpeg-djordje\install\lib -IC:\Users\Stanislav\Desktop\ffmpeg-djordje\install\include -lavcodec -lavformat -lavutil -lswscale -llibboost_system-vc140-mt-x64-1_69 -llibboost_chrono-vc140-mt-x64-1_69 -llibboost_date_time-vc140-mt-x64-1_69 -D_WIN32_WINNT=0x0601

%% Djordje's macOS build after 8/28/2019
% mex RAK_MatlabBridge.cpp RAK5206.cpp SharedMemory.cpp Log.cpp VideoAndAudioObtainer.cpp Socket.cpp -I/usr/local/Cellar/boost/1.69.0_2/include -L/usr/local/Cellar/boost/1.69.0_2/lib -Ilibraries/mac/ffmpeg/include -lboost_system -lboost_chrono -lboost_thread-mt -lavcodec -lavformat -lavutil -lswscale