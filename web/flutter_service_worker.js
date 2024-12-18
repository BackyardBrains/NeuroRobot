'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"Rolling-1s-200px.gif": "c78a889216477fada3c38e289c05fa5f",
"preprocess.worker.js": "dbebe76feb7e812d7aea418711e4500b",
"version.json": "eb8a912b05268565365e4dcdc85e8cc4",
"recognition.worker.js": "7430a25a4174ba1b9f50127e7a60bb0e",
"index.html": "906d8eceb428d39f69d2d119bf8e61d5",
"/": "906d8eceb428d39f69d2d119bf8e61d5",
"neuronprototype.wasm": "b350fa50438faa2dffb9db77ed64b244",
"workerSimulation.js": "f3e42c681db64cf36fe19eaef0b1619e",
"main.dart.js": "13a5ebe090002000af538ebe92e5758d",
"working_wasm/working_workerSimulation.js": "e62b308f5402f4a0b8ab114afa5e8d88",
"working_wasm/neuronprototype.wasm": "6a1a2e1b9ce1d03b86c2b6d0f0df0ddc",
"working_wasm/working_index.js": "e8e68bbfcc93a3b33d8291720278ed30",
"working_wasm/neuronprototype.worker.js": "64096f3a8667ec34d27d601de57c4ae6",
"working_wasm/working2/neuronprototype.wasm": "da395d4c02132cc3a4bfda9676e3c094",
"working_wasm/working2/neuronprototype.worker.js": "64096f3a8667ec34d27d601de57c4ae6",
"working_wasm/working2/neuronprototype.js": "220f11c9fa55f416c716e0d0ce921eb9",
"working_wasm/neuronprototype.js": "ec8633819bfd135f73f8acf88e124a49",
"newest_index.js": "0ab947bc379cf8ce163d67cfaf29e9da",
"flutter.js": "c71a09214cb6f5f8996a531350400a9a",
"nativeopencv.js": "5534d6a364eaf3b3601acf8764ce51f0",
"index.js": "d856ad7fc7d852ca9f4174bf2ca2af17",
"websocketcommand.worker.js": "33218bdf81ec455c00c239838682771b",
"favicon.png": "5547ebb1f9e482bdb8501f4f1afc89aa",
"neuronsimulator.js": "30b7c3bc8910e7d74847c8be9efad667",
"neuronprototype.worker.js": "2dfebf5860cd9307da9b11e249a392b5",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"websocket.worker.js": "65448ecab8b5279d7eb5cda46a4a3833",
"manifest.json": "45d40539276c059b2a8c9bb022bfbd3a",
"newest_workerSimulation.js": "d4ef1024c6693e0fbdce206761f8a089",
"neuronsimulator.wasm": "e864bf60fc99d47494ce40885f912d16",
"KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf": "11eabca2251325cfc5589c9c6fb57b46",
"nativeopencv.wasm": "c8162b68b8a25df6199acd3e4c514971",
"assets/AssetManifest.json": "8a993030233565118cd8f90c38c7d2bb",
"assets/NOTICES": "e4be1e5ac9d6148e07743cf7405a3c6e",
"assets/FontManifest.json": "b0f26ecf1e1b9cb6c145fee4756b573a",
"assets/AssetManifest.bin.json": "9923d3de97206721dd74620a24e8bd93",
"assets/packages/window_manager/images/ic_chrome_unmaximize.png": "4a90c1909cb74e8f0d35794e2f61d8bf",
"assets/packages/window_manager/images/ic_chrome_minimize.png": "4282cd84cb36edf2efb950ad9269ca62",
"assets/packages/window_manager/images/ic_chrome_maximize.png": "af7499d7657c8b69d23b85156b60298c",
"assets/packages/window_manager/images/ic_chrome_close.png": "75f4b8ab3608a05461a31fc18d6b47c2",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/packages/sn_progress_dialog/images/cancel.png": "be94b63af32e39fabad56e2cab611b4b",
"assets/packages/sn_progress_dialog/images/completed.png": "4f4ec717f6bb773c80db76261bb367c3",
"assets/packages/fialogs/lib/assets/empty.png": "95fea0110ac9fb09c2c68b37213364fe",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "ea6d571938559401ae6c1ce783b33a1b",
"assets/fonts/MaterialIcons-Regular.otf": "2e8155f5c9a07bbc08d85c5ed82032ec",
"assets/assets/saved/BrainText1724733907587233@@@L1E1-Sensor@@@Sensory%2520information%2520can%2520lead%2520to%2520action.txt": "8722f0da7692a2e783392fdee1336e83",
"assets/assets/saved/BrainText1724746973005942@@@L1E2-Follow%2520Targets@@@Produce%2520life-like%2520goal-directed%2520behaviors.txt": "6b2ba13871693773bb2e3931e60f52d9",
"assets/assets/saved/BrainText1724747399306156@@@L1E3-Moving%2520Robot@@@Using%2520spontaneous%2520bursts%2520neuron%2520to%2520perform%2520'random%2520walks'.txt": "acaf22c22ca7e53d92466e36e6d2258f",
"assets/assets/saved/BrainText1725503995473512@@@L2E3@@@WinnerTakeAll.txt": "4a6bd97301d24b387a961dd8cd08bb93",
"assets/assets/saved/BrainText1724748009573259@@@L1E4-Sees%2520Cup@@@How%2520brain%2520is%2520responding,%2520and%2520demonstrating%2520object%2520recognition.txt": "b8a26a85c246539a0ac8176157179da1",
"assets/assets/models/labelmap.txt": "df7760b07e1950af33b3008b1def6cd7",
"assets/assets/models/ssd_mobilenet.tflite": "6b185b3118cfdf50fd5ffbafa4fc9e01",
"assets/assets/icons/Clone.svg": "acd726d8ce43cf04886da98bb2ebc163",
"assets/assets/icons/InfoNotes.svg": "7c4ac7ea6de0f086c3e0ce3e4d6f8573",
"assets/assets/icons/InfoDisabled.svg": "700e1e42c465d3e88a0049b48454093f",
"assets/assets/icons/WifiLow.svg": "235874d88cf33be416ec708d7bfbb38d",
"assets/assets/icons/WifiMid.svg": "21f5384cc2e269e20bb022f0eab1d7d6",
"assets/assets/icons/DragMenuIconsExcitatory1.svg": "278e7cffcf97b89e4a90f899d70ee198",
"assets/assets/icons/Info.svg": "7c4ac7ea6de0f086c3e0ce3e4d6f8573",
"assets/assets/icons/Add.svg": "5e52b30a78751cd11a84dc2bbe9bfb1c",
"assets/assets/icons/DragMenuIconsExcitatory0.svg": "bed153ddc55f211fca41f15181a315c4",
"assets/assets/icons/WifiOff.svg": "3356050486aff0f3f79e6cb29b1256c0",
"assets/assets/icons/Save.svg": "905ee6df33c66a49bfcb746031298d80",
"assets/assets/icons/DragMenuIconsNucleus1.svg": "d572fbe50b130319b7e47ef9af8a8b6a",
"assets/assets/icons/Play.svg": "15d3a17f6c19153dc98344904f068d53",
"assets/assets/icons/DragMenuIconsNucleus0.svg": "7373f5330f7e59ca1c8decef2220cb46",
"assets/assets/icons/Redo.svg": "bea57b0aeb9528d97d9642173911ced2",
"assets/assets/icons/SaveAs.svg": "e6b3eda9dc9649f6c9613c65a2b21091",
"assets/assets/icons/NewFile.svg": "bbddd794ee2bcd4880bb33ad05cc2f95",
"assets/assets/icons/DragMenuIconsNote1.svg": "a618dc1b10d90b988707f63305a91f61",
"assets/assets/icons/Delete.svg": "c8a92daeada9249fde3cae31d363d7b7",
"assets/assets/icons/DragMenuIconsInhibitory0.svg": "2a42d2c29396a9c84339081aedf1c71e",
"assets/assets/icons/DragMenuIconsInhibitory1.svg": "4106bf6aeb3b7aed7d43245c7f9d99d5",
"assets/assets/icons/DragMenuIconsNote0.svg": "7233a3e03de2fd6b2e651bcc951de82d",
"assets/assets/icons/Remove.svg": "54a538efe03ffc44ec4ce187c485d511",
"assets/assets/icons/Undo.svg": "c5eab4a828b6cb057a11499aab796b46",
"assets/assets/icons/WifiFull.svg": "967b090e65a333f7384152ba073165b8",
"assets/assets/icons/Pause.svg": "b2c8cf7a954af16941142d59daafb7ff",
"assets/assets/icons/Merge.svg": "b1aeb60f3d88903a03a2ddb5353b867d",
"assets/assets/icons/InfoLabels.svg": "e87cb9bd8a23ed50797dd1642a8b73b5",
"assets/assets/bg/ObjectColorRange.jpeg": "c65dc462c74c5714a59de88002d25d7e",
"assets/assets/bg/ObjBlackRedBg.jpg": "d31c6dd0c85b1b9ca3ebf44cbbc08186",
"assets/assets/bg/MatLabExample.png": "fa3e42f3d9183b0c22d6f0c00717f241",
"assets/assets/bg/bg1.0x.jpeg": "dbf6e48368c1c64d5823a0235344aca2",
"assets/assets/bg/Spikerbot2Vector.svg": "081a43bef5eb5a88044410cdcc17b48f",
"assets/assets/bg/_bg1.0x.jpeg": "acd55b630ec995dd5d540c692c958144",
"assets/assets/bg/redbg.jpeg": "51266339223ab4d9c5a88398aecc6e59",
"assets/assets/bg/bg2.0x.jpeg": "e607fd341966d7cba936b1abf0758938",
"assets/assets/bg/banana.jpeg": "6a253c6efeb0c24e8f75d8def814d916",
"assets/assets/bg/ObjWhiteRedBg.jpg": "cbf5e80304bd3953f57be489fe606ce4",
"assets/assets/bg/banana224.jpeg": "11ecfaaa01e1ef2ad30c380a47b99266",
"assets/assets/bg/BrainDrawings/DistanceBlack.svg": "b312d8c072dc8e5127c923dfc6773443",
"assets/assets/bg/BrainDrawings/BrainSoloBlack.svg": "b017bf138fd7d5643b84068d7b7bca18",
"assets/assets/bg/BrainDrawings/CompassBlack.svg": "38c05e9cf59ff156e8dff1768402dc24",
"assets/assets/bg/BrainDrawings/CompassGrey.svg": "82414af0cabc4fcbcce77a3fcb8e9d39",
"assets/assets/bg/BrainDrawings/SpeakerBlack.svg": "80025d05754cc20c257f645cf1efb63b",
"assets/assets/bg/BrainDrawings/CameraGrey.svg": "2ff203639924aab643662f2a37606300",
"assets/assets/bg/BrainDrawings/BrainFullBlack_compass.svg": "d2d7a48a44270e26346773c327f99006",
"assets/assets/bg/BrainDrawings/RightMotorGrey.svg": "1147cb0358a2e941fddb5786e85aa9be",
"assets/assets/bg/BrainDrawings/BrainFullBlack.svg": "565254ccac776687a9a79f37c7f47141",
"assets/assets/bg/BrainDrawings/RightMotorBlack.svg": "a53bd7ed7f73fee30ebdd3502ad08d11",
"assets/assets/bg/BrainDrawings/BrainFullGrey_mic.svg": "2cc2840ab1e65a5c259fccfeec4c67cd",
"assets/assets/bg/BrainDrawings/No_image.svg": "36371bad3e67d7ef6d41557a4d5158ce",
"assets/assets/bg/BrainDrawings/LEDBlack.svg": "4a3ae261477646b6c112fe3dc030c4a5",
"assets/assets/bg/BrainDrawings/LEDGrey.svg": "93a74f5b3a9d1335ac43badf78312ba0",
"assets/assets/bg/BrainDrawings/BrainFullGrey.svg": "c0020d6c61ad25e35137fba4f5503ac3",
"assets/assets/bg/BrainDrawings/BrainSoloGrey.svg": "bf4e2f3dcfbf80f7fe2a4a3c962cbb4d",
"assets/assets/bg/BrainDrawings/CameraBlack.svg": "25fc59d8aa08471fdce1cb641645d6ac",
"assets/assets/bg/BrainDrawings/DistanceGrey.svg": "f9966faf064f4deaaccf72dd98348003",
"assets/assets/bg/BrainDrawings/BrainFullBlack_mic.svg": "06a392cad85f7e9ff150ed6d9da12fed",
"assets/assets/bg/BrainDrawings/MicGrey.svg": "d70c620a696f6fce1813591f4b5785a4",
"assets/assets/bg/BrainDrawings/LeftMotorBlack.svg": "8cc85fdf9247742201fbceae596b6e75",
"assets/assets/bg/BrainDrawings/LeftMotorGrey.svg": "b679ddd2ab2a50590804e316eed53afc",
"assets/assets/bg/BrainDrawings/BrainFullBlack%2520copy.svg": "d2d7a48a44270e26346773c327f99006",
"assets/assets/bg/BrainDrawings/SpeakerGrey.svg": "5adcc6eb6764628a53ea5dfecd0b82da",
"assets/assets/bg/BrainDrawings/BrainFullGrey%2520copy.svg": "61538a323306efcbb5131681c2f2d751",
"assets/assets/bg/BrainDrawings/MicBlack.svg": "04af5c71afd755aaf57b5badd3f3e9bc",
"assets/assets/bg/greenbg.jpeg": "774dc95d5b5ccd6c2e30ddc7a1cd1726",
"assets/assets/bg/redbg2.jpeg": "2ef051a164653e3c10ae2180abb5f1e2",
"assets/assets/bg/oldSpikerbot2Vector.svg": "e195047e4f1bfab5c477041168c675fd",
"assets/assets/fonts/BYBHandDrawn.otf": "6ad4c4437d82ddacd669c418f6406c2a",
"assets/assets/fonts/NotoEmoji-VariableFont_wght.ttf": "224fa6678eecb9392238cdf722204b67",
"neuronprototype.js": "ba2468a2c5bb53913377805409389dfa",
"neuronsimulator.worker.js": "64096f3a8667ec34d27d601de57c4ae6",
"canvaskit/skwasm.js": "445e9e400085faead4493be2224d95aa",
"canvaskit/skwasm.js.symbols": "741d50ffba71f89345996b0aa8426af8",
"canvaskit/canvaskit.js.symbols": "38cba9233b92472a36ff011dc21c2c9f",
"canvaskit/skwasm.wasm": "e42815763c5d05bba43f9d0337fa7d84",
"canvaskit/chromium/canvaskit.js.symbols": "4525682ef039faeb11f24f37436dca06",
"canvaskit/chromium/canvaskit.js": "43787ac5098c648979c27c13c6f804c3",
"canvaskit/chromium/canvaskit.wasm": "f5934e694f12929ed56a671617acd254",
"canvaskit/canvaskit.js": "c86fbd9e7b17accae76e5ad116583dc4",
"canvaskit/canvaskit.wasm": "3d2a2d663e8c5111ac61a46367f751ac",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
