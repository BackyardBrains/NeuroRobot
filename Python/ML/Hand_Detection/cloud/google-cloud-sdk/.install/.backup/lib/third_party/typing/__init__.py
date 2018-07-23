# Copyright 2018 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys

if sys.version_info < (3,):
  from typing.python2.typing import *
  # Special imports for attributes not defined in __all__.
  from typing.python2.typing import IO
  from typing.python2.typing import re
else:
  from typing.python3.typing import *
  # Special imports for attributes not defined in __all__.
  from typing.python3.typing import IO
  from typing.python3.typing import re

