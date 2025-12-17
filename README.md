# Spikerbot - Spiking Neural Network Designer & Simulator for Robots!

## The Spikerbot App
The Spikerbot App is an all in one design tool & neural simulator. Build spiking neural networks by hand that mimic biology, then test 'brains' realtime with the Spikerbot robot by Backyard Brains. For more information visit: [Spikerbot Documentation](https://docs.backyardbrains.com/neuroengineering/spikerbot)

# Spikerbot Hatch UX Changelog
Previous build: `neurorobot_native_app`
**Date:** 2025-12-17

## New Branch
This release marks the transition from the "Neurorobot" application into **Spikerbot** (v1.3.0). Changes have been made for compiling on MacOS for now, to complete UI/UX details, before porting to every platform. The spiking neuron simulation, drawing alogrithms, live mode and some native system integrations for macOS have all been modified.

## Detailed Changes:

### 1. App Identity & Branding
*   **App Rename**: The application should now officially be **Spikerbot** across all platforms (macOS, iOS, Android, Windows which will need verification).
*   **App Icon**: Updated macOS application icon with a new Spikerbot Specific logo, other formats to follow.
*   **Version**: Bumped to **1.3.0**.

### 2. Live Mode & Simulation
*   **Oscilloscope Viewport**:
    *   Implement dual-signal plotting (Orange/Blue pins).
    *   Plot can be zoomed in to see up to 10 seconds of activity, or as little as 0.5 seconds.
    *   Plot updates at 60Hz for smoother scrolling.
    *   Plot no longer scans with a red bar, new data is pushed into the right edge of a FIFO buffer to mimic the Spike Recorder app.
	*	Rework to openCV color detction for further augmentations planned in future. 
*   **Drag & Drop Pins**:
    *   **New Pin Probes**: Drag pins from the toolbar onto neurons in live mode to view spiking activity.
    *   **Drop Targets**: pins will highlight the target neurons which grow in size as pins pass over valid targets. pins reject locations where pins are already placed.
*   **Simulation**:
    *   **Fix**: Setting an inhibitory neuron to **Delay** now correctly respects the time delay parameter (previously ignored).
    *   **Realtime Spiking**: Spiking simulation timing has been modified with variable delay over the static 1ms delay to account for varience in computation time. This ensures accurate 1ms per step in the simulation
	*	**Increased History Buffer**: Increased from 6,000 steps to 10,000 steps for a full 10 second history. May shorten buffer in platforms with reduced processing power. 

### 3. macOS Enhancements
*   **Native File Picker**:
    *   Importing/Exporting "Brains" now uses the native macOS System File Picker instead of a custom UI, improving usability and faster access to files 
*   **Crash Fixes**:
    *   Resolved runtime crashes associated with OpenCV and startup race conditions.