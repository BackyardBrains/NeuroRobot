#include "Wrapper.hpp"

#include <string>

NSString * _Nonnull getStringFromLibrary() {
    
    // return [NSString stringWithUTF8String: get_string_from_library().c_str()];
    return @"123123";
}