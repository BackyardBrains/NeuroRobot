//
//  Macros.h
//  Neurorobot-Framework
//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#ifndef _Macros_h
#define _Macros_h

#ifdef XCODE
    #undef DEBUG
#else
    #define DEBUG
    #define MATLAB
#endif

#endif // ! _Macros_h
