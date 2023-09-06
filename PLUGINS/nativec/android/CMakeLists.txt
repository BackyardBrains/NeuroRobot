cmake_minimum_required(VERSION 3.4.1)

add_library( native_nativec

             SHARED

             ../macos/Classes/FilterBase.cpp ../macos/Classes/HighPassFilter.cpp ../macos/Classes/LowPassFilter.cpp ../macos/Classes/GainFilter.cpp ../macos/Classes/NotchPassFilter.cpp ../macos/Classes/ThresholdProcessor.cpp)