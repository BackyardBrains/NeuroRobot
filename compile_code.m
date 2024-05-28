

clear
clc

app_name = 'SpikerBot';
main_app_file = 'C:\Users\chris\NeuroRobot\NeuroRobotToolbox\neurorobot.m';
additional_files = 'C:\Users\chris\NeuroRobot\NeuroRobotToolbox';

compiler_opts = compiler.build.StandaloneApplicationOptions(main_app_file, ...
    'AdditionalFiles', additional_files, ...
    'ExecutableName', app_name, ...
    'Verbose', 'on', ...
    'ExecutableIcon', 'C:\Users\chris\NeuroRobot\Gallery\robot.jpg', ...
    'ExecutableSplashScreen', 'C:\Users\chris\NeuroRobot\Gallery\robot.jpg', ...
    'OutputDir', 'C:\Users\chris\NeuroRobot\SpikerBot_Build', ...
    'SupportPackages', 'autodetect');
compiler_results = compiler.build.standaloneApplication(compiler_opts);

package_opts = compiler.package.InstallerOptions(...
    'ApplicationName', app_name, ...
    'AuthorCompany', 'Backyard Brains', ...
    'AuthorName', 'Christopher Harris', ...
    'InstallerName', strcat(app_name, '_6.6_Installer'), ...
    'InstallerSplash', 'C:\Users\chris\NeuroRobot\Gallery\robot.jpg', ...
    'InstallerIcon', 'C:\Users\chris\NeuroRobot\Gallery\robot.jpg', ...
    'InstallerLogo', 'C:\Users\chris\NeuroRobot\Gallery\strip.jpg', ...
    'OutputDir', 'C:\Users\chris\NeuroRobot\SpikerBot_Installer', ...
    'Summary','The SpikerBot app is a brain simulator for educational neurorobotics developed by Backyard Brains. For information visit https://GitHub.com/BackyardBrains/NeuroRobot', ...
    'Description', 'You are about to download and install the SpikerBot app and Matlab Runtime Library. An internet connection is required.', ...
    'Version', '6.6', ...
    'RuntimeDelivery', 'web');

compiler.package.installer(compiler_results, 'options', package_opts);
