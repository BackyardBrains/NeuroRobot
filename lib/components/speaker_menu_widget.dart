
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Hardcoded Sound Effects Data
class SoundEffect {
  final int id;
  final String name;
  final String category; // "Voice" or "Instrument"
  final String? emoji; // Only for Voice
  final int? baseStartFreq; // Only for Instrument
  final String? noteStart; // e.g. C3
  final int? rangeOctaves; // How many octaves available

  SoundEffect({
    required this.id,
    required this.name,
    required this.category,
    this.emoji,
    this.baseStartFreq,
    this.noteStart,
    this.rangeOctaves,
  });
}

final List<SoundEffect> voiceEffects = [
  SoundEffect(id: 31, name: "Ciao", category: "Voice", emoji: "👋"),
  SoundEffect(id: 32, name: "Uh-oh!", category: "Voice", emoji: "🫢"),
  SoundEffect(id: 33, name: "Mhmm!", category: "Voice", emoji: "👍"),
  SoundEffect(id: 34, name: "Hmm...", category: "Voice", emoji: "🤔"),
  SoundEffect(id: 35, name: "Snoring", category: "Voice", emoji: "😴"),
  SoundEffect(id: 36, name: "Eating", category: "Voice", emoji: "🍰"),
  SoundEffect(id: 37, name: "Yee-haw", category: "Voice", emoji: "🤠"),
  SoundEffect(id: 38, name: "Bark", category: "Voice", emoji: "🐕"),
  SoundEffect(id: 39, name: "Meow", category: "Voice", emoji: "🐱"),
  SoundEffect(id: 40, name: "Magic", category: "Voice", emoji: "✨"),
];

final List<SoundEffect> instrumentEffects = [
  SoundEffect(id: 128, name: "Choir", category: "Instrument", baseStartFreq: 128, noteStart: "C3", rangeOctaves: 2),
  SoundEffect(id: 228, name: "Strings", category: "Instrument", baseStartFreq: 228, noteStart: "C4", rangeOctaves: 2),
  SoundEffect(id: 328, name: "Brass", category: "Instrument", baseStartFreq: 328, noteStart: "C3", rangeOctaves: 2),
  SoundEffect(id: 428, name: "Synth", category: "Instrument", baseStartFreq: 428, noteStart: "C4", rangeOctaves: 2),
];

class SpeakerMenuWidget extends StatefulWidget {
  final Function(double) onFrequencyChanged;
  final double currentFrequency;
  
  final SoLoud? soloud;
  final AudioSource? buttonOnPressedSource;
  final AudioSource? buttonPopSource;
  
  final int infoState; // V12: 0=Off, 1=Info, 2=Labels

  const SpeakerMenuWidget({
    Key? key, 
    required this.onFrequencyChanged, 
    required this.currentFrequency,
    this.soloud,
    this.buttonOnPressedSource,
    this.buttonPopSource,
    this.infoState = 0,
  }) : super(key: key);

  @override
  State<SpeakerMenuWidget> createState() => _SpeakerMenuWidgetState();
}

class _SpeakerMenuWidgetState extends State<SpeakerMenuWidget> {
  int _mode = 0; // 0=Voice, 1=Instrument
  int _selectedVoiceId = 31;
  int _selectedInstrumentIndex = 0;
  int _octaveOffset = 0; 
  
  bool _isChoosingInstrument = false; 

  // Colors 
  final Color colorOrange = const Color(0XFFFD8164); 
  final Color colorActiveKey = const Color(0xFFfd8164);
  final Color colorTabBg = const Color(0xFFF8F1FA); // V16: Match Card Background (f8f1fa)

  // V9: Added Note Names
  final List<String> noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

