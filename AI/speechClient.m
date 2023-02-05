function clientObj = speechClient(apiName,varargin)
%speechClient Interface with 3rd party Speech Recognition APIs
%
%   client = speechClient(apiName) creates a speechClient object to
%   interface with a 3rd party cloud-based speech API specified by apiName.
%   Valid API names are 'Google', 'IBM', and 'Microsoft'.
%
%   client = speechClient(apiName,'PropertyName','PropertyValue') specifies
%   additional properties used by the 3rd party API. Unspecified properties
%   use default values.
%
%   Valid property names and values depend on the 3rd party API. See the
%   documentation of the corresponding API for valid property names and
%   values.
%
%   EXAMPLE:
%     [y,Fs] = audioread('speech_dft.wav');
%     transcriber = speechClient('Google','languageCode','en-US');
%     transcript = speech2text(transcriber,y,Fs);
%
%   See also SPEECH2TEXT, AUDIOLABELER.

%   Copyright 2017-2019 The MathWorks, Inc.

narginchk(1,Inf);
validatestring(apiName,{'Google','IBM','Microsoft'},'speechClient','apiName');

switch apiName
    case 'Google'
        clientObj = GoogleSpeechClient.getClient();
    case 'IBM'
        clientObj = IBMSpeechClient.getClient();
    case 'Microsoft'
        clientObj = MicrosoftSpeechClient.getClient();
end
clientObj.clearOptions();
clientObj.setOptions(varargin{:});

end