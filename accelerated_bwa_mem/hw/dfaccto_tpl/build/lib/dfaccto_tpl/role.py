from enum import IntFlag, auto

from .util import DFACCTOError



class Role(IntFlag):
  Unidir = auto()  # Simple Signal
  Input = auto()   # Simple Input Port   - in
  Output = auto()  # Simple Output Port  - out
  Bidir = auto()   # Complex Signal
  Slave = auto()   # Complex Slave Port  - ms: in  | sm: out
  Master = auto()  # Complex Master Port - ms: out | sm: in
  View = auto()    # Complex View Port   - ms: in  | sm: in
  Pass = auto()    # Complex Pass Port   - ms: out | sm: out

  Signal = Unidir | Bidir
  Port = Input | Output | Slave | Master | View | Pass
  Const = Input | View
  Simple = Unidir | Input | Output | Unidir
  Complex = Bidir | Slave | Master | View | Pass

  @classmethod
  def parse(cls, string):
    Symbols = {
      'i': Role.Input,
      'o': Role.Output,
      'U': Role.Unidir,
      's': Role.Slave,
      'm': Role.Master,
      'v': Role.View,
      'p': Role.Pass,
      'B': Role.Bidir}
    val = Symbols.get(string)
    if val is not None:
      return val
    else:
      raise DFACCTOError('"{}" is not a role identifier'.format(string))

  def equals(self, other):
    return (self & other != 0) and (self & ~other == 0)

  def refine(self, other):
    new = self & other
    if new != 0:
      return new
    else:
      return None

  @property
  def is_input(self):
    return self.equals(Role.Input)
  @property
  def is_output(self):
    return self.equals(Role.Output)
  @property
  def is_unidir(self):
    return self.equals(Role.Unidir)
  @property
  def is_slave(self):
    return self.equals(Role.Slave)
  @property
  def is_master(self):
    return self.equals(Role.Master)
  @property
  def is_view(self):
    return self.equals(Role.View)
  @property
  def is_pass(self):
    return self.equals(Role.Pass)
  @property
  def is_ms_input(self):
    return self.equals(Role.Slave | Role.View)
  @property
  def is_ms_output(self):
    return self.equals(Role.Master | Role.Pass)
  @property
  def is_sm_input(self):
    return self.equals(Role.Master | Role.View)
  @property
  def is_sm_output(self):
    return self.equals(Role.Pass | Role.Pass)
  @property
  def is_bidir(self):
    return self.equals(Role.Bidir)
  @property
  def knows_specific(self):
    return self & (self - 1) == 0

  @property
  def is_simple(self):
    return self.equals(Role.Simple)
  @property
  def is_complex(self):
    return self.equals(Role.Complex)
  @property
  def knows_complex(self):
    return self.is_complex or self.is_simple

  @property
  def is_port(self):
    return self.equals(Role.Port)
  @property
  def is_const(self):
    return self.equals(Role.Const)
  @property
  def is_signal(self):
    return self.equals(Role.Signal)
  @property
  def knows_entity(self):
    return self.is_port or self.is_signal


  @property
  def mode(self):
    if self.equals(Role.Input):
      return 'in'
    elif self.equals(Role.Output):
      return 'out'
    else:
      return None

  @property
  def mode_ms(self):
    if self.equals(Role.Slave|Role.View):
      return 'in'
    elif self.equals(Role.Master|Role.Pass):
      return 'out'
    else:
      return None

  @property
  def mode_sm(self):
    if self.equals(Role.Master|Role.View):
      return 'in'
    elif self.equals(Role.Slave|Role.Pass):
      return 'out'
    else:
      return None

  @property
  def cmode(self):
    mode = self.mode
    return mode and mode[0]

  @property
  def cmode_ms(self):
    mode_ms = self.mode_ms
    return mode_ms and mode_ms[0]

  @property
  def cmode_sm(self):
    mode_sm = self.mode_sm
    return mode_sm and mode_sm[0]


