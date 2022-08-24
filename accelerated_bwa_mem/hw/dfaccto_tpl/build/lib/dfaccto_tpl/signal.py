from .assignable import Assignable
from .element import EntityElement
from .role import Role
from .typed import Typed
from .util import safe_str



class Signal(EntityElement, Typed, Assignable):
  def __init__(self, entity, name, type=None, vector=None, size=None):
    EntityElement.__init__(self, entity, name, 's_{name}{dir}')
    Typed.__init__(self, Role.Signal, type, vector, size, on_type_set=self._register_identifiers)
    Assignable.__init__(self)

    self.entity.signals.register(self.name, self)
    self.entity.connectables.register(self.name, self)

  def _register_identifiers(self):
    if self.is_simple:
      self.entity.identifiers.register(self.identifier, self)
    elif self.is_complex:
      self.entity.identifiers.register(self.identifier_ms, self)
      self.entity.identifiers.register(self.identifier_sm, self)

  def __str__(self):
    try:
      if self.knows_type:
        type_str = ':{}'.format(self.type)
      else:
        type_str = '?'
      if self.knows_vector:
        if self.is_vector:
          vec_str = '({})'.format(self.size if self.knows_size else '')
        else:
          vec_str = ''
      else:
        vec_str = '?'
      return '({}).s_{}{}{}'.format(self.entity, self.name, type_str, vec_str)
    except:
      return safe_str(self)

  def usage_deps(self, deps, visited):
    EntityElement.usage_deps(self, deps, visited)
    Typed.usage_deps(self, deps, visited)


