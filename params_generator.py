import csv
import re

csv_path = 'FrequencyZones±50Cents.csv'

note_order = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
note_data = {note: [] for note in note_order}

with open(csv_path, 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        note_name = row['Note Name']
        # Extract base note (e.g. C#3 -> C#)
        match = re.match(r"([A-G]#?)\d", note_name)
        if match:
            base_note = match.group(1)
            lower = float(row['Lower Bound (Hz)'])
            upper = float(row['Upper Bound (Hz)'])
            if base_note in note_data:
                note_data[base_note].append((lower, upper))

print("static const double toneRanges[12][5][2] = {")
for i, note in enumerate(note_order):
    ranges = note_data[note]
    # Ensure we have 5 ranges. If not, pad or warn.
    # The user said 5 zones. CSV has C3-B7.
    # C3..B3, C4..B4, ... C7..B7. 
    # That is 5 octaves.
    
    print(f"    {{ // {note}")
    for r in ranges:
        print(f"        {{{r[0]:.3f}, {r[1]:.3f}}},")
    print("    },")
print("};")
