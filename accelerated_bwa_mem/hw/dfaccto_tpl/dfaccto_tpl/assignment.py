import collections.abc as abc

from .typed import Typed
from .util import DFACCTOError, IndexWrapper, DeferredValue, visit_usage_deps



class Assignment(Typed):
  def __init__(self, accept_type, role, type, vector, size, value=None):
    Typed.__init__(self, role, type, vector, size)
    self._accept_type = accept_type
    self._value = DeferredValue(self._resolve_value)
    self.assign(value)

  @property
  def raw_value(self):
    return self._value

  @property
  def is_assigned(self):
    return not isinstance(self._value, DeferredValue)

  @property
  def assignment(self):
    if not isinstance(self._value, (DeferredValue, abc.Sequence)):
      return self._value
    return None

  @property
  def assignments(self):
    if isinstance(self._value, abc.Sequence):
      return IndexWrapper(self._value)
    return None

  def assign(self, value):
    if value is None:
      return
    if isinstance(self._value, DeferredValue):
      self._value.assign(value)
    elif isinstance(value, DeferredValue):
      value.assign(self._value)
    elif self._value != value:
      msg = '{} is already assigned and can not be changed to {}'
      raise DFACCTOError(msg.format(self, value))

  def _resolve_value(self, value):
    if isinstance(value, self._accept_type):
      self.adapt(value)
      value.assigned_to(self)
    elif isinstance(value, abc.Sequence):
      if not all(isinstance(part, self._accept_type) for part in value):
        msg = 'List assignment to {} must only contain assignable elements'
        raise DFACCTOError(msg.format(self))
      vec = len(value)
      for idx,part in enumerate(value):
        self.adapt(part, part_of=vec)
        part.assigned_to(self, idx)
    else:
      msg = 'Assignment to {} must be an assignable element or list of such'
      raise DFACCTOError(msg.format(self))
    self._value = value

  def usage_deps(self, deps, visited):
    Typed.usage_deps(self, deps, visited)
    if (assignments := self.assignments) is not None:
      for value in assignments:
        visit_usage_deps(deps, visited, value)
    elif (value := self.assignment) is not None:
      visit_usage_deps(deps, visited, value)