  Future<void> _playSound(bool isPress) async {
    if (widget.soloud == null) return;
    try {
      if (isPress && widget.buttonOnPressedSource != null) {
        await widget.soloud!.play(widget.buttonOnPressedSource!, looping: false);
      } else if (!isPress && widget.buttonPopSource != null) {
        await widget.soloud!.play(widget.buttonPopSource!, looping: false);
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.currentFrequency >= 31 && widget.currentFrequency <= 40) {
      _mode = 0;
      _selectedVoiceId = widget.currentFrequency.toInt();
    } else if (widget.currentFrequency >= 70) {
      _mode = 1;
      for (int i = 0; i < instrumentEffects.length; i++) {
         int start = instrumentEffects[i].baseStartFreq!;
         if (widget.currentFrequency >= start && widget.currentFrequency < start + 24) {
           _selectedInstrumentIndex = i;
           int diff = widget.currentFrequency.toInt() - start;
           _octaveOffset = (diff / 12).floor();
           if (_octaveOffset > 1) _octaveOffset = 1; 
           break;
         }
      }
    }
  }

  void _selectVoice(int id) {
    setState(() {
      _selectedVoiceId = id;
    });
    widget.onFrequencyChanged(id.toDouble());
  }

  void _selectInstrument(int index) {
    setState(() {
      _selectedInstrumentIndex = index;
      if (_octaveOffset > 1) _octaveOffset = 1; 
      _isChoosingInstrument = false; 
    });
  }

  void _toggleOctave() {
    setState(() {
      _octaveOffset = _octaveOffset == 0 ? 1 : 0;
    });
  }

  void _playNote(int noteIndex) {
    if (_mode == 1) {
       SoundEffect inst = instrumentEffects[_selectedInstrumentIndex];
       int freq = inst.baseStartFreq! + (_octaveOffset * 12) + noteIndex;
       widget.onFrequencyChanged(freq.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 3), // Keep padding?
        // User said "too much vertical padding between those elements".
        // The container has 8,7,8,3 padding.
        // I will keep this unless requested, but user said "between elements".
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Select a Sound to Play", // V17: Updated Title
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 5), // V10: Reduced from 10
            
            Container(
              decoration: BoxDecoration(
                color: colorTabBg,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTab(0, "Voices", "🗣️"),
                  const SizedBox(width: 5),
                  _buildTab(1, "Instruments", "🎹"),
                ],
              ),
            ),
            
            const SizedBox(height: 5), // V10: Reduced from 15
            
            if (_mode == 0) 
               _buildVoiceGrid()
            else 
               _buildInstrumentPanel(),

            if (widget.infoState == 1) ...[ // V12: Info Box
               const SizedBox(height: 10),
               Container(
                 width: 360, // V13: Lock Width
                 child: Row(
                   children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(0), // V15: Reduce Padding to 0
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 0.3,
                              blurRadius: 0.3,
                              offset: const Offset(1, 1), 
                            ),
                          ],
                        ),
                        child: SvgPicture.asset("assets/icons/Info.svg"),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _mode == 0 
                             ? "When the NEURON sends a SPIKE, Spikerbot will speak this sound!"
                             : "When the NEURON sends a SPIKE, Spikerbot will play a musical note!",
                          style: const TextStyle(
                            fontFamily: "BybHanddrawn",
                            fontSize: 16, // Ensure readable
                          ),
                          maxLines: 4,
                          textAlign: TextAlign.left,
                        ),
                      ),
                   ],
                 ),
               ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int mode, String label, String icon) {
    bool isSelected = _mode == mode;
    return GestureDetector(
      onTapDown: (d) => _playSound(true),
      onTapUp: (d) {
        _playSound(false);
        setState(() {
          _mode = mode;
          _isChoosingInstrument = false; 
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
             BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18, fontFamily: "NotoEmoji")),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
               fontWeight: FontWeight.bold,
               color: isSelected ? Colors.black : Colors.grey.shade600
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonBase(String icon, String label, bool isSelected, {double scaleEmoji = 1.0}) {
     return SizedBox(
       width: 80, // V11: Revert to 80 for 3-4-3 layout
       height: 90,
       child: Stack(
         clipBehavior: Clip.none, 
         alignment: Alignment.center, 
         children: [
           Positioned(
               left: 10, 
               top: 0,
               child: Container(
                 width: 60,
                 height: 60,
                 decoration: BoxDecoration(
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.white, width: 2),
                   color: isSelected ? colorOrange : Colors.white,
                   boxShadow: [
                     BoxShadow(
                       color: Colors.grey.withOpacity(0.5),
                       spreadRadius: 0.3,
                       blurRadius: 0.3,
                       offset: const Offset(1, 1), 
                     ),
                   ],
                 ),
                 child: Center(
                   child: Text(icon,
                     textAlign: TextAlign.center,
                     style: TextStyle(
                       fontSize: 28 * scaleEmoji, 
                       fontFamily: "NotoEmoji",
                       height: 1.2,
                     )),
                 ),
               )),
           
           Positioned(
               left: 0,
               right: 0,
               top: 52, // V11: 8px Overlap for 60px circle
               child: Center(
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(minWidth: 80),
                   child: Card(
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                       child: Text(
                           label,
                           textAlign: TextAlign.center,
                           style: const TextStyle(
                             fontSize: 12, 
                             fontWeight: FontWeight.w500
                           ), 
                       ),
                     ),
                   ),
                 ),
               ))
         ],
       ),
     );
  }

  Widget _buildVoiceGrid() {
    final rows = [
       voiceEffects.sublist(0, 3),
       voiceEffects.sublist(3, 7),
       voiceEffects.sublist(7, 10),
    ];

    return Container(
      width: 360, 
      height: 280, 
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Column(
          children: rows.map((rowItems) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: rowItems.map((voice) {
                  bool isSelected = _selectedVoiceId == voice.id;
                  return GestureDetector(
                     onTapDown: (d) => _playSound(true),
                     onTapUp: (d) {
                       _playSound(false);
                       _selectVoice(voice.id);
                     },
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 4.0),
                       child: _buildButtonBase(voice.emoji ?? "", voice.name, isSelected),
                     )
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInstrumentPanel() {
    if (_isChoosingInstrument) {
      return Container(
        width: 360,
        height: 250,
        alignment: Alignment.center,
        child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(instrumentEffects.length, (index) {
              bool isSelected = _selectedInstrumentIndex == index;
              SoundEffect inst = instrumentEffects[index];
              String icon = _getInstrumentIcon(inst.name);
  
              return GestureDetector(
                onTapDown: (d) => _playSound(true),
                onTapUp: (d) {
                   _playSound(false);
                   _selectInstrument(index);
                },
                child: _buildButtonBase(icon, inst.name, isSelected),
              );
            }),
          ),
      );
    } else {
      SoundEffect currentInst = instrumentEffects[_selectedInstrumentIndex];
      String icon = _getInstrumentIcon(currentInst.name);

      return Column(
        children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.center, 
             children: [
                GestureDetector(
                  onTapDown: (d) => _playSound(true),
                  onTapUp: (d) {
                    _playSound(false);
                    setState(() {
                      _isChoosingInstrument = true;
                    });
                  },
                  child: _buildButtonBase(icon, currentInst.name, true),
                ),
                
                const SizedBox(width: 30),
                
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     // V17: Octave Label Style (Match Title)
                     const Text("Octave", style: TextStyle(
                        color: Colors.black, 
                        fontSize: 17, 
                        fontWeight: FontWeight.normal // V17: Unbolded
                     )),
                     const SizedBox(height: 5), 
                     Row(
                        children: [
                          Text("Low", style: TextStyle(
                            fontWeight: FontWeight.normal,
                            // V9: Toggle Color Logic
                            color: _octaveOffset == 0 ? Colors.black : Colors.grey, 
                            fontSize: 14,
                          )),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _toggleOctave,
                            onTapDown: (d) => _playSound(true),
                            onTapUp: (d) => _playSound(false),
                            child: Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Track
                                Container(
                                  width: 50,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: colorOrange, 
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                                // Puck
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  margin: EdgeInsets.only(left: _octaveOffset == 1 ? 24.0 : 4.0),
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("High", style: TextStyle(
                            fontWeight: FontWeight.normal,
                            // V9: Toggle Color Logic
                            color: _octaveOffset == 1 ? Colors.black : Colors.grey,
                            fontSize: 14,
                          )),
                        ],
                     ),
                  ],
                ),
             ],
           ),
           
           const SizedBox(height: 20),
           
           // Keyboard
           Container(
            height: 150, 
            width: 360,
            child: LayoutBuilder(
              builder: (context, constraints) {
                 double whiteKeyWidth = (constraints.maxWidth - 2) / 7;
                 
                 List<Widget> keys = [];
                 
                 List<int> whiteIndices = [0, 2, 4, 5, 7, 9, 11];
                 for (int i = 0; i < 7; i++) {
                   int noteIndex = whiteIndices[i];
                   keys.add(Positioned(
                     left: i * whiteKeyWidth, 
                     top: 0,
                     bottom: 0,
                     width: whiteKeyWidth + 2, 
                     child: _buildKey(noteIndex, Colors.white, Colors.black, noteNames[noteIndex], false),
                   ));
                 }
                 
                 // Black Keys
                 double blackKeyWidth = whiteKeyWidth * 0.65;
                 double blackKeyHeight = constraints.maxHeight * 0.6;
                 
                 List<int> blackIndices = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
                 List<int> whiteRefIndices = [0, 1, 3, 4, 5]; 
                 
                 for (int i = 0; i < 5; i++) {
                   int refIndex = whiteRefIndices[i];
                   double left = (refIndex * whiteKeyWidth) + (whiteKeyWidth * 0.65);
                   int noteIndex = blackIndices[i];
                   keys.add(Positioned(
                     left: left,
                     top: 0,
                     height: blackKeyHeight,
                     width: blackKeyWidth,
                     child: _buildKey(noteIndex, Colors.black, Colors.white, noteNames[noteIndex], true),
                   ));
                 }
                 
                 return Stack(children: keys);
              },
            ),
          ),
        ],
      );
    }
  }

  String _getInstrumentIcon(String name) {
     if (name.contains("Choir")) return "👼";
     if (name.contains("Strings")) return "🎻";
     if (name.contains("Brass")) return "🎺";
     if (name.contains("Synth")) return "👾";
     return "🎵";
  }

  Widget _buildKey(int noteIndex, Color color, Color textColor, String label, bool isBlack) {
    bool isActive = false;
    if (_mode == 1 && !_isChoosingInstrument) {
       SoundEffect inst = instrumentEffects[_selectedInstrumentIndex];
       int keyFreq = inst.baseStartFreq! + (_octaveOffset * 12) + noteIndex;
       if (keyFreq == widget.currentFrequency.toInt()) {
         isActive = true;
       }
    }
    
    Color keyDisplayColor = isActive ? colorActiveKey : color;
    Color labelColor = isActive ? Colors.white : textColor; 

    return Material(
      color: keyDisplayColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(4), bottomRight: Radius.circular(4)),
        side: const BorderSide(color: Colors.black, width: 2.0),
      ),
      child: InkWell(
        onTapDown: (d) => _playSound(true),
        onTapUp: (d) => _playSound(false),
        onTap: () => _playNote(noteIndex),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: widget.infoState == 2 // V12: Check State 2
              ? Text(
                  label, 
                  style: TextStyle(
                  color: labelColor, 
                  fontSize: isBlack ? 14 : 18, 
                  fontFamily: "BybHanddrawn",
                  fontWeight: FontWeight.normal
                ))
              : Container(),
          ),
        ),
      ),
    );
  }
}
