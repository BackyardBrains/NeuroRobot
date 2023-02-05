function tableOut = speech2text(connection, y, fs, varargin)
%speech2text Transcribe speech signal to text
%
%   The speech2text function enables you to interface with 3rd party
%   cloud-based speech-to-text APIs through MATLAB. Supported 3rd party
%   Speech Recognition APIs include: Google, IBM, Microsoft.
%
%   To use the speech2text function, set up an account with the third party
%   API as outlined in <a
%   href="matlab:web('https://www.mathworks.com/matlabcentral/fileexchange/65266-speech2text','-browser')">the documentation</a>.
%
%   TEXT = speech2text(clientObject,SPEECH,FS) transcribes the SPEECH,
%   sampled at FS hertz, to text by passing the data to the clientObject.
%   The clientObject is an interface to a third-party API, and is an object
%   of the speechClient class. The output TEXT is returned as a table that
%   contains the transcription and confidence metrics. Some APIs provide
%   additional outputs and are also returned in the table.
%
%   TEXT = speech2text(..., 'HTTPTimeOut',TIMEOUT) specify the TIMEOUT
%   value in seconds to wait for initial server connection
%
%   EXAMPLE:
%     [y,Fs] = audioread('speech_dft.wav');
%     transcriber = speechClient('Google','languageCode','en-US');
%     transcript = speech2text(transcriber,y,Fs);
%
%   See also SPEECHCLIENT, AUDIOLABELER, TEXT2SPEECH.

%   Copyright 2017-2019 The MathWorks, Inc.


% Verify connection is a valid object of expected class-type.
assert(~isempty(connection) && isa(connection, 'BaseSpeechClient') && isvalid(connection), ...
    'The first input to the speech2text function should be a speechClient object');

% Get the HTTP Timeout value
timeOut = 10; % Default value of timeout will be 10 seconds

if ~isempty(varargin)
    validatestring(varargin{1},{'HTTPTimeOut'});
    timeOut = varargin{2};
end

connection.isSpeechToText = true;

% Call the speechToText function of speechClient
tableOut = connection.speechToText(y,fs,timeOut);

end
