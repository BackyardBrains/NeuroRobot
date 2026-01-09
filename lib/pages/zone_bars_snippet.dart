
  List<Widget> buildZoneBars() {
    List<Widget> bars = [];
    
    // Only show if info is disabled (matching sketch mode logic)
    if (isShowingInfo != 0) return bars;

    double scaleX = ((Platform.isIOS || Platform.isAndroid) ? 200.0 : 213.0) / 320.0;
    
    // Iterate through all sensory neurons to find active zones
    for (String key in _DesignBrainPageState.mapSensoryNeuron.keys) {
         // Check if this neuron is linked to the current camera view
         // (Assuming we are viewing the Robot's camera, usually Left/Right Eye nodes)
         // Since the Live View is usually the main feed, we check if the node is a visual sensor.
         
         // Simplified check: If it has an area defined, show it.
         String? areaMode = _DesignBrainPageState.mapAreaSize[key];
         if (areaMode == null) continue;
         
         List<String> modes = areaMode.split("_@_");
         if(modes.isEmpty) continue;
         
         double start = 0;
         double end = 0;
         
         if (modes[0] == "Left" || modes[0] == "Right" || modes[0] == "Custom") {
             int p1 = int.parse(modes[1]);
             int p2 = int.parse(modes[2]);
             start = (p1 < p2 ? p1 : p2).toDouble();
             end = (p1 < p2 ? p2 : p1).toDouble();
         } else if (modes[0] == "Any") {
             start = 0;
             end = 320;
         } else {
             continue; 
         }
         
         // Color: Use the neuron's filtered color if possible (index 0=Blue, 1=Green, 2=Red)
         // mapSensoryNeuron[key] stores the index (0, 2, 4...). 
         // Index 0 -> Blue, 2 -> Green, 4 -> Red? 
         // Let's verify color mapping or default to Orange.
         int colorIdx = _DesignBrainPageState.mapSensoryNeuron[key] ?? 0;
         // Usually: 0->Blue, 2->Green, 4->Red. 
         Color barColor = Colors.orange;
         if (colorIdx == 0) barColor = Colors.blue; 
         if (colorIdx == 2) barColor = Colors.green;
         if (colorIdx == 4) barColor = Colors.red;

         bars.add(
             Container(
                 height: 4,
                 width: ((Platform.isIOS || Platform.isAndroid) ? 200.0 : 213.0), // Full width container for alignment
                 margin: const EdgeInsets.only(top: 1), // Stack spacing
                 alignment: Alignment.centerLeft, // Align bars to left so we can use margin/width or strictly sized containers
                 child: Container(
                     margin: EdgeInsets.only(left: start * scaleX),
                     width: (end - start) * scaleX,
                     height: 4,
                     color: barColor.withOpacity(0.6),
                 )
             )
         );
    }
    return bars;
  }
