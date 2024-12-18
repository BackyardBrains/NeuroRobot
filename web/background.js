chrome.action.onClicked.addListener(function() {
    // chrome.tabs.create({ url: 'https://www.google.com' });
    chrome.tabs.create({
        url: chrome.runtime.getURL('index.html')
    });
    
});