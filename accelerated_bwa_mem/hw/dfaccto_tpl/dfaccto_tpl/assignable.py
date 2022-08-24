from collections import defaultdict

from .util import DFACCTOError



class Assignable:
  def __init__(self, is_literal=False):
    self._assignments = defaultdict(list)
    self._is_literal = is_literal

  @property
  def is_literal(self):
    return self._is_literal

  def assigned_to(self, container, idx=None):
    role = container.role
    if not role.is_const and self._assignments[role]:
      msg = '{} can not be assigned to multiple elements of role {}'
      raise DFACCTOError(msg.format(self, role.name))
    self._assignments[role].append((container, idx))


class ConstAssignable(Assignable):
  def __init__(self, is_literal=False):
    Assignable.__init__(self, is_literal)


